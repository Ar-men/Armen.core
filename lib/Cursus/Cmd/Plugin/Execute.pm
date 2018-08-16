#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Cursus::Cmd::Plugin::Execute;

#md_# Cursus::Cmd::Plugin::Execute
#md_

use Exclus::Exclus;
use Moo;
use Exclus::Environment;
use Exclus::REST;
use namespace::clean;

extends qw(Cursus::Cmd::Plugin);

#md_## Les méthodes
#md_

#md_### _call()
#md_
sub _call {
    my ($self, $node, $port, @args) = @_;
    #TODO ilf faut utiliser le composant 'client' pour dialoguer avec le composant 'server'
    my $api_key = env()->{api_key};
    my $client = Exclus::REST->new(timeout => 1);
    $client->send_json({args => \@args});
    my ($success, $response) = $client->request('POST', "http://$node:$port/armen/api/$api_key/v0/execute");
}

#md_### run()
#md_
sub run {
    my ($self, $services, @args) = @_;
    my @services = $self->runner->discovery->get_services;
    if (@services) {
        my @to_call;
        if ($services) {
            push @to_call, $services;
        }
        else {
            push @to_call, $_->{id} foreach @services;
        }
        push @args, 'help' unless @args;
        say 'Appel des µs:';
        foreach my $value (@to_call) {
            foreach (@services) {
                my $service_name = $_->{name};
                if (($value eq $_->{id} || ucfirst(lc($value)) eq $service_name) && $_->{status} eq 'running') {
                    say "---> ${service_name}[$_->{id}]";
                    $self->_call($_->{node}, $_->{port}, @args);
                }
            }
        }
    }
    else {
        say "Aucun µs n'est enregistré.";
    }
}

1;
__END__

=encoding utf8

=head1 Commande:

    armen execute [µs.(id|name) [cmd [args ...]]]

=head1 Description:

    Exécution d'une commande par les µs spécifiés par leur nom ou leur identifiant

=cut
