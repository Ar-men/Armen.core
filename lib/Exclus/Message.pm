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
use JSON::MaybeXS;
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

#md_### retry
#md_
has 'retry' => (
    is => 'rw', isa => Int, default => sub { 0 }
);

#md_## Les méthodes
#md_

#md_### from_json()
#md_
sub from_json {
    my ($class, $data) = @_;
    return $class->new(%{JSON::MaybeXS->new(utf8 => 1)->decode($data)});
}

#md_### from_mongodb()
#md_
sub from_mongodb {
    my ($class, $data) = @_;
    $data->{id} = delete $data->{_id};
    return $class->new(%$data);
}

#md_### _render()
#md_
sub _render {
    my ($self) = @_;
    return {
        id        => $self->id,
        priority  => $self->priority,
        timestamp => $self->timestamp,
        sender    => $self->sender,
        payload   => $self->payload,
        type      => $self->type,
        reserved  => $self->reserved
    };
}

#md_### to_json()
#md_
sub to_json { JSON::MaybeXS->new(utf8 => 1)->encode($_[0]->_render) }

#md_### to_mongodb()
#md_
sub to_mongodb {
    my ($self) = @_;
    my $message = $self->_render;
    $message->{_id} = delete $message->{id};
    return $message;
}

1;
__END__
