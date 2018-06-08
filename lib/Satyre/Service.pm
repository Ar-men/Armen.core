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
use Types::Standard qw(HashRef InstanceOf);
use Satyre::Supervised::Service;
use namespace::clean;

extends qw(Obscur::Runner::Service);

#md_## Les attributs
#md_

###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###
has '+name'        => (default => sub { 'Satyre' });
has '+description' => (default => sub { 'Le µs chargé de la supervision des autres µs' });
###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###

#md_### _services
#md_
has '_services' => (
    is => 'lazy', isa => HashRef[InstanceOf['Satyre::Supervised::Service']], init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _build__services()
#md_
sub _build__services {
    my ($self) = @_;
    my $services = {};
    $self->config->create({default => {}}, 'services')->foreach_key(
        {create => 1},
        sub {
            my ($name, $service) = @_;
            $services->{$name} = Satyre::Supervised::Service->new(
                disabled => $service->get_bool({default => 0}, 'disabled'),
                port     => $service->maybe_get_int('port'),
                deploy   => $service->create('deploy')
            );
        }
    );
    return $services;
}

#md_### _supervise()
#md_
sub _supervise {
    my ($self) = @_;
    my $unlock = $self->sync->lock_w_unlock('supervise', 5000); ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    return if $self->is_stopping;
    $self->info('>>>> Supervise');
$self->_services;
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
