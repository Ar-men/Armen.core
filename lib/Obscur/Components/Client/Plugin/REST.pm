#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Components::Client::Plugin::REST;

#md_# Obscur::Components::Client::Plugin::REST
#md_

use Exclus::Exclus;
use Moo;
use Exclus::Environment;
use Exclus::Exceptions qw(Client::NoEndpoint);
use Exclus::REST;
use namespace::clean;

extends qw(Obscur::Object);

#md_## Les méthodes
#md_

#md_### request_endpoint()
#md_
sub request_endpoint{
    my ($self, $node, $port, $method, $query, @args) = @_;
    my $api_key = env()->{api_key};
    my $client = Exclus::REST->new(timeout => 5);
    $client->send_json({args => \@args});
    my ($success, $response) = $client->request($method, "http://$node:$port/armen/api/$api_key/v0/$query");
    my $content = $client->get_content($response);
    return $content->{payload}
        if $success;
    EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////////
        message => "L'appel du µs a échoué",
        params  => [defined $content ? %$content : %$response]
    });
}

#md_### request()
#md_
sub request {
    my ($self, $method, $service, $query, @args) = @_;
    my ($node, $port) = $self->runner->discovery->get_endpoint($service);
    unless ($node && $port) {
        EX::Client::NoEndpoint->throw({ ##//////////////////////////////////////////////////////////////////////////////
            message => "Ce µs n'a aucune instance disponible",
            params  => [µs => $service]
        });
    }
    $self->request_endpoint($node, $port, $method, $query, @args);
}

#md_### delete(), get(), post(), put()
#md_
sub delete { return shift->request('DELETE', @_) }
sub get    { return shift->request('GET',    @_) }
sub post   { return shift->request('POST',   @_) }
sub put    { return shift->request('PUT',    @_) }

1;
__END__
