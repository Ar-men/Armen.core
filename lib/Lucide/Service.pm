#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Lucide::Service;

#md_# Lucide::Service
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard -types;
use namespace::clean;

extends qw(Obscur::Runner::Service);

#md_## Les attributs
#md_

###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###
has '+name'        => (default => sub { 'Lucide' });
has '+description' => (default => sub { "Le µs chargé de la supervision" });
###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###

#md_### _backend
#md_
has '_backend' => (
    is => 'lazy', isa => InstanceOf['Obscur::Object'], init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _build__backend()
#md_
sub _build__backend {
    my $self = shift;
    my $config = $self->cfg->create('backend');
    return $self->load_object('Lucide::Backend', $config->get_str('use'), $config->create('cfg'));
}

1;
__END__
