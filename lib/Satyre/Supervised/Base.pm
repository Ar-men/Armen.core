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
use Types::Standard qw(Int Str Maybe);
use namespace::clean;

extends qw(Obscur::Context);

#md_## Les attributs
#md_

#md_### name
#md_
has 'name' => (
    is => 'ro', isa => Str, required => 1
);

#md_### _deploy
#md_
has '_deploy' => (
    is => 'rw', isa => Maybe[Int], default => sub { undef }, init_arg => undef
);

#md_### _count
#md_
has '_count' => (
    is => 'rw', isa => Int, default => sub { 0 }, init_arg => undef
);

1;
__END__
