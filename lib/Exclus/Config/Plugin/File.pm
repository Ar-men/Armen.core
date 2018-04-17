#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Écosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Config::Plugin::File;

#md_# Exclus::Config::Plugin::File
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard qw(Str);
use YAML::XS qw(LoadFile);
use namespace::clean;

extends qw(Exclus::Config::Plugin);

#md_## Les attributs
#md_

#md_### file_name
#md_
has 'file_name' => (
    is => 'ro', isa => Str, required => 1
);

#md_## Les méthodes
#md_

#md_### load()
#md_
sub load { return LoadFile($_[0]->file_name) }

1;
__END__
