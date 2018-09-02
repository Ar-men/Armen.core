#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Resources::Plugin;

#md_# Obscur::Resources::Plugin
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard -types;
use namespace::clean;

#md_## Les attributs
#md_

#md_### cfg
#md_
has 'cfg' => (
    is => 'ro', isa => InstanceOf['Exclus::Data'], required => 1
);

#md_## Les méthodes
#md_

#md_### build_resource()
#md_
sub build_resource {...}

1;
__END__
