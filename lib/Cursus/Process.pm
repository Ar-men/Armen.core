#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Cursus::Process;

#md_# Cursus::Process
#md_

use Exclus::Exclus;
use Pod::Find qw(pod_where);
use Pod::Usage;
use Moo;
use Try::Tiny;
use Exclus::Util qw(plugin to_stderr);
use namespace::clean;

extends qw(Obscur::Runner::Process);

#md_## Les attributs
#md_

###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###
has '+name'        => (default => sub { 'Cursus' });
has '+description' => (default => sub { "Client version ligne de commande" });
###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###

#md_## Les méthodes
#md_

#md_### setup()
#md_
sub setup {
    my ($self) = @_;
    my $config = $self->config;
    $config->set(stdin  => '');
    $config->set(stdout => '');
    $config->set(stderr => '');
}

#md_### _help()
#md_
sub _help {
    my $self = shift;
    pod2usage(
        -exitval => 'NOEXIT',
        -input   => pod_where({-inc => 1}, @_ ? sprintf('Cursus::Cmd::Plugin::%s', ucfirst($_[0])) : __PACKAGE__),
        -verbose => 2
    );
}

#md_### run()
#md_
sub run {
    my ($self) = @_;
    $self->info('Cmd', [armen => join(' ', @ARGV)]);
    my $cmd = shift @ARGV // 'help';
    if ($cmd eq 'help') { $self->_help(@ARGV) }
    else {
        try {
            plugin('Cursus::Cmd', ucfirst($cmd), {runner => $self})->run(@ARGV);
        }
        catch {
            to_stderr($_);
            die $_;
        };
    }
}

1;
__END__

=encoding utf8

=head1 Ar-Men

    Écosystème basé sur les microservices.

=head1 Les commandes:

    armen help                        [subcommand] - Afficher l'aide en général ou pour une sous-commande
    armen version                                  - Afficher la liste des projets et leur numéro de version
    armen available                                - Afficher la liste des µs déclarés
    armen registered                               - Afficher la liste des µs enregistrés
    armen start                      [µs.name ...] - Lancer de nouvelles instances de µs
    armen stop                  [µs.(id|name) ...] - Stopper les µs spécifiés
    armen kill                             <µs.id> - Tuer le µs spécifié
    armen execute [µs.(id|name) [cmd [value ...]]] - Exécution d'une commande par les µs spécifiés
    ----- -------
    armen encrypt                         <string> - Crypter une chaine de caractères
    armen decrypt                         <string> - Décrypter une chaine préalablement cryptée
    ----- -------

    ...

=cut
