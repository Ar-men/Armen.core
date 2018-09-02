#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Jargon::Cmd::Plugin::Kill;

#md_# Jargon::Cmd::Plugin::Kill
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
    my ($self) = @_;
}

1;
__END__

=encoding utf8

=head1 Commande:

    armen kill <µs.id>

=head1 Description:

    Tuer le µs spécifié par son identifiant

=cut
