#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Cursus::Cmd::Plugin::Registered;

#md_# Cursus::Cmd::Plugin::Registered
#md_

use Exclus::Exclus;
use EV;
use AnyEvent;
use Moo;
use Try::Tiny;
use namespace::clean;

extends qw(Cursus::Cmd::Plugin);

#md_## Les méthodes
#md_

#md_### _sort()
#md_
sub _sort {
    $a->{name} cmp $b->{name} || $a->{dc} cmp $b->{dc} || $a->{node} cmp $b->{node} || $a->{port} <=> $b->{port};
}

#md_### _get_uptime()
#md_
sub _get_uptime {
    my ($class, $time) = @_;
    my $uptime = time - $time;
    return sprintf('%dd', int($uptime/86400)) if $uptime >= 86400;
    return sprintf('%dh', int($uptime/ 3600)) if $uptime >=  3600;
    return sprintf('%dm', int($uptime/   60)) if $uptime >=    60;
    return sprintf('%ds',     $uptime);
}

#md_### _registered()
#md_
sub _registered {
    my ($self) = @_;
    my @services = $self->runner->discovery->get_services;
    if (@services) {
        my $rows = [];
        foreach (sort _sort @services) {
            push @$rows, [
                $_->{id},
                $_->{name},
                $_->{status},
                $_->{dc},
                $_->{node},
                $_->{port},
                sprintf('%ds', time - $_->{heartbeat}),
                $self->_get_uptime($_->{timestamp}),
                $_->{pid}
            ];
        }
        $self->render_table($rows, qw(ID NAME STATUS DC NODE PORT HEARTBEAT UPTIME PID));
    }
    else {
        say "Aucun µs n'est enregistré.";
    }
}

#md_### run()
#md_
sub run {
    my ($self, $repeat) = @_;
    if ($repeat) {
        my @watchers;
        my $cv = AE::cv;
        push @watchers, AE::timer(
            0,
            $repeat,
            sub {
                try {
                    $self->restore_position;
                    $self->clear_to_end;
                    $self->_registered;
                }
                catch {
                    $cv->send($_);
                };
            }
        );
        push @watchers, AE::signal('INT', sub { $cv->send });
        $self->clear_terminal;
        $self->store_position;
        my $e = $cv->recv;
        die $e if $e;
    }
    else {
        $self->_registered;
    }
}

1;
__END__

=encoding utf8

=head1 Commande:

    armen registered

=head1 Description:

    Afficher la liste des µs enregistrés

=cut
