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
use Exclus::Environment;
use Exclus::Util qw(generate_string);

our @EXPORT_OK = qw(decrypt encrypt);

#md_## Les méthodes
#md_

#md_### encrypt()
#md_
sub encrypt {
    my $string = shift;
    my $iv = generate_string('.{16}');
    return encode_b64($iv . Crypt::Mode::CBC->new('AES')->encrypt($string, env()->{crypt_key}, $iv));
}

#md_### decrypt()
#md_
sub decrypt {
    my $sb64 = shift;
    return $sb64 unless (my $s = decode_b64($sb64));
    my $iv = substr($s, 0, 16);
    return Crypt::Mode::CBC->new('AES')->decrypt(substr($s, 16), env()->{crypt_key}, $iv);
}

1;
__END__
