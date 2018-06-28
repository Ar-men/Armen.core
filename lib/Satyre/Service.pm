#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Satyre::Service;

#md_# Satyre::Service
#md_

use Exclus::Exclus;
use List::Util qw(shuffle);
use Moo;
use Safe::Isa qw($_isa);
use Try::Tiny;
use Types::Standard qw(HashRef InstanceOf);
use Satyre::Supervised::Service;
use namespace::clean;

extends qw(Obscur::Runner::Service);

#md_## Les attributs
#md_

###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###
has '+name'        => (default => sub { 'Satyre' });
has '+description' => (default => sub { 'Le µs chargé de la supervision des autres µs' });
###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###

#md_### _services
#md_
has '_services' => (
    is => 'lazy', isa => HashRef[InstanceOf['Satyre::Supervised::Service']], init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _build__services()
#md_
sub _build__services {
    my ($self) = @_;
    my $services = {};
    $self->config->create({default => {}}, 'services')->foreach_key(
        {create => 1},
        sub {
            my ($name, $service) = @_;
            return
                if $service->get_bool({default => 0}, 'disabled');
            $services->{$name} = Satyre::Supervised::Service->new(
                runner => $self,
                name   => $name,
                port   => $service->maybe_get_int('port'),
                deploy => $service->create('deploy')
            );
        }
    );
    return $services;
}

#md_### _stop_service()
#md_
sub _stop_service {
    my ($self, $ssh, $service) = @_;
    my $node_name = $service->{node};
    if ($node_name eq $self->node_name) {
        kill 'TERM', $service->{pid};
    }
    else {
        $ssh->{$node_name} = $self->get_resource('SSH', $node_name)->try_connect($self->logger)
            unless exists $ssh->{$node_name};
        if ($ssh->{$node_name}) {
            try { $ssh->{$node_name}->kill('-TERM', $service->{pid}) } catch { $self->logger->error("$_") };
        }
    }
}

#md_### _check_services()
#md_
sub _check_services {
    my ($self) = @_;
    my $ssh = {};
    my $heartbeat = $self->config->get_int('heartbeat');
    foreach ($self->discovery->get_services) {
        next if $_->{id} eq $self->id;
        my $params = [id => $_->{id}, µs => $_->{name}, dc => $_->{dc}, node => $_->{node}];
        if ($_->{status} eq 'running') {
            my $elapsed = time - $_->{heartbeat};
            push @$params, elapsed => $elapsed;
            if ($elapsed > $heartbeat * 4) {
                $self->error("Ce µs n'est plus opérationnel, il doit être tué", $params);
            }
            elsif ($elapsed > $heartbeat * 3) {
                $self->error("Ce µs n'est plus opérationnel, il va être stoppé", $params);
                $self->_stop_service($ssh, $_);
            }
            elsif ($elapsed > $heartbeat * 2) {
                $self->warning('Ce µs est-il opérationnel ?', $params);
            }
        }
        else {
            my $elapsed = time - $_->{timestamp};
            push @$params, elapsed => $elapsed;
            if ($_->{status} eq 'stopping') {
                if ($elapsed > 60) {
                    $self->error("Ce µs est bloqué, il doit être tué", $params);
                }
                elsif ($elapsed > 30) {
                    $self->warning("Ce µs ne semble pas vouloir s'arrêter !", $params);
                }
            }
            elsif ($_->{status} eq 'STOPPING') {
                if ($elapsed > 86400) {
                    $self->warning("Ce µs ne semble pas vouloir s'arrêter !", $params);
                }
            }
            else { ## launched, starting
                if ($elapsed > 60) {
                    $self->error("Ce µs est bloqué, il doit être tué", $params);
                }
                elsif ($elapsed > 30) {
                    $self->warning('Ce µs ne semble pas vouloir se lancer !', $params);
                }
            }
        }
    }
}

#md_### _reset_counters()
#md_
sub _reset_counters { $_->reset foreach values %{$_[0]->_services} }

#md_### _update_counters()
#md_
sub _update_counters {
    my ($self) = @_;
    my $services = $self->_services;
    foreach ($self->discovery->get_services) {
        next if $_->{status} eq 'stopping';
        $services->{$_->{name}}->update($_) if exists $services->{$_->{name}};
    }
}

#md_### _launch_services()
#md_
sub _launch_services { $_->launch foreach shuffle values %{$_[0]->_services} }

#md_### _supervise()
#md_
sub _supervise {
    my ($self) = @_;
    try {
        my $unlock = $self->sync->lock_w_unlock('supervise', 5000); ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        return if $self->is_stopping;
        $self->info('>>>> Supervise');
        try {
            $self->_check_services;
            $self->_reset_counters;
            $self->_update_counters;
            $self->_launch_services;
        }
        catch {
            $self->error("$_");
        };
        $self->info('<<<< Supervise');
    }
    catch {
        $self->logger->log($_->$_isa('EX::UnableToLock') ? 'warning' : 'err', "$_");
    };
}

#md_### on_starting()
#md_
sub on_starting {
    my ($self) = @_;
    $self->_services;
    $self->scheduler->add_timer(0, $self->cfg->get_int({default => 30}, 'frequency'), sub { $self->_supervise });
}

1;
__END__
