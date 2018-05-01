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
use Types::Standard qw(InstanceOf);
use Exclus::Exceptions;
use namespace::clean;

extends qw(Obscur::Component);

#md_## Les attributs
#md_

#md_### _mongo
#md_
has '_mongo' => (
    is => 'ro',
    isa => InstanceOf['Exclus::Databases::MongoDB'],
    lazy => 1,
    default => sub { $_[0]->runner->build_resource('MongoDB', $_[0]->cfg) },
    init_arg => undef
);

#md_### _discovery
#md_
has '_discovery' => (
    is => 'ro',
    isa => InstanceOf['MongoDB::Collection'],
    lazy => 1,
    default => sub { $_[0]->_mongo->get_collection(qw(armen discovery)) },
    init_arg => undef
);

#md_## Les méthodes
#md_

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
                $port = undef;
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
    my ($self) = @_;
    my @services = $self->_discovery->find->all;
    $_->{id} = delete $_->{_id} foreach @services;
    return @services;
}

1;
__END__
