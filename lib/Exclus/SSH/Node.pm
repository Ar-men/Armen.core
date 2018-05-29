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
use Ref::Util qw(is_hashref);
use Types::Standard qw(Bool HashRef Int Str);
use Exclus::Crypt qw(try_decrypt);
use Exclus::Exceptions;
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
        $data->{_usable}    = 1;
        $data->{_timestamp} = 0;
    }
}

#md_### is_node()
#md_
sub is_node { 1 }

#md_### _get_username()
#md_
sub _get_username {
    my ($self) = @_;
    my @users = keys %{$self->users};
    if (@users > 1) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Plusieurs utilisateurs sont disponibles pour ce noeud SSH",
            params  => [node => $self->name]
        });
    }
    return $users[0];
}

#md_### connect()
#md_
sub connect {
    my $self = shift;
    my $opts = is_hashref($_[0]) ? shift : {};
    my ($username, $logger) = @_;
    my %options = (%{$self->options}, %$opts);
    $options{port} = $self->port;
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
        $username = $self->_get_username;
    }
    $options{user} = $username;
    my $data = $users->{$username};
    if (exists $data->{password}) {
        $options{password} = try_decrypt($data->{password});
    }
    else {
        $options{passphrase} = try_decrypt($data->{passphrase})
            if exists $data->{passphrase};
        $options{key_path} = $data->{key}
            if exists $data->{key};
    }
}

1;
__END__
