#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Satyre::Supervised::Service;

#md_# Satyre::Supervised::Service
#md_

use Exclus::Exclus;
use List::Util qw(shuffle);
use Moo;
use Types::Standard qw(HashRef InstanceOf Int Maybe);
use Satyre::Supervised::DC;
use namespace::clean;

extends qw(Satyre::Supervised::Base);

#md_## Les attributs
#md_

#md_### deploy_max
#md_
has '+deploy_max' => (
    default => sub { $_[0]->deploy->maybe_get_int('overall') },
);

#md_### port
#md_
has 'port' => (
    is => 'ro', isa => Maybe[Int], required => 1
);

#md_### _dcs
#md_
has '_dcs' => (
    is => 'lazy', isa => HashRef[InstanceOf['Satyre::Supervised::DC']], init_arg => undef
);

#md_## Les méthodes
#md_

#md_### BUILD()
#md_
sub BUILD {
    my ($self) = @_;
    $self->deploy_max;
    $self->_dcs;
}

#md_### _build__dcs()
#md_
sub _build__dcs {
    my ($self) = @_;
    my $dcs = {};
    $self->config->create({default => {}}, 'dcs')->foreach_key(
        {create => 1},
        sub {
            my ($name, $dc) = @_;
            return
                if $dc->get_bool({default => 0}, 'disabled');
            $dcs->{$name} = Satyre::Supervised::DC->new(
                runner => $self->runner,
                name   => $name,
                deploy => $self->deploy
            );
        }
    );
    return $dcs;
}

#md_### reset()
#md_
sub reset {
    my ($self) = @_;
    $_->reset foreach values %{$self->_dcs};
    $self->count(0);
}

#md_### update()
#md_
sub update {
    my ($self, $service) = @_;
    $self->_dcs->{$service->{dc}}->update($service) if exists $self->_dcs->{$service->{dc}};
    $self->count($self->count + 1);
}

#md_### launch()
#md_
sub launch {
    my ($self) = @_;
    return
        if $self->deploy_max
        && $self->count >= $self->deploy_max;
    $_->launch($self) foreach shuffle values %{$self->_dcs};
}

1;
__END__
