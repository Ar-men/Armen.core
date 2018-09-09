#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Databases::SQL;

#md_# Exclus::Databases::SQL
#md_

use Exclus::Exclus;
use DBI;
use Moo;
use Types::Standard -types;
use Exclus::Crypt qw(decrypt);
use Exclus::Exceptions;
use namespace::clean;

#md_## Les attributs
#md_

#md_### dsn
#md_
has 'dsn' => (
    is => 'ro', isa => Str, required => 1
);

#md_### options
#md_
has 'options' => (
    is => 'ro', isa => HashRef, required => 1
);

#md_### timeout
#md_
has 'timeout' => (
    is => 'ro', isa => Int, default => sub { 60 }
);

#md_### _handle
#md_
has '_handle' => (
    is => 'rw', isa => Maybe[InstanceOf['DBI::db']], default => sub { undef }, init_arg => undef
);

#md_### _last_use
#md_
has '_last_use' => (
    is => 'rw', isa => Int, default => sub { 0 }, init_arg => undef
);

#md_## Les méthodes
#md_

#md_### DEMOLISH()
#md_
sub DEMOLISH {
    my $self = shift;
    $self->_handle->disconnect if $self->_handle;
}

#md_### _is_connected()
#md_
sub _is_connected {
    my $self = shift;
    return
        unless (my $ok = $self->_handle->ping);
    return 1
        if int($ok);
    undef($ok);
    eval {
        $ok = $self->_handle->do('select 1');
    };
    return $ok;
}

#md_### _connect()
#md_
sub _connect {
    my $self = shift;
    my %attributes = %{$self->options};

    $attributes{PrintError} = 0;
    $attributes{RaiseError} = 1;
    $attributes{AutoCommit} = 1;

    $attributes{Password} = decrypt($attributes{Password})
        if exists $attributes{Password};

    my ($driver) = $self->dsn =~ m!^dbi:(\w+)!;

    # Pas de redirection du Ctrl-C pour Oracle
    $attributes{ora_connect_with_default_signals} = ['INT']
        if $driver eq 'Oracle';

    my $handle = DBI->connect($self->dsn, undef, undef, \%attributes);
    unless ($handle) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => 'Impossible de se connecter à cette base SQL',
            params  => [dsn => $self->dsn, error => $DBI::errstr]
        });
    }
    $self->_handle($handle);
    return $handle;
}

#md_### get_handle()
#md_
sub get_handle {
    my $self = shift;
    my $handle = $self->_handle;
    if ($handle) {
        if (time - $self->_last_use >= $self->_timeout) {
            unless ($self->_is_connected) {
                $self->_handle->disconnect;
                $self->_handle(undef);
                $handle = $self->_connect;
            }
        }
    }
    else {
        $handle = $self->_connect;
    }
    $self->_last_use(time);
    return $handle;
}

1;
__END__
