#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Lucide::Service;

#md_# Lucide::Service
#md_

use Exclus::Exclus;
use Module::Runtime qw(use_module);
use Moo;
use Try::Tiny;
use Types::Standard -types;
use Exclus::Data;
use Exclus::Email;
use Exclus::Exceptions;
use Exclus::Util qw(template);
use namespace::clean;

extends qw(Obscur::Runner::Service);

#md_## Les attributs
#md_

###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###
has '+name'        => (default => sub { 'Lucide' });
has '+description' => (default => sub { "Le µs chargé du monitoring" });
###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###

#md_### _backend
#md_
has '_backend' => (
    is => 'lazy', isa => InstanceOf['Obscur::Object'], init_arg => undef
);

#md_### _systems
#md_
has '_all_systems' => (
    is => 'lazy', isa => ArrayRef, init_arg => undef
);

#md_### _states
#md_
has '_all_states' => (
    is => 'ro',
    isa => HashRef,
    lazy => 1,
    default => sub { {ok => {}, warning => {}, error => {}, undefined => {}} },
    init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _build__backend()
#md_
sub _build__backend {
    my $self = shift;
    my $config = $self->cfg->create('backend');
    return $self->load_object('Lucide::Backend', $config->get_str('use'), $config->create('cfg'));
}

#md_### _get_application()
#md_
sub _get_application {
    state $_app = {};
    my ($self, $name, $method) = @_;
    unless (exists $_app->{$name}) {
        my $app = $self->config->create({default => undef}, 'applications', $name);
        unless ($app) {
            EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////
                message => "Cette application n'existe pas",
                params  => [application => $name]
            });
        }
        return if $app->get_bool({default => 0}, 'disabled');
        $_app->{$name} = use_module("Application::$name")->setup($self, $app->create({default => {}}, 'cfg'));
    }
    my $app = $_app->{$name};
    unless ($app->can($method)) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Cette méthode n'est pas valide pour cette application",
            params  => [application => $name, method => $method]
        });
    }
    return $app;
}

#md_### _build_composed_system()
#md_
sub _build_composed_system {
    my ($self, $system, $list, @labels) = @_;
    $system->{state} = 'uninitialized';
    $system->{systems} = [];
    push @{$system->{systems}}, $self->_build_one_system(Exclus::Data->new(data => $_), @labels)
        foreach @$list;
}

#md_### _build_resource_system()
#md_
sub _build_resource_system {
    my ($self, $system, $resource) = @_;
    my ($app_name, $method, @args) = split(' ', $resource->get_str('cmd'));
    my $app = $self->_get_application($app_name, $method);
    return unless $app;
    $system->{app}    = $app;
    $system->{method} = $method;
    $system->{args}   = [@args];
    $system->{value}  = 'uninitialized';
    $system->{state}  = 'uninitialized';
    $self->scheduler->add_timer(
        int(rand(10) + 1),
        $resource->get_str('repeat'),
        sub {
            $self->_monitor($system);
        },
        $system->{name}
    );
}

#md_### _build_one_system()
#md_
sub _build_one_system {
    my ($self, $cfg, @labels) = @_;
    my $label = $cfg->get_str('label');
    my $name = join('.', @labels, $label);
    my $system = {name => $name};
    if ($cfg->get_bool({delault => 0}, 'disabled')) {
        $system->{type} = 'disabled';
        $self->info('Disabled', [system => $name]);
    }
    elsif (my $and = $cfg->maybe_get_arrayref('and')) {
        $system->{type} = 'and';
        $self->_build_composed_system($system, $and, @labels, $label);
    }
    elsif (my $or = $cfg->maybe_get_arrayref('or')) {
        $system->{type} = 'or';
        $self->_build_composed_system($system, $or, @labels, $label);
    }
    elsif (my $resource = $cfg->create({default => undef}, 'resource')) {
        $system->{type} = 'resource';
        $self->_build_resource_system($system, $resource);
    }
    else {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Ce système est mal configuré",
            params  => [system => $name]
        });
    }
    return $system;
}

#md_### _build__all_systems()
#md_
sub _build__all_systems {
    my $self = shift;
    my $all_systems = [];
    foreach ($self->_backend->get_all_systems) {
        push @$all_systems, $self->_build_one_system(Exclus::Data->new(data => $_));

    }
    return $all_systems;
}

#md_### _execute_cmd()
#md_
sub _execute_cmd {
    my ($self, $system) = @_;
    my ($value, $state);
    try {
        local $SIG{ALRM} = sub {
            EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////
                message => "Timeout lors du test de cette ressource système",
                params  => [resource => $system->{name}]
            });
        };
        my $method = $system->{method};
        alarm 10;
        ($value, $state) = $system->{app}->$method(@{$system->{args}});
        alarm 0;
    }
    catch {
        ($value, $state) = ('undefined', 'undefined');
        $self->error("$_");
    };
    # Stringification de la valeur en prévision de la comparaison avec la valeur précédente
    return ("$value", $state);
}

#md_### _monitor()
#md_
sub _monitor {
    my ($self, $system) = @_;
    my $all_states = $self->_all_states;
    my $system_name = $system->{name};
    my ($value, $state) = $self->_execute_cmd($system);
    $self->info('Monitor', [system => $system_name, value => $value, state => $state]);
    my $previous_value = $system->{value};
    my $previous_state = $system->{state};
    $system->{value} = $value if $value ne $previous_value;
    if ($state ne $previous_state) {
        $system->{state} = $state;
        delete $all_states->{$previous_state}->{$system_name}
            if $previous_state ne 'uninitialized';
        $all_states->{$state}->{$system_name} = 1;
        #TODO: refaire le calcul global pour avoir l'état général
    }
    if (  ($previous_state ne 'uninitialized' && $state ne $previous_state)
       || ($previous_state eq 'uninitialized' && $state ne            'ok')
       )
    {
###::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::###
        Exclus::Email
            ->new(config => $self->config, subject => $system_name)
            ->try_to_send(
                $state,
                $self->signature,
                template(
                    'armen.core',
                    'monitor',
                    {
                        value          => $value,
                        previous_value => $previous_value,
                        state          => $state,
                        previous_state => $previous_state,
                        warning        => [keys %{$all_states->{warning}}  ],
                        error          => [keys %{$all_states->{error}}    ],
                        undefined      => [keys %{$all_states->{undefined}}]
                    }
                )
            );
###::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::###
    }
}

#md_### on_starting()
#md_
sub on_starting { $_[0]->_all_systems }

1;
__END__
