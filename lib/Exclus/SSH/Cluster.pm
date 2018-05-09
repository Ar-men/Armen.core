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
use Moo;
use namespace::clean;

extends qw(Exclus::SSH::Base);

#md_## Les méthodes
#md_

#md_### is_cluster()
#md_
sub is_cluster { 1 }

1;
__END__
