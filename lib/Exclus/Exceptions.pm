#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Exceptions;

#md_# Exclus::Exceptions
#md_

use strict;
use warnings;

#md_## Les méthodes
#md_

#md_### import()
#md_
sub import {
    my $class = shift;
    my $caller = caller;
    no strict 'refs';
    foreach my $exception (@_) {
        my $default = 'EX';
        foreach my $part (split('::', $exception)) {
            push @{"$default\::$part\::ISA"}, $default;
            $default .= "::$part";
        }
    }
}

package EX; ############################################################################################################

#md_# EX
#md_

use Exclus::Exclus;
use List::Util qw(pairmap);
use Moo;
use Ref::Util qw(is_hashref);
use Safe::Isa qw($_isa);
use Try::Tiny;
use Types::Standard qw(ArrayRef HashRef Str);
use Exclus::Util qw(clean_string dump_data);
use namespace::clean;

use overload bool => sub {1}, '""' => sub { shift->to_string }, fallback => 1;

#md_## Les attributs
#md_

#md_### message
#md_
has 'message' => (
    is => 'ro', isa => Str, default => sub { '?' }
);

#md_### params
#md_
has 'params' => (
    is => 'ro', isa => ArrayRef, default => sub { [] }
);

#md_### trace
#md_
has 'trace' => (
    is => 'ro', isa => Str, default => sub { '' }
);

#md_### payload
#md_
has 'payload' => (
    is => 'rw', isa => HashRef, default => sub { {} }
);

#md_## Les méthodes
#md_

#md_### throw()
#md_
sub throw {
    my ($class, $data) = @_;
    die $class->new(is_hashref($data) ? %$data : (message => $data // '?'));
}

#md_### rethrow()
#md_
sub rethrow { die $_[0] }

#md_### to_string()
#md_
sub to_string {
    my ($self) = @_;
    my $string = "!Exception! " . clean_string($self->message);
    my $params = $self->params;
    $string .= '> ' . join q{, }, pairmap {"$a: " . dump_data($b)} @$params
        if @$params;
    my $trace = $self->trace;
    return $trace ? "$string --$trace" : $string;
}

#md_### simple_trace()
#md_
sub simple_trace {
    my (undef, $file_name, $line) = caller;
    return " at $file_name line $line";
}

#md_### croak_trace()
#md_
sub croak_trace {
    local @failure::CARP_NOT = (scalar caller);
    return Carp::shortmess('');
}

#md_### confess_trace()
#md_
sub confess_trace {
    local @failure::CARP_NOT = (scalar caller);
    return Carp::longmess('');
}

#md_### TODO()
#md_
sub TODO {
    my $class = shift;
    $class->throw({message => 'A faire (non implémenté)', trace => $class->simple_trace, @_});
}

#md_### try_run()
#md_
sub try_run {
    my ($class, $cb, $payload) = @_;
    my $wa = wantarray;
    my @result;
    try {
        if ($wa) {
            @result = $cb->();
        } elsif (defined $wa) {
            $result[0] = $cb->();
        } else {
            $cb->();
        }
    }
    catch {
        my $e = $_;
        $payload //= {};
        if ($e->$_isa($class)) {
            $e->payload({%$payload, %{$e->payload}});
            $e->rethrow;
        }
        $class->throw({message => "$e", payload => $payload});
    };
    return $wa ? @result : $result[0];
}

#md_### AUTOLOAD()
#md_
sub AUTOLOAD {
    my ($self, $default) = @_;
    our $AUTOLOAD;
    my $key = $AUTOLOAD;
    $key =~ s/.*:://;
    return exists $self->payload->{$key} ? $self->payload->{$key} : $default;
}

1;
__END__
