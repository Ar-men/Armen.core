#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Satyre::Service;

#md_# Satyre::Service
#md_

use Exclus::Exclus;
use Moo;
use namespace::clean;

extends qw(Obscur::Runner::Service);

#md_## Les attributs
#md_

###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###
has '+name'        => (default => sub { 'Satyre' });
has '+description' => (default => sub { 'Le µs chargé de la supervision des autres µs' });
###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###

#md_## Les méthodes
#md_

#md_### _supervise()
#md_
sub _supervise {
    my ($self) = @_;
    $self->info('>>>> Supervise');
    $self->info('<<<< Supervise');
}

#md_### on_starting()
#md_
sub on_starting {
    my ($self) = @_;
    $self->scheduler->add_timer(0, $self->cfg->get_int({default => 30}, 'frequency'), sub { $self->_supervise });
}

1;
__END__
