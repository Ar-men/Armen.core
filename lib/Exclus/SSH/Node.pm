#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::SSH::Node;

#md_# Exclus::SSH::Node
#md_

use Exclus::Exclus;
use Moo;
use Net::OpenSSH;
use Ref::Util qw(is_hashref);
use Try::Tiny;
use Types::Standard qw(HashRef Int Str);
use Exclus::Crypt qw(decrypt);
use Exclus::Exceptions;
use Exclus::SSH::Connection;
use namespace::clean;

extends qw(Exclus::SSH::Base);

#md_## Les attributs
#md_

#md_### server
#md_
has 'server' => (
    is => 'ro', isa => Str, required => 1
);

#md_### port
#md_
has 'port' => (
    is => 'ro', isa => Int, default => sub { 22 }
);

#md_### users
#md_
has 'users' => (
    is => 'ro', isa => HashRef, required => 1
);

#md_### options
#md_
has 'options' => (
    is => 'ro',
    isa => HashRef,
    default => sub {{
        master_opts => ['-o','LogLevel=ERROR', '-o','StrictHostKeyChecking=no', '-o','UserKnownHostsFile=/dev/null']
    }}
);

#md_## Les méthodes
#md_

#md_### BUILD()
#md_
sub BUILD {
    my ($self) = @_;
    my $users = $self->users;
    foreach (keys %$users) {
        my $data = $users->{$_};
        unless (is_hashref($data)) {
            $data = defined $data ? {password => $data} : {};
        }
        $data->{_failure}   = 0;
        $data->{_timestamp} = 0;
    }
}

#md_### is_node()
#md_
sub is_node { 1 }

#md_### _get_username()
#md_
sub _get_username {
    my ($self, $username) = @_;
    my $users = $self->users;
    if (defined $username) {
        unless (exists $users->{$username}) {
            EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////
                message => "Cet utilisateur n'est pas déclaré pour ce noeud SSH",
                params  => [node => $self->name, username => $username]
            });
        }
    }
    else {
        my @users = keys %$users;
        if (@users > 1) {
            EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////
                message => "Plusieurs utilisateurs sont disponibles pour ce noeud SSH",
                params  => [node => $self->name]
            });
        }
        $username = $users[0];
    }
    return ($username, $users->{$username});
}

#md_### _connect()
#md_
sub _connect {
    my ($self, $logger, $opts, $username, $data) = @_;
    my %options = (%{$self->options}, %{$opts || {}});
    $options{port} = $self->port;
    $options{user} = $username;
    if (exists $data->{password}) {
        $options{password} = decrypt($data->{password});
    }
    else {
        $options{passphrase} = decrypt($data->{passphrase})
            if exists $data->{passphrase};
        $options{key_path} = $data->{key_file}
            if exists $data->{key_file};
    }
    my $ssh = Net::OpenSSH->new($self->server, %options);
    if ($ssh->error) {
        $data->{_failure}  += 1;
        $data->{_timestamp} = time;
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => 'Impossible de se connecter à ce noeud SSH',
            params  => [node => $self->name, server => $self->server, username => $username, error => $ssh->error]
        });
    }
    $data->{_failure} = 0;
    return Exclus::SSH::Connection->new(logger => $logger, ssh => $ssh);
}

#md_### connect()
#md_
sub connect {
    my ($self, $logger, $user, $opts) = @_;
    return $self->_connect($logger, $opts, $self->_get_username($user));
}

#md_### try_connect()
#md_
sub try_connect {
    my ($self, $logger, $user, $opts) = @_;
    my ($username, $data) = $self->_get_username($user);
    return if $data->{_failure} && time - $data->{_timestamp} <= $data->{_failure} * 60;
    my $connection;
    try { $connection = $self->_connect($logger, $opts, $username, $data) } catch { $logger->warning("$_") };
    return $connection;
}

1;
__END__
