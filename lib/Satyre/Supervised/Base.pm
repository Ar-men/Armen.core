#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Satyre::Supervised::Base;

#md_# Satyre::Supervised::Base
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard -types;
use namespace::clean;

extends qw(Obscur::Context);

#md_## Les attributs
#md_

#md_### name
#md_
has 'name' => (
    is => 'ro', isa => Str, required => 1
);

#md_### deploy
#md_
has 'deploy' => (
    is => 'rw', isa => Maybe[Int], default => sub { undef }, init_arg => undef
);

#md_### count
#md_
has 'count' => (
    is => 'rw', isa => Int, default => sub { 0 }, init_arg => undef
);

#md_## Les méthodes
#md_

#md_### is_deployed()
#md_
sub is_deployed{
    my ($self) = @_;
    return defined $self->deploy && $self->count >= $self->deploy;
}

#md_### increment()
#md_
sub increment{
    my ($self) = @_;
    $self->count($self->count + 1);
}

1;
__END__
