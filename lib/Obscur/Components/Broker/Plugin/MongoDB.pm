#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Components::Broker::Plugin::MongoDB;

#md_# Obscur::Components::Broker::Plugin::MongoDB
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard qw(InstanceOf);
use namespace::clean;

extends qw(Obscur::Component);

#md_## Les attributs
#md_

#md_### _mongo
#md_
has '_mongo' => (
    is => 'ro',
    isa => InstanceOf['Exclus::Databases::MongoDB'],
    lazy => 1,
    default => sub { $_[0]->runner->build_resource('MongoDB', $_[0]->cfg) },
    init_arg => undef
);

#md_### _broker
#md_
has '_broker' => (
    is => 'ro',
    isa => InstanceOf['MongoDB::Collection'],
    lazy => 1,
    default => sub { $_[0]->_mongo->get_collection(qw(armen broker)) },
    init_arg => undef
);

1;
__END__
