#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Jargon::Cmd::Plugin::Stop;

#md_# Jargon::Cmd::Plugin::Stop
#md_

use Exclus::Exclus;
use Moo;
use Try::Tiny;
use namespace::clean;

extends qw(Jargon::Cmd::Plugin);

#md_## Les méthodes
#md_

#md_### run()
#md_
sub run {
    my ($self, @to_stop) = @_;
    my @services = $self->runner->discovery->get_services;
    if (@services) {
        unless (@to_stop) {
            push @to_stop, $_->{id} foreach @services;
        }
        say 'Arrêt des µs:';
        foreach my $value (@to_stop) {
            foreach (@services) {
                my $service_name = $_->{name};
                my $pid = $_->{pid};
                if (($value eq $_->{id} || ucfirst(lc($value)) eq $service_name) && $pid ne '#') {
                    say "---> ${service_name}[$_->{id}]";
                    my $node_name = $_->{node};
                    if ($node_name eq $self->runner->node_name) {
                        kill 'TERM', $pid;
                    }
                    elsif (my $ssh = $self->runner->get_resource('SSH', $node_name)->try_connect($self->logger)) {
                        try { $ssh->kill('-TERM', $pid) } catch { $self->logger->error("$_") };
                    }
                }
            }
        }
    }
    else {
        say "Aucun µs n'est enregistré.";
    }
}

1;
__END__

=encoding utf8

=head1 Commande:

    armen stop [µs.(id|name) ...]

=head1 Description:

    Stopper les µs spécifiés par leur nom ou leur identifiant

=cut
