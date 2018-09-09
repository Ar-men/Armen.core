#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Resources::Plugin::SQL;

#md_# Obscur::Resources::Plugin::SQL
#md_

use Exclus::Exclus;
use Moo;
use Exclus::Databases::SQL;
use namespace::clean;

extends qw(Obscur::Resources::Plugin);

#md_## Les méthodes
#md_

#md_### build_resource()
#md_
sub build_resource {
    my ($self, $runner, $name) = @_;
    my $cfg = $self->cfg;
    return Exclus::Databases::SQL->new(
        dsn     => $cfg->get_str(                         'dsn'),
        options => $cfg->get_hashref({default => {}}, 'options'),
        timeout => $cfg->get_int(    {default => 60}, 'timeout')
    )
}

1;
__END__
