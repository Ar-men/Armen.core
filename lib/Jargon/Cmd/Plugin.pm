#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Jargon::Cmd::Plugin;

#md_# Jargon::Cmd::Plugin
#md_

use Exclus::Exclus;
use Moo;
use Exclus::Util qw(format_table);
use namespace::clean;

extends qw(Obscur::Context);

#md_## Les méthodes
#md_

#md_### clear_terminal()
#md_
sub clear_terminal {
    print "\e[2J";
    print "\e[0;0H";
}

#md_### clear_to_end()
#md_
sub clear_to_end { print "\e[J" }

#md_### store_position()
#md_
sub store_position { print "\e7"  }

#md_### restore_position()
#md_
sub restore_position { print "\e8"  }

#md_### display_table()
#md_
sub display_table {
    shift;
    say foreach format_table(@_);
}

#md_### run()
#md_
sub run {...}

1;
__END__
