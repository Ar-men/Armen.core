#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Databases::SQL;

#md_# Obscur::Databases::SQL
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard -types;
use namespace::clean;

extends qw(Obscur::Object);

#md_## Les attributs
#md_

#md_### _db
#md_
has '_db' => (
    is => 'ro',
    isa => InstanceOf['Exclus::Databases::SQL'],
    lazy => 1,
    default => sub { $_[0]->runner->build_resource('SQL', $_[0]->cfg) },
    init_arg => undef
);

#md_## Les méthodes
#md_

1;
__END__
