#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Component;

#md_# Obscur::Component
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard qw(Bool);
use namespace::clean;

extends qw(Obscur::Object);

#md_## Les attributs
#md_

#md_### debug
#md_
has 'debug' => (
    is => 'ro',
    isa => Bool,
    lazy => 1,
    default => sub { $_[0]->cfg->get_bool({default => 0}, 'debug') },
    init_arg => undef
);

1;
__END__
