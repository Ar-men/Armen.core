#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::SSH::Cluster;

#md_# Exclus::SSH::Cluster
#md_

use Exclus::Exclus;
use List::Util qw(shuffle);
use Moo;
use Try::Tiny;
use Types::Standard qw(HashRef InstanceOf);
use Exclus::Exceptions;
use namespace::clean;

extends qw(Exclus::SSH::Base);

#md_## Les attributs
#md_

#md_### nodes
#md_
has 'nodes' => (
    is => 'ro', isa => HashRef[InstanceOf['Exclus::SSH::Base']], required => 1
);

#md_## Les méthodes
#md_

#md_### is_cluster()
#md_
sub is_cluster { 1 }

#md_### _connect()
#md_
sub _connect {
    my $self = shift;
    foreach (shuffle values %{$self->nodes}) {
        my $connection = $_->try_connect(@_);
        return $connection
            if $connection;
    }
    EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////////
        message => "Aucune connexion SSH n'est fonctionnelle pour ce cluster",
        params  => [cluster => $self->name]
    });
}

#md_### connect()
#md_
sub connect { shift->_connect(@_) }

#md_### try_connect()
#md_
sub try_connect {
    my ($self, $logger, @args) = @_;
    my $connection;
    try   { $connection = $self->_connect($logger, @args) }
    catch { $logger->warning("$_") };
    return $connection;
}

1;
__END__
