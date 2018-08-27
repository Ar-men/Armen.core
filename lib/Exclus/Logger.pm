#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Logger;

#md_# Exclus::Logger
#md_

use Exclus::Exclus;
use Moo;
use Safe::Isa qw($_isa);
use Types::Standard qw(CodeRef HashRef InstanceOf Maybe Str);
use Exclus::Config::Parser qw(parse);
use Exclus::Exceptions;
use Exclus::Semaphore;
use Exclus::Util qw(plugin);
use namespace::clean;

#md_## Les attributs
#md_

#md_### runner_name
#md_
has 'runner_name' => (
    is => 'ro', isa => Str, required => 1
);

#md_### runner_data
#md_
has 'runner_data' => (
    is => 'rw', isa => Str, required => 1
);

#md_### _semaphore
#md_
has '_semaphore' => (
    is => 'ro',
    isa => InstanceOf['Exclus::Semaphore'],
    lazy => 1,
    default => sub { Exclus::Semaphore->new(key => 0) },
    init_arg => undef
);

#md_### _outputs
#md_
has '_outputs' => (
    is => 'ro', isa => HashRef, lazy => 1, default => sub { {} }, init_arg => undef
);

#md_### extra_cb
#md_
has 'extra_cb' => (
    is => 'rw', isa => Maybe[CodeRef], clearer => 1, default => sub { undef }, init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _add_output()
#md_
sub _add_output {
    my ($self, $type, $attributes, $config) = @_;
    $attributes->{config} = $config;
    my ($output, $plugin_name) = plugin(__PACKAGE__, $type, $attributes);
    unless ($output->$_isa('Exclus::Logger::Plugin')) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "La valeur renvoyée par ce plugin n'hérite pas de 'Exclus::Logger::Plugin'",
            params  => [plugin => $plugin_name]
        });
    }
    $self->_outputs->{$type} = $output;
}

#md_### setup()
#md_
sub setup {
    my ($self, $config) = @_;
    parse($config->get('logger'), sub { $self->_add_output(@_, $config) });
}

#md_### _cmp_level()
#md_
sub _cmp_level {
    state $_priorities = {
        debug   => 0,
        info    => 1,
        notice  => 2,
        warning => 3,
        err     => 4,
        crit    => 5
    };
    shift;
    return $_priorities->{$_[0]} >= $_priorities->{$_[1]};
}

#md_### log()
#md_
sub log {
    my ($self, $level) = (shift, shift);
    my $release = $self->_semaphore->acquire_then_release; ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    foreach (values %{$self->_outputs}) {
        $_->log($self, $level, @_)
            if $self->_cmp_level($level, $_->level);
    }
}

#md_### debug(), info(), notice(), warning(), error(), critical()
#md_
sub debug    { shift->log('debug',   @_) }
sub info     { shift->log('info',    @_) }
sub notice   { shift->log('notice',  @_) }
sub warning  { shift->log('warning', @_) }
sub error    { shift->log('err',     @_) }
sub critical { shift->log('crit',    @_) }

#md_### unexpected_error()
#md_
sub unexpected_error {
    my $self = shift;
    my ($undef, $file, $line) = caller;
    $self->error('Erreur inattendue', [file => $file, line => $line, @_]);
}

1;
__END__
