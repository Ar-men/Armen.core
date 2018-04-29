#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Cursus::Cmd::Plugin::Available;

#md_# Cursus::Cmd::Plugin::Available
#md_

use Exclus::Exclus;
use Moo;
use namespace::clean;

extends qw(Cursus::Cmd::Plugin);

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

    armen available

=head1 Description:

    Afficher la liste des µs déclarés

=cut
