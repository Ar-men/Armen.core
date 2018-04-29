#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Cursus::Cmd::Plugin;

#md_# Cursus::Cmd::Plugin
#md_

use Exclus::Exclus;
use Moo;
use Term::Table;
use namespace::clean;

extends qw(Obscur::Context);

#md_## Les méthodes
#md_

#md_### render_table()
#md_
sub render_table {
    my ($self, $rows) = (shift, shift);
    return unless @$rows;
    say foreach Term::Table->new(max_width => 150, header => [@_], rows => $rows)->render;
}

#md_### run()
#md_
sub run {...}

1;
__END__
