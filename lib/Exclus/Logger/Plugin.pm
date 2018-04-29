#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Logger::Plugin;

#md_# Exclus::Logger::Plugin
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard qw(InstanceOf Str);
use namespace::clean;

#md_## Les attributs
#md_

#md_### config
#md_
has 'config' => (
    is => 'ro', isa => InstanceOf['Exclus::Data'], required => 1
);

#md_### level
#md_
has 'level' => (
    is => 'rw', isa => Str, required => 1
);

#md_## Les méthodes
#md_

#md_### log()
#md_
sub log {...}

1;
__END__
