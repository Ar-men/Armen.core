#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Lucide::Backend::Plugin::MongoDB;

#md_# Lucide::Backend::Plugin::MongoDB
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard -types;
use namespace::clean;

extends qw(Obscur::Databases::MongoDB);

#md_## Les attributs
#md_

#md_### _config
#md_
has '_config' => (
    is => 'ro',
    isa => InstanceOf['MongoDB::Collection'],
    lazy => 1,
    default => sub { $_[0]->get_collection(qw(armen_Lucide buckets)) },
    init_arg => undef
);

#md_## Les méthodes
#md_

1;
__END__
