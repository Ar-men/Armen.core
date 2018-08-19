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
use Try::Tiny;
use Exclus::Util qw(dump_data);
use namespace::clean;

extends qw(Cursus::Cmd::Plugin);

#md_## Les méthodes
#md_

#md_### run()
#md_
sub run {
    my ($self, $services, @args) = @_;
    my $runner = $self->runner;
    my @services = $runner->discovery->get_services;
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
        my $client = $runner->client;
        foreach my $value (@to_call) {
            foreach (@services) {
                my $service_name = $_->{name};
                if (($value eq $_->{id} || ucfirst(lc($value)) eq $service_name) && $_->{status} eq 'running') {
                    say "---> ${service_name}[$_->{id}]";
                    try   {
                        say dump_data(
                            $client->request_endpoint($_->{node}, $_->{port}, 'POST', 'execute', @args)
                        );
                    }
                    catch {
                        say "$_";
                    };
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
