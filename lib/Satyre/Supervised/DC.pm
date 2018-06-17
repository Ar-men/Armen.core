#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Satyre::Supervised::DC;

#md_# Satyre::Supervised::DC
#md_

use Exclus::Exclus;
use List::Util qw(shuffle);
use Moo;
use Types::Standard qw(HashRef InstanceOf);
use Satyre::Supervised::Node;
use namespace::clean;

extends qw(Satyre::Supervised::Base);

#md_## Les attributs
#md_

#md_### _nodes
#md_
has '_nodes' => (
    is => 'ro', isa => HashRef[InstanceOf['Satyre::Supervised::Node']], default => sub { {} }, init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _build__nodes()
#md_
sub _build__nodes {
    my ($self, $deploy) = @_;
    my $nodes = $self->_nodes;
    $self->config->create({default => {}}, 'nodes')->foreach_key(
        {create => 1},
        sub {
            my ($name, $node) = @_;
            return
                if $node->get_str('dc') ne $self->name
                || $node->get_bool({default => 0}, 'disabled');
            $nodes->{$name} = Satyre::Supervised::Node->new(
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
    $self->_deploy($deploy->maybe_get_int('dc'));
    $self->_build__nodes($deploy);
}

#md_### reset()
#md_
sub reset {
    my ($self) = @_;
    $self->_count(0);
    $_->reset foreach values %{$self->_nodes};
}

#md_### update()
#md_
sub update {
    my ($self, $service) = @_;
    $self->_count($self->_count + 1);
    my $nodes = $self->_nodes;
    $nodes->{$service->{node}}->update if exists $nodes->{$service->{node}};
}

#md_### launch()
#md_
sub launch {
    my $self = shift;
    $_->launch($self, @_) foreach shuffle values %{$self->_nodes};
}

1;
__END__
