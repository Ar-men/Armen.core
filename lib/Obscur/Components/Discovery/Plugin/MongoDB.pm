#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Components::Discovery::Plugin::MongoDB;

#md_# Obscur::Components::Discovery::Plugin::MongoDB
#md_

use Exclus::Exclus;
use List::Util qw(shuffle);
use Moo;
use Safe::Isa qw($_isa);
use Try::Tiny;
use Types::Standard -types;
use Exclus::Exceptions;
use namespace::clean;

extends qw(Obscur::Databases::MongoDB);

#md_## Les attributs
#md_

#md_### _discovery
#md_
has '_discovery' => (
    is => 'ro',
    isa => InstanceOf['MongoDB::Collection'],
    lazy => 1,
    default => sub { $_[0]->get_collection(qw(armen discovery)) },
    init_arg => undef
);

#md_## Les méthodes
#md_

#md_### pre_register_service()
#md_
sub pre_register_service {
    my ($self, $id, $name, $node, $dc, $port_min, $port_max, $fixed_port) = @_;
    my $port = $fixed_port;
    my $registered = 0;
    while (!$registered) {
        $port = int(rand($port_max - $port_min + 1) + $port_min) unless $port;
        try {
            $self->_discovery->insert_one({
                _id       => $id,
                name      => $name,
                node      => $node,
                dc        => $dc,
                port      => $port,
                pid       => '#',
                status    => 'launched',
                timestamp => time,
                heartbeat => time
            });
            $registered = 1;
        }
        catch {
            if ($_->$_isa('MongoDB::DuplicateKeyError')) {
                if ($fixed_port) {
                    EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////
                        message => "Le port suivant est déjà utilisé",
                        params  => [port => $port]
                    });
                }
                undef($port);
            }
            else {
                die $_;
            }
        };
    }
    return $port;
}

#md_### register_service()
#md_
sub register_service {
    my ($self, $service, $port_min, $port_max, $fixed_port) = @_;
    my $port = $fixed_port;
    my $registered = 0;
    while (!$registered) {
        $port = int(rand($port_max - $port_min + 1) + $port_min) unless $port;
        try {
            $self->_discovery->update_one(
                {_id => $service->id},
                {'$set' => {
                    name      => $service->name,
                    node      => $service->node_name,
                    dc        => $service->dc_name,
                    port      => $port,
                    pid       => $$,
                    status    => 'starting',
                    timestamp => time,
                    heartbeat => time
                }},
                {upsert => 1}
            );
            $registered = 1;
        }
        catch {
            if ($_->$_isa('MongoDB::DuplicateKeyError')) {
                if ($fixed_port) {
                    EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////
                        message => "Le port suivant est déjà utilisé",
                        params  => [port => $port]
                    });
                }
                undef($port);
            }
            else {
                die $_;
            }
        };
    }
    return $port;
}

#md_### deregister_service()
#md_
sub deregister_service {
    my ($self, $service) = @_;
    $self->_discovery->delete_one({_id => $service->id});
}

#md_### update_service_status()
#md_
sub update_service_status {
    my ($self, $service, $status) = @_;
    $self->_discovery->update_one({_id => $service->id}, {'$set' => {status => $status, timestamp => time}});
}

#md_### update_service_heartbeat()
#md_
sub update_service_heartbeat {
    my ($self, $service) = @_;
    $self->_discovery->update_one({_id => $service->id}, {'$set' => {heartbeat => time}});
}

#md_### get_services()
#md_
sub get_services {
    my ($self, $status) = @_;
    return map { $_->{id} = delete $_->{_id}; $_ } $_[0]->_discovery->find($status ? {status => $status} : {})->all
}

#md_### get_endpoint()
#md_
sub get_endpoint {
    my ($self, $service_name) = @_;
    my @services = shuffle $self->_discovery->find({name => $service_name, status => 'running'})->all;
    return () unless @services;
    my $service = $services[0];
    return ($service->{node}, $service->{port});
}

1;
__END__
