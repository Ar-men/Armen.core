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
use List::Util qw(shuffle);
use Moo;
use Try::Tiny;
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
            return
                if $service->get_bool({default => 0}, 'disabled');
            $services->{$name} = Satyre::Supervised::Service->new(
                runner => $self,
                name   => $name,
                port   => $service->maybe_get_int('port'),
                deploy => $service->create('deploy')
            );
        }
    );
    return $services;
}

#md_### _reset()
#md_
sub _reset { $_->reset foreach values %{$_[0]->_services} }

#md_### _update()
#md_
sub __update {
    my $self = shift;
    my $services = $self->_services;
    foreach (@_) {
        next if $_->{status} eq 'stopping';
        $services->{$_->{name}}->update($_) if exists $services->{$_->{name}};
    }
}

#md_### _launch()
#md_
sub _launch { $_->launch foreach shuffle values %{$_[0]->_services} }

#md_### _supervise()
#md_
sub _supervise {
    my ($self) = @_;
    my $unlock = $self->sync->lock_w_unlock('supervise', 5000); ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    return if $self->is_stopping;
    $self->info('>>>> Supervise');
    try {
        $self->_reset;
        my @services = $self->discovery->get_services;
        $self->_update(@services);
        $self->_launch;
    }
    catch {
        $self->error("$_");
    };
    $self->info('<<<< Supervise');
}

#md_### on_starting()
#md_
sub on_starting {
    my ($self) = @_;
    $self->_services;
    $self->scheduler->add_timer(0, $self->cfg->get_int({default => 30}, 'frequency'), sub { $self->_supervise });
}

1;
__END__
