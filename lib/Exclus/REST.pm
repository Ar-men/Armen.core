#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::REST;

#md_# Exclus::REST
#md_

use Exclus::Exclus;
use HTTP::Tiny;
use JSON::MaybeXS qw(decode_json encode_json);
use Moo;
use Types::Standard -types;
use Exclus::Exceptions;
use namespace::clean;

#md_## Les attributs
#md_

#md_### _client
#md_
has '_client' => (
    is => 'ro', isa => InstanceOf['HTTP::Tiny'], required => 1
);

#md_### _options
#md_
has '_options' => (
    is => 'ro',
    isa => HashRef,
    default => sub { {headers => {'Accept-Charset' => 'UTF-8', 'Accept' => 'application/json'}} },
    init_arg => undef
);

#md_## Les méthodes
#md_

#md_### BUILDARGS()
#md_
around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    return $class->$orig(
        _client => HTTP::Tiny->new(
            agent       => 'armen/armen.core/Exclus',
            http_proxy  => undef,
            https_proxy => undef,
            proxy       => undef,
            timeout     => 5,
            %args
        )
    );
};

#md_### add_header()
#md_
sub add_header {
    my ($self, $name, $value) = @_;
    $self->_options->{headers}->{$name} = $value;
}

#md_### send_json()
#md_
sub send_json {
    my ($self, $content) = @_;
    my $options = $self->_options;
    $options->{content} = encode_json($content);
    my $headers = $options->{headers};
    $headers->{'Content-Length'} = length($options->{content});
    $headers->{'Content-Type'  } = 'application/json; charset=UTF-8';
}

#md_### request()
#md_
sub request {
    my $self = shift;
    my $response = $self->_client->request(@_, $self->_options);
    return $response->{success}, $response;
}

#md_### get_content()
#md_
sub get_content {
    my ($self, $response) = @_;
    my $content;
    my $headers = $response->{headers};
    if (exists $headers->{'content-type'}) {
        my $content_type = $headers->{'content-type'};
        if ($content_type =~ m!json!) {
            $content = decode_json($response->{content});
        }
        elsif ($content_type =~ m!xml!) {
            EX->TODO;
        }
        elsif ($content_type =~ m!text!) {
            $content = $response->{content};
        }
        else {
            EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////
                message => "Le type du contenu de la réponse n'est pas valide",
                params  => [content_type => $content_type]
            });
        }
    }
    return $content;
}

#md_### delete(), get(), post(), put()
#md_
sub delete { shift->request('DELETE', @_) }
sub get    { shift->request('GET',    @_) }
sub post   { shift->request('POST',   @_) }
sub put    { shift->request('PUT',    @_) }

1;
__END__
