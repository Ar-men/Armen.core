#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Blocus::Service;

#md_# Blocus::Service
#md_

use Exclus::Exclus;
use AnyEvent::HTTP;
use JSON::MaybeXS qw(decode_json encode_json);
use Moo;
use Plack::Response;
use Exclus::Environment;
use Exclus::Exceptions;
use namespace::clean;

extends qw(Obscur::Runner::Service);

AnyEvent::HTTP::set_proxy(undef);
$AnyEvent::HTTP::USERAGENT = 'armen/armen.core/Blocus';

#md_## Les attributs
#md_

###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###
has '+name'        => (default => sub { 'Blocus' });
has '+description' => (default => sub { "Le µs 'gatekeeper'" });
###----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----###

#md_## Les méthodes
#md_

#md_### _api_gatekeeper()
#md_
sub _api_gatekeeper {
    my ($self, $respond, $rr, $p) = @_;
    my $service  = $p->get_str('service');
    my $version  = $p->get_int('version');
    my $asterisk = $p->get_str(      '*');
    my $body = encode_json($p->data);
    my ($node, $port) = $self->discovery->get_endpoint(ucfirst(lc($service)));
    unless ($node && $port) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "Ce µs n'a aucune instance disponible",
            params  => [µs => $service]
        });
    }
    my $api_key = env()->{api_key};
    my $rr_id = $rr->id;
    http_request(
        $rr->request->method,
        "http://$node:$port/armen/api/$api_key/v$version/$asterisk?\@id=$rr_id",
        body    => $rr->request->content,
        headers => {@{$rr->request->headers->psgi_flatten_without_sort}},
        timeout => 60,
        sub {
            my ($body, $headers) = @_;
            if (defined $body) {
                $respond->(Plack::Response->new($headers->{Status}, $headers, $body)->finalize);
            }
            else {
                $respond->($rr->status($headers->{Status})->error($headers->{Reason})->render->finalize);
            }
        }
    );
}

#md_### build_API()
#md_
sub build_API {
    my ($self) = @_;
    $self->server->any('/s.:service/v:version/*', sub { $self->_api_gatekeeper(@_) });
}

1;
__END__
