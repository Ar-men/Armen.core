#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Cursus::Cmd::Plugin::Version;

#md_# Cursus::Cmd::Plugin::Version
#md_

use Exclus::Exclus;
use Moo;
use Path::Iterator::Rule;
use YAML::XS qw(LoadFile);
use namespace::clean;

extends qw(Cursus::Cmd::Plugin);

#md_## Les méthodes
#md_

#md_### run()
#md_
sub run {
    my ($self) = @_;
    my $rows = [];
    my $rule = Path::Iterator::Rule->new;
    $rule->file->nonempty;
    $rule->name('Version.yaml');
    $rule->min_depth(2);
    $rule->max_depth(2);
    foreach ($rule->all($self->runner->dir->parent->stringify)) {
        my $data = LoadFile($_);
        push @$rows, [$data->{project}, $data->{version}]
            if exists $data->{project} && exists $data->{version};
    }
    $self->render_table($rows, 'PROJECT NAME', 'VERSION');
}

1;
__END__

=encoding utf8

=head1 Commande:

    armen version

=head1 Description:

    Afficher les projets et leur numéro de version

=cut
