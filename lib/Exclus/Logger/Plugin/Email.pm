#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Logger::Plugin::Email;

#md_# Exclus::Logger::Plugin::Email
#md_

use Exclus::Exclus;
use List::Util qw(pairmap);
use Moo;
use Exclus::Email;
use Exclus::Util qw(dump_data);
use namespace::clean;

extends qw(Exclus::Logger::Plugin);

#md_## Les attributs
#md_

#md_### level
#md_
has '+level' => (
    lazy => 1, default => sub { 'warning' }
);

#md_## Les méthodes
#md_

#md_### log()
#md_
sub log {
    my ($self, $logger, $level, $message, $attributes) = @_;
###::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::###
    my $content = "<p>$message</p>";
    if ($attributes) {
        $content .= '<ul>';
        $content .= "<li>$_</li>" foreach pairmap {"$a=" . dump_data($b)} @$attributes;
        $content .= '</ul>';
    }
###::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::###
    $content .= $logger->extra_cb->() if $logger->extra_cb;
    Exclus::Email
        ->new(config => $self->config, subject => ucfirst($level))
        ->try_to_send($level, $content, sprintf('%s[%s]', $logger->runner_name, $logger->runner_data));
}

1;
__END__
