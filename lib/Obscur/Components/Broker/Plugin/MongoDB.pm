#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Components::Broker::Plugin::MongoDB;

#md_# Obscur::Components::Broker::Plugin::MongoDB
#md_

use Exclus::Exclus;
use AnyEvent;
use Moo;
use Try::Tiny;
use Types::Standard -types;
use Exclus::Data;
use Exclus::Exceptions;
use Exclus::Message;
use Exclus::Util qw(exponential_backoff);
use namespace::clean;

extends qw(Obscur::Databases::MongoDB);

#md_## Les attributs
#md_

#md_### _broker
#md_
has '_broker' => (
    is => 'ro',
    isa => InstanceOf['MongoDB::Collection'],
    lazy => 1,
    default => sub { $_[0]->get_collection(qw(armen broker)) },
    init_arg => undef
);

#md_### _bindings
#md_
has '_bindings' => (
    is => 'lazy', isa => HashRef, init_arg => undef
);

#md_### _to_publish
#md_
has '_to_publish' => (
    is => 'ro', isa => ArrayRef, default => sub { [] }, init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _build__bindings()
#md_
sub _build__bindings {
    my $self = shift;
    my $bindings = {};
    foreach ($self->_broker->find->all) {
        my $cfg = Exclus::Data->new(data => $_);
        my $queue = $cfg->get_str('_id');
        $bindings->{$queue} = {
            collection => $self->get_collection('armen', "broker.queue.$queue"),
            bindings   => $cfg->get({type => ArrayRef[Str]}, 'bindings')
        }
    }
    return $bindings;
}

#md_### _build_message_document()
#md_
sub _build_message_document {
    my ($self, $type, $priority, $data) = @_;
    my $message = Exclus::Message->new(
        type     => $type,
        sender   => $self->runner->properties,
        priority => $priority,
        payload  => $data
    );
    my $document = $message->unbless;
    $document->{_id} = delete $document->{id};
    return ($message, $document);
}

#md_### _try_publish()
#md_
sub _try_publish {
    my ($self, $collection, $document) = @_;
    my $end;
    my $fifo = $self->_to_publish;
    push @$fifo, [$collection, $document];
    do {
        ($collection, $document) = @{shift @$fifo};
        try {
            $collection->insert_one($document);
            $self->logger->debug('Published', ['@id' => $document->{_id}])
                if $self->debug;
        }
        catch {
            unshift @$fifo, [$collection, $document];
            $self->logger->notice("$_");
            my $count = @$fifo;
            $self->logger->warning("Des messages sont en attente de publication par le 'Broker'", [count => $count])
                unless $count % 10;
            $end = 1;
        };
    } while (@$fifo && !$end);
}

#md_### publish()
#md_
sub publish {
    my ($self, $type, $priority, $data) = @_;
    my ($message, $document) = $self->_build_message_document($type, $priority, $data);
    my $bindings = $self->_bindings;
    foreach my $queue (keys %$bindings) {
        my $collection = $bindings->{$queue}->{collection};
        foreach (@{$bindings->{$queue}->{bindings}}) {
            if ($type =~ m!^$_$!) {
                $self->logger->debug('Publish', ['@id' => $message->id, queue => $queue, type => $type])
                    if $self->debug;
                $self->_try_publish($collection, $document);
                last;
            }
        }
    }
}

#md_### _ack_message()
#md_
sub _ack_message {
    my ($self, $collection, $message) = @_;
    try {
        $collection->delete_one({_id => $message->id});
    }
    catch {
        $self->logger->error(
            "Impossible de supprimer ce message dans le 'Broker'",
            [
                reason  => "$_",
                message => $message->signature,
                TODO    => 'Supprimer le message dans le backend'
            ]
        );
    };
}

#md_### _requeue_message()
#md_
sub _requeue_message {
    my ($self, $collection, $message, $after) = @_;
    try {
        $collection->update_one(
            {_id => $message->id},
            {'$set' => {reserved => 0, timestamp => time + $after, retries => $message->retries}}
        );
    }
    catch {
        $self->logger->error(
            "Impossible de réactiver ce message dans le 'Broker'",
            [
                reason  => "$_",
                message => $message->signature,
                TODO    => 'Réactiver le message dans le backend'
            ]
        );
    };
}

#md_### _handle_message()
#md_
sub _handle_message {
    my ($self, $collection, $cb_name, $message) = @_;
    try {
        $self->logger->debug('Consume', ['@id' => $message->id, type => $message->type])
            if $self->debug;
        $message->clear_after;
        $self->runner->$cb_name($message->type, $message);
        $message->retry_after
            ? $self->_requeue_message($collection, $message, $message->retry_after)
            : $self->_ack_message(    $collection, $message);
    }
    catch {
        my $after = exponential_backoff(my $retries = $message->retry, 30, 3840);
        $self->logger->warning(
            "Echec lors du traitement d'un message du 'Broker'",
            [
                reason      => "$_",
                message     => $message->signature,
                retry_after => "$after s",
                retries     => $retries
            ]
        );
        $self->_requeue_message($collection, $message, $after);
    };
}

#md_### _handle_document()
#md_
sub _handle_document {
    my ($self, $collection, $cb_name, $document) = @_;
    try {
        $document->{id} = delete $document->{_id};
        $self->_handle_message($collection, $cb_name, Exclus::Message->new($document));
    }
    catch {
        $self->logger->error(
            "Ce message du 'Broker' n'est pas valide",
            [
                reason  => "$_",
                message => $document,
                TODO    => 'Corriger le message dans le backend'
            ]
        );
    };
}

#md_### _consume_forever()
#md_
sub _consume_forever {
    my ($self, $retries, $after, $collection, $cb_name) = @_;
    return
        if $self->runner->is_stopping;
    my $w;
    $w = AE::timer(
        $after,
        0,
        sub {
            undef $w;
            try {
                my $document = $collection->find_one_and_update(
                    {reserved => 0, timestamp => {'$lt' => time}},
                    {'$set' => {reserved => 1, timestamp => time}},
                    {sort => {priority => -1, timestamp => 1}}
                );
                $retries = 0;
                if ($document) {
                    $self->_handle_document($collection, $cb_name, $document);
                    $after = 0;
                }
                else {
                    $after = 1;
                }
            }
            catch {
                $after = exponential_backoff($retries, 30, 3840);
                $self->logger->warning(
                    "Impossible de consommer les messages du 'Broker'",
                    [
                        reason      => "$_",
                        retry_after => "$after s",
                        retries     => $retries
                    ]
                );
                $retries++;
            };
            $self->_consume_forever($retries, $after, $collection, $cb_name);
        }
    );
}

#md_### consume()
#md_
sub consume {
    my ($self, $queue, $cb_name) = @_;
    if (my $collection = $self->_bindings->{$queue}->{collection}) {
        $self->_consume_forever(0, 1, $collection, $cb_name // 'on_message');
    }
    else {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Cette queue n'existe pas",
            params  => [queue => $queue]
        })
    }
}

1;
__END__
