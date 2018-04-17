#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Écosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Runner::Process;

#md_# Obscur::Runner::Process
#md_

use Exclus::Exclus;
use File::Spec::Functions qw(catfile devnull tmpdir);
use Guard qw(guard);
use Moo;
use Try::Tiny;
use Exclus::Exceptions;
use Exclus::Util qw(to_stderr);
use namespace::clean;

extends qw(Obscur::Runner);

#md_## Les méthodes
#md_

#md_### _initialize()
#md_
sub _initialize {
    my ($self) = @_;
    $0 = 'armen.' . $self->name;
    binmode STDERR, ':encoding(UTF-8)';
    binmode STDOUT, ':encoding(UTF-8)';
    chdir tmpdir;
}

#md_### _configure()
#md_
sub _configure {
    my ($self) = @_;
    my $config = $self->config;
    # Les valeurs par défaut
    $config->set_default(debug => 0);
    $config->set_default(stderr => '');
    $config->set_default(stdout => '');
    $config->set_default(logger => {use => 'Stdout'});
    $self->set_config_default if $self->can('set_config_default');
    my @options = $self->can('add_config_options') ? $self->add_config_options : ();
    $config->setup(
        'debug!',
        'stderr=s', 'stdout=s',
        'logger=s@',
        @options
    );
}

#md_### _set_std()
#md_
sub _set_std {
    my ($self, $stream, $handle) = @_;
    my $mode = $self->config->get_str($stream);
    if ($mode eq 'devnull' || $mode eq 'file') {
        my $file_name = devnull;
        if ($mode eq 'file') {
            state @_unlink;
            $file_name = catfile(tmpdir, sprintf("armen.%s.$stream.$$", $self->name));
            push @_unlink, guard { unlink $file_name if -e -z $file_name };
        }
        unless (open($handle, '+>:encoding(UTF-8)', $file_name)) {
            EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////
                message => 'Impossible de rediriger ' . uc $stream,
                params  => [file => $file_name]
            });
        }
        $handle->autoflush(1);
    }
}

#md_### _set_std_streams()
#md_
sub _set_std_streams {
    my ($self) = @_;
    open(STDIN, '<', devnull)
        or EX->throw('Impossible de rediriger STDIN'); ##///////////////////////////////////////////////////////////////
    $self->_set_std('stderr', \*STDERR);
    $self->_set_std('stdout', \*STDOUT);
}

#md_### setup()
#md_
sub setup {}

#md_### process()
#md_
sub process {
    my ($self) = @_;
    my $exit = -1;
    try {
        # Initialisation et configuration minimale
        $self->_initialize;
        $self->_configure;
        $self->_set_std_streams;
        # Mise en place suplémentaire éventuelle
        $self->setup;
        # Mise en place du 'logger'
        $self->logger->setup($self->config);
        try {
            $self->info('BEGIN.process', [id => $self->id, name => $self->name, pid => $$]);
            # C'est un 'runner' donc...
            $self->run if $self->can('run');
            $exit = 0;
        }
        catch {
            $self->critical("$_");
        };
        $self->info('END.process');
    }
    catch {
        to_stderr("$_");
    };
    return $exit;
}

1;
__END__
