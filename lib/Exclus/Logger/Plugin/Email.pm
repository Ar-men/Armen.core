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
use Exclus::Util qw(dump_data template);
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
    my $severity = $level eq 'err' ? 'error' : $level eq 'crit' ? 'critical' : $level;
###::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::###
    Exclus::Email
        ->new(config => $self->config, subject => ucfirst($severity))
        ->send(
            $severity,
            sprintf('%s[%s]', $logger->runner_name, $logger->runner_data),
            template(
                'armen.core',
                'Exclus.Logger.Plugin.Email',
                {
                    message    => $message,
                    attributes => [pairmap {"$a=" . dump_data($b)} @$attributes],
                    extra      => $logger->extra_cb ? $logger->extra_cb->() : undef
                }
            )
        );
###::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::###
}

1;
__END__
