#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Environment;

#md_# Exclus::Environment
#md_

use Exclus::Exclus;
use Exporter qw(import);

our @EXPORT = qw(env);
our @EXPORT_OK = qw(add_environment);

my $_g_environment = {};
add_environment({crypt_key => '@1/]IfA>~Q:dO[armen]{#{6I\(Z,7n@'});

#md_## Les méthodes
#md_

#md_### env()
#md_
sub env { $_g_environment }

#md_### add_environment()
#md_
sub add_environment {
    my ($vars) = @_;
    foreach (keys %$vars) {
        my $key = '_ARMEN_' . uc($_);
        $_g_environment->{$_} = exists $ENV{$key} ? $ENV{$key} : $vars->{$_};
    }
}

1;
__END__
