#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Jargon::Cmd::Plugin::Start;

#md_# Jargon::Cmd::Plugin::Start
#md_

use Exclus::Exclus;
use Moo;
use namespace::clean;

extends qw(Jargon::Cmd::Plugin);

#md_## Les méthodes
#md_

#md_### run()
#md_
sub run {
    my ($self, @to_start) = @_;
    my $services = $self->config->create({default => {}}, 'services');
    if ($services->count_keys) {
        push @to_start, 'Satyre' unless @to_start;
        say 'Lancement des µs:';
        foreach (@to_start) {
            my $service = ucfirst(lc($_));
            say "---> $service";
            if ($services->exists($service)) {
                system("armen.service --service=$service &");
            }
            else {
                say "Ce µs n'existe pas.";
            }
        }
    }
    else {
        say "Aucun µs n'a été déclaré.";
    }
}

1;
__END__

=encoding utf8

=head1 Commande:

    armen start [µs.name ...]

=head1 Description:

    Lancer de nouvelles instances de µs

=cut
