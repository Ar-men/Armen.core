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

#md_### _get_elapsed_time()
#md_
sub _get_elapsed_time {
    my ($class, $time) = @_;
    my $elapsed = time - $time;
    if ($elapsed >= 86400) {
        $elapsed = int($elapsed/86400);
        return sprintf("%3u (d)", $elapsed);
    }
    if ($elapsed >= 3600) {
        $elapsed = int($elapsed/3600);
        return sprintf("%3u (h)", $elapsed);
    }
    if ($elapsed >= 60) {
        $elapsed = int($elapsed/60);
        return sprintf("%3u (m)", $elapsed);
    }
    return sprintf("%3u (s)", $elapsed);
}

#md_### _registered()
#md_
sub _registered {
    my ($self) = @_;
    my @services = $self->runner->discovery->get_services;
    if (@services) {
        my $rows = [];
        foreach (sort _sort @services) {
            my $row = [$_->{id}, $_->{name}, $_->{status}, $_->{dc}, $_->{node}, $_->{pid}, $_->{port}];
            push @$row, $self->_get_elapsed_time($_->{timestamp});
            push @$row, sprintf('%5u (s)', time - $_->{heartbeat});
            push @$rows, $row;
        }
        $self->render_table($rows, qw(ID NAME STATUS DC NODE PID PORT ELAPSED HEARTBEAT));
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
        my $ex = $cv->recv;
        die $ex if $ex;
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
