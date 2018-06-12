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

#md_### port
#md_
has 'port' => (
    is => 'ro', isa => Maybe[Int], required => 1
);

#md_### _dcs
#md_
has '_dcs' => (
    is => 'ro', isa => HashRef[InstanceOf['Satyre::Supervised::DC']], default => sub { {} }, init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _build__dcs()
#md_
sub _build__dcs {
    my ($self, $deploy) = @_;
    my $dcs = $self->_dcs;
    $self->config->create({default => {}}, 'dcs')->foreach_key(
        {create => 1},
        sub {
            my ($name, $dc) = @_;
            return
                if $dc->get_bool({default => 0}, 'disabled');
            $dcs->{$name} = Satyre::Supervised::DC->new(
                runner => $self->runner,
                name   => $name,
                deploy => $deploy
            );
        }
    );
}

#md_### BUILD()
#md_
sub BUILD {
    my ($self, $attributes) = @_;
    my $deploy = $attributes->{deploy};
    $self->_deploy($deploy->maybe_get_int('overall'));
    $self->_build__dcs($deploy);
}

#md_### reset()
#md_
sub reset {
    my ($self) = @_;
    $_->reset foreach values %{$self->_dcs};
    $self->_count(0);
}

#md_### update()
#md_
sub update {
    my ($self, $service) = @_;
    $self->_dcs->{$service->{dc}}->update($service) if exists $self->_dcs->{$service->{dc}};
    $self->_count($self->_count + 1);
}

#md_### launch()
#md_
sub launch {
    my ($self) = @_;
    return
        if $self->_deploy
        && $self->_count >= $self->_deploy;
    $_->launch($self) foreach shuffle values %{$self->_dcs};
}

1;
__END__
