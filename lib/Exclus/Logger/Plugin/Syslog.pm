#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Logger::Plugin::Syslog;

#md_# Exclus::Logger::Plugin::Syslog
#md_

use Exclus::Exclus;
use List::Util qw(pairmap);
use Moo;
use Sys::Syslog ();
use Types::Standard qw(Str);
use Exclus::Util qw(clean_string dump_data);
use namespace::clean;

extends qw(Exclus::Logger::Plugin);

#md_## Les attributs
#md_

#md_### level
#md_
has '+level' => (
    lazy => 1, default => sub { $_[0]->config->get_bool('debug') ? 'debug' : 'info' }
);

#md_### facility
#md_
has 'facility' => (
    is => 'ro', isa => Str, default => sub { 'local0' }
);

#md_## Les méthodes
#md_

#md_### BUILD()
#md_
sub BUILD { Sys::Syslog::openlog('armen', '', $_[0]->facility) }

#md_### DEMOLISH()
#md_
sub DEMOLISH { Sys::Syslog::closelog }

#md_### log()
#md_
sub log {
    my ($self, $logger, $level, $message, $attributes) = @_;
    my $string = $attributes
        ? "$message> " . join q{, }, pairmap {"$a: " . dump_data($b)} @$attributes
        : $message;
    Sys::Syslog::syslog(
        $level,
        sprintf('%s.%s %s', $logger->runner_name, $logger->runner_data, clean_string($string))
    );
}

1;
__END__
