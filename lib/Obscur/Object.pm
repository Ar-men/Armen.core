#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Écosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Object;

#md_# Obscur::Object
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard qw(InstanceOf);
use namespace::clean;

extends qw(Obscur::Context);

#md_## Les attributs
#md_

#md_### cfg
#md_
has 'cfg' => (
    is => 'ro', isa => InstanceOf['Exclus::Data'], required => 1
);

1;
__END__
