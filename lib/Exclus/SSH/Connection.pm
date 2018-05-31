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
use Types::Standard qw(InstanceOf Maybe Str);
use Exclus::Exceptions;
use namespace::clean;

#md_## Les attributs
#md_

#md_### logger
#md_
has 'logger' => (
    is => 'ro', isa => Maybe[InstanceOf['Exclus::Logger']], required => 1
);

#md_### ssh
#md_
has 'ssh' => (
    is => 'ro', isa => InstanceOf['Net::OpenSSH'], required => 1
);

#md_## Les méthodes
#md_

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
    if ($self->logger) {
        my $ssh = $self->ssh;
        $self->logger->debug(
            'SSH',
            [server => $ssh->get_host, username => $ssh->get_user, cmd => $cmd]
        );
    }
}

#md_### _throw_error()
#md_
sub _throw_error {
    my ($self, $cmd, $stderr) = @_;
    my ($field, $value);
    my $ssh = $self->ssh;
    if ($stderr) {
        $field = 'stderr';
        $value = $stderr;
    }
    else {
        $field = 'error';
        $value = $ssh->error;
    }
    EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////////
        message => 'SSH',
        params  => [
            cmd      => $cmd,
            server   => $ssh->get_host,
            username => $ssh->get_user,
            $field   => $value
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

1;
__END__
