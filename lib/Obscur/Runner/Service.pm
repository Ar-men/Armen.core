#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Runner::Service;

#md_# Obscur::Runner::Service
#md_

use Exclus::Exclus;
use EV;
use AnyEvent;
use Guard qw(scope_guard);
use Moo;
use Try::Tiny;
use Types::Standard qw(Bool InstanceOf Int Str);
use Exclus::Exceptions;
use Exclus::Util qw($_call_if_can);
use namespace::clean;

extends qw(Obscur::Runner::Process);

#md_## Les attributs
#md_

#md_### port
#md_
has 'port' => (
    is => 'rw', isa => Int, lazy => 1, builder => '_build_port'
);

#md_### dc_name
#md_
has 'dc_name' => (
    is => 'lazy', isa => Str, init_arg => undef
);

#md_### cfg
#md_
has 'cfg' => (
    is => 'lazy', isa => InstanceOf['Exclus::Data'], init_arg => undef
);

#md_### is_stopping
#md_
has 'is_stopping' => (
    is => 'rw', isa => Bool, default => sub { 0 }, init_arg => undef
);

#md_### _cv_stop
#md_
has '_cv_stop' => (
    is => 'ro', isa => InstanceOf['AnyEvent::CondVar'], default => sub { AE::cv }, init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _build_port()
#md_
sub _build_port {
    my $self= shift;
    return $self->config->get_int({default => 0}, 'services', $self->name, 'port');
}

#md_### _build_dc_name()
#md_
sub _build_dc_name {
    my $self= shift;
    my $config = $self->config;
    my $node_name = $self->node_name;
    unless ($config->exists('nodes', $node_name)) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Ce noeud n'est pas déclaré",
            params  => [node => $node_name]
        });
    }
    if ($config->get_bool({default => 0}, 'nodes', $node_name, 'disabled')) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Ce noeud n'est pas utilisable",
            params  => [node => $node_name]
        });
    }
    my $dc_name = $config->get_str('nodes', $node_name, 'dc');
    unless ($config->exists('dcs', $dc_name)) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Ce centre n'est pas déclaré",
            params  => [dc => $dc_name]
        });
    }
    if ($config->get_bool({default => 0}, 'dcs', $dc_name, 'disabled')) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Ce centre n'est pas utilisable",
            params  => [dc => $dc_name]
        });
    }
    return $dc_name;
}

#md_### _build_cfg()
#md_
sub _build_cfg {
    my $self= shift;
    return $self->config->create({default => {}}, 'services', $self->name, 'cfg');
}

#md_### set_config_default()
#md_
sub set_config_default {
    my ($self) = @_;
    my $config = $self->config;
    $config->set_default(port_min  => 60000);
    $config->set_default(port_max  => 65535);
    $config->set_default(heartbeat =>    60);
}

#md_### _register()
#md_
sub _register {
    my ($self) = @_;
    my $port = $self->port;
    {
        my $unlock = $self->sync->lock_w_unlock('services', 5000); ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        $port = $self->discovery->register_service(
            $self,
            $self->config->get_int('port_min'),
            $self->config->get_int('port_max'),
            $port
        );
    }
    $self->info('Registered', [port => $port]);
    $self->port($port);
}

#md_### _deregister()
#md_
sub _deregister {
    my ($self) = @_;
    my $unlock = $self->sync->lock_w_unlock('services', 5000); ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    $self->discovery->deregister_service($self);
}

#md_### _get_status()
#md_
sub _get_status {
    my ($self, $respond, $rr) = @_;
    $rr->payload({
        id          => $self->id,
        name        => $self->name,
        description => $self->description,
        dc          => $self->dc_name,
        node        => $self->node_name
    });
    $respond->($rr->render->finalize);
}

#md_### _API()
#md_
sub _API {
    my ($self) = @_;
    $self->server->get('/v0/status', sub { $self->_get_status(@_) });
    $self->$_call_if_can('build_API');
}

#md_### _update()
#md_
sub _update {
    my ($self) = @_;
    $self->scheduler->add_timer(0, 0, sub { $self->discovery->update_service_status($self, 'running') });
    my $heartbeat = $self->config->get_int('heartbeat');
    $self->scheduler->add_timer(
        $heartbeat,
        $heartbeat,
        sub { $self->discovery->update_service_heartbeat($self) }
    );
}

#md_### _stop_loop()
#md_
sub _stop_loop { $_[0]->_cv_stop->send }

#md_### is_ready_to_stop()
#md_
sub is_ready_to_stop { 1 }

#md_### _stop()
#md_
sub _stop {
    my ($self) = @_;
    return if $self->is_stopping;
    $self->is_stopping(1);
    $self->info('Stopping...');
    try { $self->discovery->update_service_status($self, 'stopping') } catch { $self->error("$_") };
    $self->scheduler->remove;
    $self->$_call_if_can('on_stopping');
    $self->scheduler->add_timer(5, 2, sub { $self->_stop_loop if $self->is_ready_to_stop });
}

#md_### _start_loop()
#md_
sub _start_loop {
    my ($self) = @_;
    my @watchers = (
        AE::signal('QUIT', sub { $self->_stop_loop }),
        AE::signal('TERM', sub { $self->_stop      })
    );
    $self->_cv_stop->recv;
}

#md_### run()
#md_
sub run {
    my ($self) = @_;
    unless ($self->config->exists('services', $self->name)) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Ce µs n'est pas déclaré",
            params  => [µs => $self->name]
        });
    }
    $self->info('Location', [dc => $self->dc_name, node => $self->node_name]);
    $self->_register;
    scope_guard { $self->_deregister };
    $self->_API;
    $self->_update;
    $self->$_call_if_can('on_starting');
    $self->info('READY.service', [description => $self->description]);
    $self->_start_loop;
}

#md_### service()
#md_
sub service { return shift->process }

1;
__END__
