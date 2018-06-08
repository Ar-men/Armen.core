#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Satyre::Supervised::Service;

#md_# Satyre::Supervised::Service
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard qw(Bool InstanceOf Int Maybe);
use namespace::clean;

#md_## Les attributs
#md_

#md_### disabled
#md_
has 'disabled' => (
    is => 'ro', isa => Bool, required => 1
);

#md_### port
#md_
has 'port' => (
    is => 'ro', isa => Maybe[Int], required => 1
);

#md_## Les méthodes
#md_

1;
__END__
