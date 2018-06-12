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
use constant DELAY => 120;
use Moo;
use Types::Standard qw(Int Maybe Str);
use Exclus::Util qw(create_uuid);
use namespace::clean;

extends qw(Satyre::Supervised::Base);

#md_## Les attributs
#md_

#md_### _last_id
#md_
has '_last_id' => (
    is => 'rw', isa => Maybe[Str], default => sub { undef }, init_arg => undef
);

#md_### _last_timestamp
#md_
has '_last_timestamp' => (
    is => 'rw', isa => Int, default => sub { 0 }, init_arg => undef
);

#md_## Les méthodes
#md_

#md_### BUILD()
#md_
sub BUILD {
    my ($self, $attributes) = @_;
    $self->_deploy($attributes->{deploy}->maybe_get_int('node'));
}

#md_### reset()
#md_
sub reset { $_[0]->_count(0) }

#md_### update()
#md_
sub update {
    my ($self, $service) = @_;
    $self->_count($self->_count + 1);
    $self->_last_id(undef)
        if $self->_last_id && $service->{status} eq 'running' && $self->_last_id eq $service->{id};
}

#md_### _launch_service()
#md_
sub _launch_service {
    my ($self, $service, $dc) = @_;
    my $service_name = $service->name;
    if ($self->_last_id && time - $self->_last_timestamp < DELAY) {
        my $wait = DELAY + $self->_last_timestamp - time;
        $self->logger->notice(
            "Ce service ne peut être relancé pour l'instant",
            [
                service => $service_name,
                dc      => $dc->name,
                node    => $self->name,
                wait    => "${wait}s"
            ]
        );
        return;
    }
    my $id = create_uuid;
    my $port = $self->runner->discovery->pre_register_service(
        $id,
        $service_name,
        $self->name,
        $dc->name,
        $self->config->get_int('port_min'),
        $self->config->get_int('port_max'),
        $service->port
    );
    $self->logger->info(
        'Launch', [id => $id, service => $service_name, dc => $dc->name, node => $self->name, port => $port]
    );
    if ($self->name eq $self->runner->node_name) {
        system("armen.service --service=$service_name --id=$id --port=$port &");
    }
    else {
#TODO
    }
    $self->_last_id($id);
    $self->_last_timestamp(time);
}

#md_### launch()
#md_
sub launch {
    my $self = shift;
    return
        if $self->_deploy
        && $self->_count >= $self->_deploy;
    $self->_launch_service(@_);
}

1;
__END__
