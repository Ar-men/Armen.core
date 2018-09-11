#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Application;

#md_# Obscur::Application
#md_

use Exclus::Exclus;
use Module::Runtime qw(use_module);
use Moo;
use Types::Standard -types;
use Exclus::Exceptions;
use namespace::clean;

extends qw(Obscur::Object);

#md_## Les attributs
#md_

#md_### name
#md_
has 'name' => (
    is => 'ro', isa => Str, required => 1
);

#md_### _disabled
#md_
has '_disabled' => (
    is => 'ro',
    isa => Bool,
    lazy => 1,
    default => sub { $_[0]->cfg->get_bool({default => 0}, 'disabled') },
    init_arg => undef
);

#md_### _class
#md_
has '_class' => (
    is => 'rw', isa => Maybe[Str], default => sub { undef }, init_arg => undef
);

#md_### _resources
#md_
has '_resources' => (
    is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef
);

#md_## Les méthodes
#md_

#md_### setup()
#md_
sub setup {
    my $self = shift;
    my $name = $self->name;
    $self->_class(use_module("Application::$name")->setup($self, $self->cfg->create({default => {}}, 'cfg')))
        unless $self->_disabled;
    $self->runner->info('Application', [name => $name, status => $self->_disabled ? 'disabled' : 'initialized']);
    return $self;
}

#md_### get_method_reference()
#md_
sub get_method_reference {
    my ($self, $method) = @_;
    return if $self->_disabled;
    my $ref;
    unless ($ref = $self->_class->can($method)) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Cette méthode n'est pas valide pour cette application",
            params  => [application => $self->name, method => $method]
        });
    }
    return $ref;
}

#md_### add_resource()
#md_
sub add_resource {
    my ($self, $name, $resource) = @_;
    my $resources = $self->_resources;
    if (exists $resources->{$name}) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => 'Cette ressource existe déjà pour cette application',
            params  => [application => $self->name, resource => $name]
        });
    }
    $resources->{$name} = $resource;
}

#md_### get_resource()
#md_
sub get_resource {
    my ($self, $name) = @_;
    my $resources = $self->_resources;
    unless (exists $resources->{$name}) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Cette ressource n'existe pas pour cette application",
            params  => [application => $self->name, resource => $name]
        });
    }
    return $resources->{$name};
}

1;
__END__
