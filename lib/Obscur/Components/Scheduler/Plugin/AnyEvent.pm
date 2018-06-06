#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Components::Scheduler::Plugin::AnyEvent;

#md_# Obscur::Components::Scheduler::Plugin::AnyEvent
#md_

use Exclus::Exclus;
use AnyEvent;
use AnyEvent::Timer::Cron;
use DateTime::TimeZone::Local;
use Moo;
use Try::Tiny;
use Types::Standard qw(HashRef);
use namespace::clean;

extends qw(Obscur::Component);

#md_## Les attributs
#md_

#md_### _events
#md_
has '_events' => (
    is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _get_auto_name()
#md_
sub _get_auto_name {
    state $_id = 0;
    return '_' . $_id++;
}

#md_### add_timer()
#md_
sub add_timer {
    my ($self, $after, $repeat, $cb, $name) = @_;
    $name //= $self->_get_auto_name;
    $self->_events->{$name} = AE::timer(
        $after,
        $repeat,
        sub {
            try   { $cb->() }
            catch { $self->logger->error("$_") };
            delete $self->_events->{$name}
                unless $repeat;
        }
    );
}

#md_### add_cron()
#md_
sub add_cron {
    my ($self, $cron, $cb, $name) = @_;
    $name //= $self->_get_auto_name;
    $self->_events->{$name} = AnyEvent::Timer::Cron->new(
        cron => $cron,
        cb => sub {
            try   { $cb->() }
            catch { $self->logger->error("$_") };
        },
        time_zone => DateTime::TimeZone::Local->TimeZone()
    );
}

#md_### remove()
#md_
sub remove {
    my ($self, $regex) = @_;
    my $events = [];
    $regex //= '.+';
    foreach (keys %{$self->_events}) {
        if (m!^$regex$!) {
            delete $self->_events->{$_};
            push @$events, $_;
        }
    }
    return $events;
}

1;
__END__
