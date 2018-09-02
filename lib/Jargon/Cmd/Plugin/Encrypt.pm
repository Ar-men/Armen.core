#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Jargon::Cmd::Plugin::Encrypt;

#md_# Jargon::Cmd::Plugin::Encrypt
#md_

use Exclus::Exclus;
use Moo;
use Exclus::Crypt qw(encrypt);
use namespace::clean;

extends qw(Jargon::Cmd::Plugin);

#md_## Les méthodes
#md_

#md_### run()
#md_
sub run {
    my ($self, $string) = @_;
    printf("$string ---> %s\n", encrypt($string));
}

1;
__END__

=encoding utf8

=head1 Commande:

    armen encrypt <string>

=head1 Description:

    Crypter une chaine de caractères

=cut
