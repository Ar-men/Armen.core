#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Diktat::Service;

#md_# Diktat::Service
#md_

use Exclus::Exclus;
use Moo;
use Exclus::Exceptions;
use namespace::clean;

extends qw(Obscur::Runner::Service);

#md_## Les attributs
#md_

###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###
has '+name'        => (default => sub { 'Diktat' });
has '+description' => (default => sub { 'Le µs chargé de générer des évènements' });
###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###

#md_## Les méthodes
#md_

#md_### _add_timer()
#md_
sub _add_timer {
    my ($self, $name, $priority, $data, $params) = @_;
    $self->scheduler->add_timer(
        $params->get_int({default => 0}, 'after'),
        $params->get_int({default => 0}, 'repeat'),
        sub {
            $self->logger->debug('Emit timer event', [name => $name]);
            $self->broker->publish($name, $priority, $data);
        },
        $name
    );
}

#md_### _add_cron()
#md_
sub _add_cron {
    my ($self, $name, $priority, $data, $params) = @_;
    $self->scheduler->add_cron(
        $params->get_str({default => '0 * * * *'}, 'cron'),
        sub {
            $self->logger->debug('Emit cron event', [name => $name]);
            $self->broker->publish($name, $priority, $data);
        },
        $name
    );
}

#md_### _add_events()
#md_
sub _add_events {
    my ($self, $events) = @_;
    $events->foreach_key(
        {create => 1},
        sub {
            my ($name, $params) = @_;
            return if $params->get_bool({default => 0}, 'disabled');
            my $type = $params->get_str('type');
            my $priority = $params->get_str({default => 'NONE'}, 'priority');
            my $data = $params->maybe_get_any('data');
            if ($type eq 'timer') {
                $self->_add_timer($name, $priority, $data, $params);
            }
            elsif ($type eq 'cron') {
                $self->_add_cron($name, $priority, $data, $params);
            }
            else {
                EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////
                    message => "Le type de cet évènement n'est pas valide",
                    params  => [event => $name, type => $type]
                });
            }
        }
    );
}

#md_### on_starting()
#md_
sub on_starting {
    my ($self) = @_;
    $self->_add_events($self->cfg->create({default => {}}, 'events'));
}

1;
__END__
