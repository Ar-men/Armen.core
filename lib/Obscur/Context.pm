#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Écosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Context;

#md_# Obscur::Context
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard qw(InstanceOf);
use namespace::clean;

#md_## Les attributs
#md_

#md_### runner
#md_
has 'runner' => (
    is => 'ro', isa => InstanceOf['Obscur::Runner'], required => 1
);

#md_### config
#md_
has 'config' => (
    is => 'ro',
    isa => InstanceOf['Exclus::Config'],
    lazy => 1,
    default => sub { $_[0]->runner->config },
    init_arg => undef
);

#md_### logger
#md_
has 'logger' => (
    is => 'ro',
    isa => InstanceOf['Exclus::Logger'],
    lazy => 1,
    default => sub { $_[0]->runner->logger },
    init_arg => undef
);

1;
__END__
