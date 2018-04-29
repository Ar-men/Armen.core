#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Crypt;

#md_# Exclus::Crypt
#md_

use Exclus::Exclus;
use Crypt::Misc qw(decode_b64 encode_b64);
use Crypt::Mode::CBC;
use Exporter qw(import);
use Safe::Isa qw($_isa);
use String::Random;
use Try::Tiny;
use Exclus::Environment;
use Exclus::Exceptions qw(Unencrypted);

our @EXPORT_OK = qw(decrypt encrypt try_decrypt);

#md_## Les méthodes
#md_

#md_### encrypt()
#md_
sub encrypt {
    my $string = shift;
    my $iv = String::Random->new->randregex('.{16}');
    return encode_b64("armen$iv" . Crypt::Mode::CBC->new('AES')->encrypt($string, env()->{crypt_key}, $iv));
}

#md_### decrypt()
#md_
sub decrypt {
    my $sb64 = shift;
    if ($sb64 !~ m!^YXJtZW4!) {
        EX::Unencrypted->throw({ ##/////////////////////////////////////////////////////////////////////////////////////
            message => "Cette valeur n'est pas [armen] cryptée",
            params => [value => $sb64]
        });
    }
    my $s  = decode_b64($sb64);
    my $iv = substr($s, 5, 16);
    return Crypt::Mode::CBC->new('AES')->decrypt(substr($s, 21), env()->{crypt_key}, $iv);
}

#md_### try_decrypt()
#md_
sub try_decrypt {
    my $value = shift;
    my $string;
    try {
        $string = decrypt($value);
    }
    catch {
        die $_ unless $_->$_isa('EX::Unencrypted');
        $string = $value;
    };
    return $string;
}

1;
__END__
