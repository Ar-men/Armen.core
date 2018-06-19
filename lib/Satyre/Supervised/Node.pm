#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Satyre::Supervised::Node;

#md_# Satyre::Supervised::Node
#md_

use Exclus::Exclus;
use Moo;
use Try::Tiny;
use Exclus::Util qw(create_uuid);
use namespace::clean;

extends qw(Satyre::Supervised::Base);

#md_## Les méthodes
#md_

#md_### BUILD()
#md_
sub BUILD {
    my ($self, $attributes) = @_;
    $self->deploy($attributes->{deploy}->maybe_get_int('node'));
}

#md_### reset()
#md_
sub reset { $_[0]->count(0) }

#md_### update()
#md_
sub update { $_[0]->increment }

#md_### _pre_register_service()
#md_
sub _pre_register_service {
    my ($self, $dc, $service) = @_;
    my $service_name = $service->name;
    my $id = create_uuid;
    $self->logger->info(
        'PreRegister',
        [id => $id, µs => $service_name, dc => $dc->name, node => $self->name, port => $service->port]
    );
    my $port = $self->runner->discovery->pre_register_service(
        $id,
        $service_name,
        $self->name,
        $dc->name,
        $self->config->get_int('port_min'),
        $self->config->get_int('port_max'),
        $service->port
    );
    return $id, $port;
}

#md_### _launch_service()
#md_
sub _launch_service {
    my ($self, $dc, $service, $ssh) = @_;
    my ($id, $port) = $self->_pre_register_service($dc, $service);
    my $service_name = $service->name;
    $self->logger->info(
        'Launch', [id => $id, µs => $service_name, dc => $dc->name, node => $self->name, port => $port]
    );
    if ($ssh) {
        $ssh->execute('./armen.service.sh', "--service=$service_name", "--id=$id", "--port=$port");
    }
    else {
        system("armen.service --service=$service_name --id=$id --port=$port &");
    }
}

#md_### launch()
#md_
sub launch {
    my ($self, $dc, $service) = @_;
    try {
        my $ssh;
        for (;;) {
            last if $self->is_deployed || $service->is_deployed || $dc->is_deployed;
            if ($self->name eq $self->runner->node_name) {
                $self->_launch_service($dc, $service);
            }
            else {
                if (!$ssh) {
                    $ssh = $self->runner->get_resource('SSH', $self->name)->try_connect($self->logger);
                    last unless $ssh;
                }
                $self->_launch_service($dc, $service, $ssh);
            }
            $service->increment;
            $dc->increment;
            $self->increment;
        }
    }
    catch {
        $self->logger->error("$_");
    };
}

1;
__END__
