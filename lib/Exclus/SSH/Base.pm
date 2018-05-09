#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::SSH::Base;

#md_# Exclus::SSH::Base
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard qw(Str);
use namespace::clean;

#md_## Les attributs
#md_

#md_### name
#md_
has 'name' => (
    is => 'ro', isa => Str, required => 1
);

#md_## Les méthodes
#md_

#md_### is_cluster()
#md_
sub is_cluster { 0 }

#md_### is_node()
#md_
sub is_node { 0 }

1;
__END__
