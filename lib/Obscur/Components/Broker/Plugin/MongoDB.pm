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

#md_### publish()
#md_
sub publish {
    my ($self, $type, $priority, $data) = @_;
    my $message = Exclus::Message->new(
        type     => $type,
        sender   => $self->runner->properties,
        priority => $priority,
        payload  => $data
    );
    my $bindings = $self->_bindings;
    foreach my $queue (keys %$bindings) {
        my $collection = $bindings->{$queue}->{collection};
        foreach (@{$bindings->{$queue}->{bindings}}) {
            if ($type =~ m!^$_$!) {
                $self->logger->debug('Publish', ['@id' => $message->id, queue => $queue, type => $type])
                    if $self->debug;
                $collection->insert_one($message->to_mongodb);
                last;
            }
        }
    }
}

#md_### try_publish()
#md_
sub try_publish {
    my ($self, @args) = @_;
    try { $self->publish(@args) } catch { $self->logger->error("$_") };
}

#md_### _ack_message()
#md_
sub _ack_message {
    my ($self, $collection, $message) = @_;
    try { $collection->delete_one({_id => $message->id}) } catch { $self->logger->error("$_") };
}

#md_### _requeue_message()
#md_
sub _requeue_message {
    my ($self, $collection, $message, $after) = @_;
    try   { $collection->update_one({_id => $message->id}, {'$set' => {reserved => 0, timestamp => time + $after}}) }
    catch { $self->logger->error("$_") };
}

#md_### _get_message()
#md_
sub _get_message {
    my ($self, $after, $collection, $cb_name) = @_;
    return
        if $self->runner->is_stopping;
    my $w;
    $w = AE::timer(
        $after,
        0,
        sub {
            undef $w;
            try {
                my $doc = $collection->find_one_and_update(
                    {reserved => 0, timestamp => {'$lt' => time}},
                    {'$set' => {reserved => 1, timestamp => time}},
                    {sort => {priority => -1, timestamp => 1}}
                );
                if ($doc) {
                    try {
                        my $message = Exclus::Message->from_mongodb($doc);
                        $self->logger->debug('Consume', ['@id' => $message->id, type => $message->type])
                            if $self->debug;
                        try {
                            $self->runner->$cb_name($message->type, $message);
                            $message->retry
                                ? $self->_requeue_message($collection, $message, $message->retry)
                                : $self->_ack_message(    $collection, $message);
                        }
                        catch {
                            $self->logger->error("$_");
                            $self->_requeue_message($collection, $message, 30);
                        };
                    }
                    catch {
                        $self->logger->error("$_");
                    };
                    $after = 0.1;
                }
                else {
                    $after = 1;
                }
            }
            catch {
                $self->logger->error("$_");
                $after = 10;
            };
            $self->_get_message($after, $collection, $cb_name);
        }
    );
}

#md_### consume()
#md_
sub consume {
    my ($self, $queue, $cb_name) = @_;
    if (my $collection = $self->_bindings->{$queue}->{collection}) {
        $self->_get_message(1, $collection, $cb_name // 'on_message');
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
