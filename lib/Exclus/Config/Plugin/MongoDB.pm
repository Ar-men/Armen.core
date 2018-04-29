#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Config::Plugin::MongoDB;

#md_# Exclus::Config::Plugin::MongoDB
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard qw(Str);
use Exclus::Databases::MongoDB;
use Exclus::Exceptions;
use namespace::clean;

extends qw(Exclus::Config::Plugin);

#md_## Les attributs
#md_

#md_### uri
#md_
has 'uri' => (
    is => 'ro', isa => Str, required => 1
);

#md_## Les méthodes
#md_

#md_### load()
#md_
sub load {
    my $self = shift;
    my $config = {};
    my $mongo = Exclus::Databases::MongoDB->new(uri => $self->uri);
    my $cursor = $mongo->get_collection(qw(armen config))->find;
    while (my $doc = $cursor->next) {
        delete $doc->{_id};
        $config->{$_} = $doc->{$_}
            foreach keys %$doc;
    }
    $mongo->dot_patch($config);
    return $config;
}

1;
__END__
