#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Exclus;

#md_# Exclus::Exclus
#md_
#md_Ce module doit être le premier de la liste des modules chargés par un module.
#md_
#md_    use Exclus::Exclus;
#md_    use ...
#md_
#md_est équivalent à:
#md_
#md_    use strict;
#md_    use warnings;
#md_    use utf8;
#md_    use feature qw(:5.10);
#md_    use ...
#md_

use strict;
use warnings;
use utf8;
use feature ();

#md_## Les méthodes
#md_

#md_### import()
#md_
#md_Cette méthode est automatiquement appelée lorsque ce module est chargé.
#md_
sub import {
    $_->import foreach qw(strict warnings utf8);
    feature->import(':5.10');
}

1;
__END__
