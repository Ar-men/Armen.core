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
use Types::Standard qw(InstanceOf Int Str Maybe);
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
    is => 'ro', isa => InstanceOf['Exclus::Data'], required => 1
);

#md_### deploy_max
#md_
has 'deploy_max' => (
    is => 'ro', isa => Maybe[Int], lazy => 1, init_arg => undef
);

#md_### count
#md_
has 'count' => (
    is => 'rw', isa => Int, default => sub { 0 }, init_arg => undef
);

1;
__END__
