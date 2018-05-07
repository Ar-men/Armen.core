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
use Moo;
use Types::Standard qw(ArrayRef HashRef InstanceOf Str);
use Exclus::Data;
use Exclus::Message;
use namespace::clean;

extends qw(Obscur::Component);

#md_## Les attributs
#md_

#md_### _mongo
#md_
has '_mongo' => (
    is => 'ro',
    isa => InstanceOf['Exclus::Databases::MongoDB'],
    lazy => 1,
    default => sub { $_[0]->runner->build_resource('MongoDB', $_[0]->cfg) },
    init_arg => undef
);

#md_### _broker
#md_
has '_broker' => (
    is => 'ro',
    isa => InstanceOf['MongoDB::Collection'],
    lazy => 1,
    default => sub { $_[0]->_mongo->get_collection(qw(armen broker)) },
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
            collection => $self->_mongo->get_collection('armen', "broker.queue.$queue"),
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
        sender   => $self->runner->who_i_am,
        priority => $priority,
        payload  => $data
    );
    my $bindings = $self->_bindings;
    foreach my $queue (keys %$bindings) {
        my $collection = $bindings->{$queue}->{collection};
        foreach (@{$bindings->{$queue}->{bindings}}) {
            if ($type =~ m!^$_$!) {
                $collection->insert_one($message->to_mongodb);
                $self->logger->debug('Publish', ['@id' => $message->id, queue => $queue, type => $type])
                    if $self->debug;
                last;
            }
        }
    }
}

1;
__END__
