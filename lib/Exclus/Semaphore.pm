#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Semaphore;

#md_# Exclus::Semaphore
#md_

use Exclus::Exclus;
use Guard qw(guard);
use IPC::SysV qw(S_IRUSR S_IWUSR IPC_CREAT SETVAL);
use Moo;
use Types::Standard qw(Int);
use Exclus::Exceptions;
use namespace::clean;

#md_## Les attributs
#md_

#md_### key
#md_
has 'key' => (
    is => 'ro', isa => Int, required => 1
);

#md_### value
#md_
has 'value' => (
    is => 'ro', isa => Int, default => sub { 1 }
);

#md_### _id
#md_
has '_id' => (
    is => 'lazy', isa => Int, init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _build__id()
#md_
sub _build__id {
    my $self = shift;
    my $key = 0x0afac000 + $self->key;
    my $exists = semget($key, 0, 0);
    my $id = semget($key, 1, IPC_CREAT | S_IRUSR | S_IWUSR);
    if (defined $id && !defined $exists && !defined semctl($id, 0, SETVAL, $self->value)) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Impossible d'initialiser le sémaphore",
            params  => [key => $self->key, error => $!]
        });
    }
    return $id if defined $id;
    EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////////
        message => 'Impossible de créer un sémaphore',
        params  => [key => $self->key, error => $!]
    });
}

#md_### _acquire()
#md_
sub _acquire {
    semop($_[0]->_id, pack('s*', 0, -1, 0));
}

#md_### _release()
#md_
sub _release {
    semop($_[0]->_id, pack('s*', 0,  1, 0));
}

sub acquire_then_release {
    my $self = shift;
    $self->_acquire;
    return guard { $self->_release };
}

1;
__END__
