#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Config::Parser;

#md_# Exclus::Config::Parser
#md_

use Exclus::Exclus;
use Exporter qw(import);
use JSON::MaybeXS qw(decode_json);
use Ref::Util qw(is_arrayref is_hashref is_ref);
use Scalar::Util qw(looks_like_number);
use Try::Tiny;
use Exclus::Exceptions;
use Exclus::Util qw(key_value);

our @EXPORT_OK = qw(parse);

#md_## Les méthodes
#md_

#md_### _decode_json
#md_
sub _decode_json {
    my $json = shift;
    return try {
        return decode_json($json);
    }
    catch {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Ces données ne sont pas au format JSON",
            params  => [data => $json]
        });
    };
}

#md_### parse()
#md_
sub parse {
    my ($config, $cb) = @_;
    if (is_hashref($config)) {
        my $use = key_value($config, 'use');
        my $cfg = key_value($config, 'cfg', {});
        if (!defined $use || is_ref($use) || looks_like_number($use) || !is_hashref($cfg)) {
            EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////
                message => "Cet élément de configuration n'est pas valide",
                params  => [config => $_[0]]
            });
        }
        $cb->($use, $cfg);
    }
    elsif (is_arrayref($config)) {
        parse($_, $cb)
            foreach @$config;
    }
    else {
        parse(_decode_json($config), $cb);
    }
}

1;
__END__
