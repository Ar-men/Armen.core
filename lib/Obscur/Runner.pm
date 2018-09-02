#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Runner;

#md_# Obscur::Runner
#md_

use Exclus::Exclus;
use Moo;
use Safe::Isa qw($_isa);
use Sys::Hostname::FQDN qw(fqdn);
use Types::Standard -types;
use Exclus::Config;
use Exclus::Data;
use Exclus::Exceptions;
use Exclus::Logger;
use Exclus::Util qw(create_uuid monkey_patch plugin);
use namespace::clean;

#md_## Les attributs
#md_

#md_### id
#md_
has 'id' => (
    is => 'ro', isa => Str, lazy => 1, default => sub { create_uuid() }
);

#md_### name
#md_
has 'name' => (
    is => 'ro', isa => Str, required => 1
);

#md_### description
#md_
has 'description' => (
    is => 'ro', isa => Str, required => 1
);

#md_### node_name
#md_
has 'node_name' => (
    is => 'ro', isa => Str, lazy => 1, default => sub { fqdn }, init_arg => undef
);

#md_### config
#md_
has 'config' => (
    is => 'ro', isa => InstanceOf['Exclus::Config'], default => sub { Exclus::Config->new }, init_arg => undef
);

#md_### logger
#md_
has 'logger' => (
    is => 'ro',
    isa => InstanceOf['Exclus::Logger'],
    lazy => 1,
    default => sub { Exclus::Logger->new(runner_name => $_[0]->name, runner_data => $_[0]->get_short_id) },
    init_arg => undef
);

###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###
### Les composants #####################################################################################################

#md_### broker
#md_
#md_### client
#md_
#md_### discovery
#md_
#md_### scheduler
#md_
#md_### server
#md_
#md_### sync
#md_
foreach my $name (qw(broker client discovery scheduler server sync)) {
    has(
        $name => (
            is => 'ro',
            isa => InstanceOf['Obscur::Object'],
            lazy => 1,
            default => sub { $_[0]->_build_component($name) }
        )
    );
}

###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###

#md_### _resources
#md_
has '_resources' => (
    is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef
);

#md_## Les méthodes
#md_

#md_### get_short_id()
#md_
sub get_short_id { substr($_[0]->id, 0, 8) }

#md_### signature()
#md_
sub signature {
    my ($self) = @_;
    return $self->name . '[' . $self->id . ']';
}

#md_### properties()
#md_
sub properties {
    my ($self) = @_;
    return {id => $self->id, name => $self->name, node => $self->node_name};
}

#md_### load_object()
#md_
sub load_object {
    my ($self, $package, $name, $cfg, %attributes) = @_;
    my ($object, $plugin_name) = plugin($package, $name, {runner => $self, cfg => $cfg, %attributes});
    unless ($object->$_isa('Obscur::Object')) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "La valeur renvoyée par ce plugin n'hérite pas de 'Obscur::Object'",
            params  => [plugin => $plugin_name]
        });
    }
    return $object;
}

#md_### _build_component()
#md_
sub _build_component {
    my ($self, $name) = @_;
    my $component_config = $self->config->create('components', $name);
    return $self->load_object(
        'Obscur::Components::' . ucfirst $name,
        $component_config->get_str('use'),
        $component_config->create({default => {}}, 'cfg')
    );
}

#md_### build_resource()
#md_
sub build_resource {
    my ($self, $type, $cfg) = @_;
    my $resource_name;
    my $resources = $self->_resources;
    if ($cfg->exists('resource')) {
        $resource_name = $cfg->get_str('resource');
        return $resources->{$resource_name} if exists $resources->{$resource_name};
        $cfg = $self->config->create('resources', $resource_name);
    }
    my ($plugin, $plugin_name) = plugin('Obscur::Resources', $type, {cfg => $cfg});
    unless ($plugin->$_isa('Obscur::Resources::Plugin')) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "La valeur renvoyée par ce plugin n'hérite pas de 'Obscur::Resources::Plugin'",
            params  => [plugin => $plugin_name]
        });
    }
    my $resource = $plugin->build_resource($self, $resource_name);
    $resources->{$resource_name} = $resource
        if $resource_name;
    return $resource;
}

#md_### get_resource()
#md_
sub get_resource {
    my ($self, $type, $name) = @_;
    my $resources = $self->_resources;
    return
        exists $resources->{$name}
            ? $resources->{$name}
            : $self->build_resource($type, Exclus::Data->new(data => {resource => $name}));
}

#md_### debug(), info(), notice(), warning(), error(), critical()
#md_
foreach my $level (qw(debug info notice warning error critical)) {
    monkey_patch(
        __PACKAGE__,
        $level,
        sub { shift->logger->$level(@_) }
    );
}

1;
__END__
