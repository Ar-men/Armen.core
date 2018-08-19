#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Util::Advanced;

#md_# Exclus::Util::Advanced
#md_

use Exclus::Exclus;
use Exporter qw(import);
use Getopt::Long ();
use Exclus::Data;
use Exclus::Exceptions;

our @EXPORT_OK = qw(
    get_cmd_options
);

#md_## Les méthodes
#md_

#md_### get_cmd_options()
#md_
sub get_cmd_options {
    my ($cmd, $args, $options, $default, $required) = @_;
    local $SIG;
    $SIG{__WARN__} = sub {
        EX->throw($_[0]); ##////////////////////////////////////////////////////////////////////////////////////////////
    };
    my $data = $default ? {%$default} : {};
    my $parser = Getopt::Long::Parser->new;
    $parser->configure(qw(no_getopt_compat));
    $parser->getoptionsfromarray($args, map {m!^(\w+)!; $_ => \$data->{$1}} @$options);
    foreach (@$required) {
        unless (defined $data->{$_}) {
            EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////
                message => 'Cette option est requise pour cette commande',
                params  => [cmd => $cmd, option => $_]
            });
        }
    }
    return Exclus::Data->new(data => $data);
}

1;
__END__
