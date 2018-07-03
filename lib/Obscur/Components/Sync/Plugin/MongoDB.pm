#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Components::Sync::Plugin::MongoDB;

#md_# Obscur::Components::Sync::Plugin::MongoDB
#md_

use Exclus::Exclus;
use BSON::Types qw(bson_time);
use Guard qw(guard);
use Moo;
use Safe::Isa qw($_isa);
use Try::Tiny;
use Types::Standard qw(InstanceOf);
use Exclus::Exceptions qw(Sync::UnableToLock);
use Exclus::Util qw(ms_sleep t0 t0_ms_elapsed);
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

#md_### _sync
#md_
has '_sync' => (
    is => 'ro',
    isa => InstanceOf['MongoDB::Collection'],
    lazy => 1,
    default => sub { $_[0]->_mongo->get_collection(qw(armen sync)) },
    init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _find_or_insert()
#md_
sub _find_or_insert {
    my ($self, $resource, $t0, $timeout) = @_;
    my $end = 0;
    for (;;) {
        my $doc = $self->_sync->find_one({_id => $resource});
        return $doc
            if $doc;
        try {
            $self->_sync->insert_one({
                _id         => $resource,
                writer      => undef,
                readers     => [],
                acquired_at => undef
            });
            $end = 1;
        }
        catch {
            die $_ unless $_->$_isa('MongoDB::DuplicateKeyError');
        };
        unless ($end) {
            if (t0_ms_elapsed($t0) >= $timeout) {
                EX::Sync::UnableToLock->throw({ ##//////////////////////////////////////////////////////////////////////
                    message => "Impossible de créer le verrou pour cette ressource",
                    params  => [resource => $resource, timeout => $timeout]
                });
            }
            else {
                ms_sleep(50);
            }
        }
    }
}

#md_### _write_lock()
#md_
sub _write_lock {
    my ($self, $resource, $t0, $timeout) = @_;
    my $doc = $self->_find_or_insert($resource, $t0, $timeout);
    return 0
        if $doc && defined $doc->{writer} && $doc->{writer} eq $self->runner->id;
    for (;;) {
        my $result = $self->_sync->update_one(
            {
                _id     => $resource,
                writer  => undef,
                readers => []
            },
            {
                '$set' => {writer => $self->runner->id, acquired_at => bson_time()}
            }
        );
        return 1
            if $result->modified_count;
        if (t0_ms_elapsed($t0) >= $timeout) {
            EX::Sync::UnableToLock->throw({ ##//////////////////////////////////////////////////////////////////////////
                message => "Impossible d'acquérir cette ressource en écriture",
                params  => [resource => $resource, timeout => $timeout]
            });
        }
        else {
            ms_sleep(50);
        }
    }
}

#md_### _write_unlock()
#md_
sub _write_unlock {
    my ($self, $resource) = @_;
    $self->_sync->update_one(
        {
            _id    => $resource,
            writer => $self->runner->id
        },
        {
            '$set' => {writer => undef, acquired_at => undef}
        }
    );
}

#md_### lock_w_unlock()
#md_
sub lock_w_unlock {
    my ($self, $resource, $timeout) = @_;
    return
        $self->_write_lock($resource, t0, $timeout // 5000) ? guard { $self->_write_unlock($resource) } : undef;
}

#md_### _read_lock()
#md_
sub _read_lock {
    my ($self, $resource, $t0, $timeout) = @_;
    my $doc = $self->_find_or_insert($resource, $t0, $timeout);
    if ($doc) {
        foreach (@{$doc->{readers}}) {
            return 0
                if $_ eq $self->runner->id;
        }
    }
    for (;;) {
        my $result = $self->_sync->update_one(
            {
                _id    => $resource,
                writer => undef
            },
            {
                '$addToSet' => {readers => $self->runner->id},
                '$set'      => {acquired_at => bson_time()}
            }
        );
        return 1
            if $result->modified_count;
        if (t0_ms_elapsed($t0) >= $timeout) {
            EX::Sync::UnableToLock->throw({ ##//////////////////////////////////////////////////////////////////////////
                message => "Impossible d'acquérir cette ressource en lecture",
                params  => [resource => $resource, timeout => $timeout]
            });
        }
        else {
            ms_sleep(50);
        }
    }
}

#md_### _read_unlock()
#md_
sub _read_unlock {
    my ($self, $resource) = @_;
    $self->_sync->update_one(
        {
            _id => $resource
        },
        {
            '$pull' => {readers => $self->runner->id},
            '$set'  => {acquired_at => undef}
        }
    );
}

#md_### lock_r_unlock()
#md_
sub lock_r_unlock {
    my ($self, $resource, $timeout) = @_;
    return
        $self->_read_lock($resource, t0, $timeout // 5000) ? guard { $self->_read_unlock($resource) } : undef;
}

1;
__END__
