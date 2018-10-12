#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Message;

#md_# Exclus::Message
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard -types;
use Exclus::Util qw(create_uuid to_priority);
use namespace::clean;

#md_## Les attributs
#md_

#md_### id
#md_
has 'id' => (
    is => 'ro', isa => Str, default => sub { create_uuid() }
);

#md_### priority
#md_
has 'priority' => (
    is => 'ro', isa => Int, default => sub { 'NONE' }, coerce => sub { to_priority($_[0]) }
);

#md_### timestamp
#md_
has 'timestamp' => (
    is => 'ro', isa => Num, default => sub { time }
);

#md_### sender
#md_
has 'sender' => (
    is => 'ro', isa => HashRef[Str], required => 1
);

#md_### payload
#md_
has 'payload' => (
    is => 'ro', isa => Maybe[ArrayRef|Bool|HashRef|Int|Num|Str], default => sub { undef }
);

#md_### type
#md_
has 'type' => (
    is => 'ro', isa => Str, required => 1
);

#md_### reserved
#md_
has 'reserved' => (
    is => 'ro', isa => Bool, default => sub { 0 }
);

#md_### retries
#md_
has 'retries' => (
    is => 'rw', isa => Int, default => sub { 0 }
);

#md_### _after
#md_
has '_after' => (
    is => 'rw', isa => Int, clearer => 'clear_after', default => sub { 0 }
);

#md_## Les méthodes
#md_

#md_### signature()
#md_
sub signature {
    my ($self) = @_;
    return sprintf('%s[%s]', $self->type, $self->id);
}

#md_### unbless()
#md_
sub unbless {
    my ($self) = @_;
    return {
        id        => $self->id,
        priority  => $self->priority,
        timestamp => $self->timestamp,
        sender    => $self->sender,
        payload   => $self->payload,
        type      => $self->type,
        reserved  => $self->reserved,
        retries   => $self->retries
    };
}

#md_### retry()
#md_
sub retry {
    my ($self) = @_;
    my $retries = $self->retries;
    $self->retries($retries +1);
    return $retries;
}

#md_### retry_after()
#md_
sub retry_after {
    my $self = shift;
    if (@_) {
        $self->_after($_[0]);
        $self->retry;
    }
    return $self->_after;
}

1;
__END__
