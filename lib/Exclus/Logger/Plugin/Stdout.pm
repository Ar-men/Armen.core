#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Logger::Plugin::Stdout;

#md_# Exclus::Logger::Plugin::Stdout
#md_

use Exclus::Exclus;
use JSON::MaybeXS qw(encode_json);
use Moo;
use namespace::clean;

extends qw(Exclus::Logger::Plugin);

#md_## Les attributs
#md_

#md_### level
#md_
has '+level' => (
    lazy => 1, default => sub { $_[0]->config->get_bool('debug') ? 'debug' : 'info' }
);

#md_## Les méthodes
#md_

#md_### log()
#md_
sub log {
    my ($self, $logger, $level, $message, $attributes) = @_;
    say STDOUT encode_json({
        _level       => $level,
        _message     => $message,
        _runner_name => $logger->runner_name,
        _runner_data => $logger->runner_data,
        $attributes ? @$attributes : ()
    });
}

1;
__END__
