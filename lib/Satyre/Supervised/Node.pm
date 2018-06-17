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
    $self->_deploy($attributes->{deploy}->maybe_get_int('node'));
}

#md_### reset()
#md_
sub reset { $_[0]->_count(0) }

#md_### update()
#md_
sub update {
    my ($self) = @_;
    $self->_count($self->_count + 1);
}

#md_### _launch_service()
#md_
sub _launch_service {
    my ($self, $dc, $service) = @_;
    my $service_name = $service->name;
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
    my $result;
    if ($self->name eq $self->runner->node_name) {
        system("armen.service --service=$service_name --id=$id --port=$port &");
        $result = 1;
    }
    else {
        my $ssh = $self->runner->get_resource('SSH', $self->name)->try_connect($self->logger);
        if ($ssh) {
            try {
                $ssh->execute('./armen.service.sh', "--service=$service_name", "--id=$id", "--port=$port");
                $result = 1;
            }
            catch {
                $self->logger->error("$_");
            };
        }
    }
    return $result;
}

#md_### launch()
#md_
sub launch {
    my ($self, $dc, $service) = @_;
    for (;;) {
        last
            if (defined $service->_deploy && $service->_count >= $service->_deploy)
            || (defined      $dc->_deploy &&      $dc->_count >=      $dc->_deploy)
            || (defined    $self->_deploy &&    $self->_count >=    $self->_deploy)
            || !$self->_launch_service($dc, $service);
        $service->_count($service->_count + 1);
        $dc->_count(          $dc->_count + 1);
        $self->_count(      $self->_count + 1);
    }
}

1;
__END__
