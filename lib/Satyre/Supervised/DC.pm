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

#md_### deploy_max
#md_
has '+deploy_max' => (
    default => sub { $_[0]->deploy->maybe_get_int('dc') }
);

#md_### _nodes
#md_
has '_nodes' => (
    is => 'lazy', isa => HashRef[InstanceOf['Satyre::Supervised::Node']], init_arg => undef
);

#md_## Les méthodes
#md_

#md_### BUILD()
#md_
sub BUILD {
    my ($self) = @_;
    $self->deploy_max;
    $self->_nodes;
}

#md_### _build__nodes()
#md_
sub _build__nodes {
    my ($self) = @_;
    my $nodes = {};
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
                deploy => $self->deploy
            );
        }
    );
    return $nodes;
}

#md_### reset()
#md_
sub reset {
    my ($self) = @_;
    $_->reset foreach values %{$self->_nodes};
    $self->count(0);
}

#md_### update()
#md_
sub update {
    my ($self, $service) = @_;
    $self->_nodes->{$service->{node}}->update if exists $self->_nodes->{$service->{node}};
    $self->count($self->count + 1);
}

#md_### launch()
#md_
sub launch {
    my $self = shift;
    return
        if $self->deploy_max
        && $self->count >= $self->deploy_max;
    $_->launch(@_, $self) foreach shuffle values %{$self->_nodes};
}

1;
__END__
