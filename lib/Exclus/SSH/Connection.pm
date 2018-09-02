#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::SSH::Connection;

#md_# Exclus::SSH::Connection
#md_

use Exclus::Exclus;
use Moo;
use Net::OpenSSH::Constants qw(:error);
use Ref::Util qw(is_hashref);
use Types::Standard -types;
use Exclus::Exceptions;
use namespace::clean;

#md_## Les attributs
#md_

#md_### logger
#md_
has 'logger' => (
    is => 'ro', isa => InstanceOf['Exclus::Logger'], required => 1
);

#md_### ssh
#md_
has 'ssh' => (
    is => 'ro', isa => InstanceOf['Net::OpenSSH'], required => 1
);

#md_## Les méthodes
#md_

#md_### get_details()
#md_
sub get_details {
    my ($self) = @_;
    return ($self->ssh->get_host, $self->ssh->get_user);
}

#md_### _sudo()
#md_
sub _sudo {
    my ($self, $opts, $cmd) = @_;
    if (exists $opts->{sudo}) {
        unshift(@$cmd, 'sudo') if $opts->{sudo};
        delete $opts->{sudo};
    }
}

#md_### _debug()
#md_
sub _debug {
    my ($self, $cmd) = @_;
    my $ssh = $self->ssh;
    $self->logger->debug('SSH', [server => $ssh->get_host, username => $ssh->get_user, cmd => $cmd] );
}

#md_### _throw_error()
#md_
sub _throw_error {
    my ($self, $cmd, $stderr) = @_;
    my $ssh = $self->ssh;
    EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////////
        message => 'SSH',
        params  => [
            cmd      => $cmd,
            server   => $ssh->get_host,
            username => $ssh->get_user,
            $stderr ? (stderr => $stderr) : (error => $ssh->error)
        ]
    });
}

#md_### system()
#md_
sub system {
    my $self = shift;
    my $opts = is_hashref($_[0]) ? shift : {};
    my $cmd = [@_];
    $self->_sudo($opts, $cmd);
    $self->_debug($cmd);
    $self->_throw_error($cmd) unless $self->ssh->system($opts, @$cmd);
}

#md_### capture()
#md_
sub capture {
    my $self = shift;
    my $opts = is_hashref($_[0]) ? shift : {};
    my $cmd = [@_];
    $self->_sudo($opts, $cmd);
    $self->_debug($cmd);
    my $ssh = $self->ssh;
    my ($stdout, $stderr) = $ssh->capture2($opts, @$cmd);
    my $exit_code = $?;
    $self->_throw_error($cmd) if $ssh->error && $ssh->error != OSSH_SLAVE_CMD_FAILED;
    return
        wantarray ? ($exit_code, $stdout, $stderr) : $exit_code;
}

#md_### execute()
#md_
sub execute {
    my $self = shift;
    my $opts = is_hashref($_[0]) ? shift : {};
    my $cmd = [@_];
    $self->_sudo($opts, $cmd);
    $self->_debug($cmd);
    my $ssh = $self->ssh;
    my ($stdout, $stderr) = $ssh->capture2($opts, @$cmd);
    if ($stderr) {
        $self->_throw_error($cmd, $stderr);
    }
    elsif ($ssh->error) {
        $self->_throw_error($cmd);
    }
    return $stdout;
}

#md_### DESTROY()
#md_
sub DESTROY {}

#md_### AUTOLOAD()
#md_
sub AUTOLOAD {
    my $self = shift;
    my $opts = is_hashref($_[0]) ? shift : {};
    our $AUTOLOAD;
    my $cmd = $AUTOLOAD;
    $cmd =~ s/.*:://;
    return $self->execute($opts, $cmd, @_);
}

#md_### compute_md5()
#md_
sub compute_md5 {
    my $self = shift;
    my $output = $self->md5sum(@_);
    if ($output =~ m!^([a-f0-9]{32})\s!) {
        return $1;
    }
    EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////////
        message => 'Cette valeur ne correspond pas à un md5',
        params  => [output => $output]
    });
}

1;
__END__
