#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Satyre::Supervised::Node;

#md_# Satyre::Supervised::Node
#md_

use Exclus::Exclus;
use Moo;
use namespace::clean;

extends qw(Satyre::Supervised::Base);

#md_## Les attributs
#md_

#md_### deploy_max
#md_
has '+deploy_max' => (
    default => sub { $_[0]->deploy->maybe_get_int('node') }
);

#md_## Les méthodes
#md_

#md_### BUILD()
#md_
sub BUILD { $_[0]->deploy_max }

#md_### reset()
#md_
sub reset { $_[0]->count(0) }

#md_### reset()
#md_
sub update {
    my ($self) = @_;
    $self->count($self->count + 1);
}

#md_### _launch_service()
#md_
sub _launch_service {
    my ($self, $service, $dc) = @_;
    $self->logger->info('Launch', [service => $service->name, dc => $dc->name, node => $self->name]);
}

#md_### launch()
#md_
sub launch {
    my $self = shift;
    return
        if $self->deploy_max
        && $self->count >= $self->deploy_max;
    $self->_launch_service(@_);
}

1;
__END__
