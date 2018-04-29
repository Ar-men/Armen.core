#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Config;

#md_# Exclus::Config
#md_

use Exclus::Exclus;
use Data::Visitor::Tiny qw(visit);
use Getopt::Long qw(Configure GetOptions);
use Moo;
use Ref::Util qw(is_hashref is_scalarref);
use Safe::Isa qw($_isa);
use Exclus::Config::Parser qw(parse);
use Exclus::Exceptions;
use Exclus::Util qw(plugin);
use namespace::clean;

extends qw(Exclus::Data);

#md_## Les méthodes
#md_

#md_### set()
#md_
sub set {
    my ($self, $key, $value) = @_;
    $self->data->{$key} = $value;
}

#md_### set_default()
#md_
sub set_default {
    my ($self, $key, $value) = @_;
    $self->set($key, $value) unless exists $self->data->{$key};
}

#md_### _configure_options()
#md_
sub _configure_options { Configure(qw(default pass_through no_auto_abbrev no_ignore_case)) }

#md_### _get_options()
#md_
sub _get_options {
    my $self = shift;
    my $options = {};
    GetOptions(map {m!^(\w+)!; $_ => \$options->{$1}} @_);
    foreach (keys %$options) {
        $self->set($_, $options->{$_}) if defined $options->{$_};
    }
}

#md_### _replace()
#md_
sub _replace {
    my ($self, $data, $vars) = @_;
    visit(
        $data,
        sub {
            my ($key, $ref_value) = @_;
            if (is_scalarref($ref_value) && $$ref_value =~ m!^\{\{(\S+)\}\}$!) {
                my $var_name = $1;
                unless (exists $vars->{$var_name}) {
                    EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////
                        message => "Cette variable de configuration n'existe pas",
                        params  => [variable => "{{$var_name}}"]
                    });
                }
###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###
                $$ref_value = $self->_replace([$vars->{$var_name}], $vars)->[0];
###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###
            }
        }
    );
    return $data;
}

#md_### _merge()
#md_
sub _merge {
    my ($self, $config) = @_;
    my $vars = exists $config->{vars} ? delete $config->{vars} : {};
    EX->throw("Dans la configuration, la clé <vars> doit être de type 'HashRef'") ##////////////////////////////////////
        unless is_hashref($vars);
    $self->_replace($config, $vars);
    $self->data->{$_} = $config->{$_}
        foreach keys %$config;
}

#md_### _load()
#md_
sub _load {
    my $self = shift;
    my ($plugin, $plugin_name) = plugin(__PACKAGE__, @_);
    unless ($plugin->$_isa('Exclus::Config::Plugin')) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "La valeur renvoyée par ce plugin n'hérite pas de 'Exclus::Config::Plugin'",
            params  => [plugin => $plugin_name]
        });
    }
    my $config = $plugin->load;
    unless (is_hashref($config)) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "La valeur renvoyée par ce plugin n'est pas une référence sur un hash",
            params  => [plugin => $plugin_name]
        });
    }
    $self->_merge($config);
}

#md_### setup()
#md_
sub setup {
    my ($self, @options) = @_;
    $self->set('config', delete $ENV{ARMEN_CONFIG}) if exists $ENV{ARMEN_CONFIG};
    $self->_configure_options;
    $self->_get_options('config=s@');
    my $count = 0;
    while (exists $self->data->{config} && $count++ < 10) {
        parse(
            delete $self->data->{config},
            sub { $self->_load(@_) }
        );
    }
    foreach (keys %ENV) {
        next unless m!^ARMEN_(.+)$!;
        $self->set(lc $1, $ENV{$_});
    }
    $self->_get_options(@options);
}

1;
__END__
