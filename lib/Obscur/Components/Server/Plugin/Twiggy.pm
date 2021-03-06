#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Components::Server::Plugin::Twiggy;

#md_# Obscur::Components::Server::Plugin::Twiggy
#md_

use Exclus::Exclus;
use Moo;
use Plack::Builder;
use Router::Boom::Method;
use Try::Tiny;
use Twiggy::Server;
use Types::Standard -types;
use Exclus::Util qw($_call_if_can);
use namespace::clean;

extends qw(Obscur::Object);

#md_## Les attributs
#md_

#md_### _router
#md_
has '_router' => (
    is => 'ro',
    isa => InstanceOf['Router::Boom::Method'],
    lazy => 1,
    default => sub { Router::Boom::Method->new },
    init_arg => undef
);

#md_## Les méthodes
#md_

#md_### BUILD()
#md_
sub BUILD {
    my ($self) = @_;
    my $builder      = Plack::Builder->new;
    my $builder_api  = Plack::Builder->new;
    $builder_api->add_middleware('Plack::Middleware::ContentLength');
    $builder_api->add_middleware('Plack::Middleware::XForwardedFor');
    $builder->mount('/armen/api' => $builder_api->wrap(sub { $self->_psgi_api(@_) }));
    $self->$_call_if_can(build => $builder);
    my $runner = $self->runner;
    $runner->$_call_if_can(build_psgi => $builder);
    Twiggy::Server->new(host => '0.0.0.0', port => $runner->port)->register_service($builder->to_app);
}

#md_### route_match()
#md_
sub route_match {return shift->_router->match($_[0]->{REQUEST_METHOD}, $_[0]->{PATH_INFO}) }

#md_### _delayed_response()
#md_
sub _delayed_response {
    my ($self, $rr, $cb, $params) = @_;
    return sub {
        my ($respond) = @_;
        try {
            $cb->($respond, $rr, $rr->get_parameters($params));
        }
        catch {
            $self->logger->error("$_");
            $rr->render_500("$_");
            $respond->($rr->finalize);
        };
    };
}

#md_### _psgi_api()
#md_
sub _psgi_api {
    my ($self, $env) = @_;
    my $runner = $self->runner;
    my $rr = _OCSPT::RequestResponse->new(runner => $runner, env => $env, debug => $self->debug);
    my $later;
    try {
        my ($cb, $params, $is_method_not_allowed, $allowed_methods) = $self->route_match($env);
        if ($cb) {
            $later = $self->_delayed_response($rr, $cb, $params);
        }
        elsif ($is_method_not_allowed || $allowed_methods) {
            $rr->render_405;
        }
        else {
            $rr->render_404;
        }
    }
    catch {
        my $error = "$_";
        $self->logger->error($error);
        $rr->render_500(     $error);
    };
    return $later ? $later : $rr->finalize;
}

#md_### delete(), get(), post(), put()
#md_
sub delete { shift->_router->add('DELETE', @_) }
sub get    { shift->_router->add('GET',    @_) }
sub post   { shift->_router->add('POST',   @_) }
sub put    { shift->_router->add('PUT',    @_) }

#md_### any()
#md_
sub any { shift->_router->add([qw(DELETE GET POST PUT)], @_) }

package _OCSPT::RequestResponse; #######################################################################################

#md_# _OCSPT::RequestResponse
#md_

use Exclus::Exclus;
use JSON::MaybeXS qw(decode_json encode_json);
use Moo;
use Plack::Request;
use Plack::Response;
use Types::Standard -types;
use XML::Hash::XS qw(hash2xml xml2hash);
use Exclus::Data;
use Exclus::Exceptions;
use Exclus::Util qw(create_uuid);
use namespace::clean;

extends qw(Obscur::Context);

#md_## Les attributs
#md_

#md_### id
#md_
has 'id' => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub { $_[0]->request->query_parameters->{'@id'} || create_uuid },
    init_arg => undef
);

#md_### env
#md_
has 'env' => (
    is => 'ro', isa => HashRef, required => 1
);

#md_### request
#md_
has 'request' => (
    is => 'ro',
    isa => InstanceOf['Plack::Request'],
    lazy => 1,
    default => sub { Plack::Request->new($_[0]->env) },
    init_arg => undef
);

#md_### _response
#md_
has '_response' => (
    is => 'ro',
    isa => InstanceOf['Plack::Response'],
    lazy => 1,
    default => sub {
        Plack::Response->new(200, {'Content-Type' => 'application/json; charset=UTF-8'})
    },
    init_arg => undef
);

#md_### _content
#md_
has '_content' => (
    is => 'rw',
    isa => HashRef,
    lazy => 1,
    default => sub { {'@id' => $_[0]->id, status => 200, success => 'yes'} },
    init_arg => undef
);

#md_### _debug
#md_
has '_debug' => (
    is => 'ro', isa => Bool, required => 1, init_arg => 'debug'
);

#md_## Les méthodes
#md_

#md_### BUILD()
#md_
sub BUILD {
    my $self = shift;
    if ($self->_debug) {
        $self->logger->debug(
            'Request',
            ['@id' => $self->id, server => $self->env->{REMOTE_ADDR}, resource => $self->env->{PATH_INFO}]
        );
    }
}

#md_### get_parameters()
#md_
sub get_parameters {
    my ($self, $params) = @_;
    my $content = {};
    my $content_type = $self->request->content_type;
    if ($content_type) {
        if ($content_type =~ m!json!) {
            $content = decode_json($self->request->content);
        }
        elsif ($content_type =~ m!xml!) {
            $self->_response->content_type('text/xml; charset=UTF-8');
            $content = xml2hash($self->request->content);
        }
        else {
            EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////
                message => 'Le contenu de la requête est de type inconnu',
                params  => [content_type => $content_type]
            });
        }
    }
    my $query_params = $self->request->query_parameters->as_hashref_mixed;
    $params = Exclus::Data->new(data => {%$content, %{$query_params || {}}, %{$params || {}}});

    $self->logger->debug('Parameters', ['@id' => $self->id, %{$params->data}])
        if $self->_debug;

    return $params;
}

#md_### set_key_value()
#md_
sub set_key_value {
    my ($self, $key, $value) = @_;
    $self->_content->{$key} = $value;
    return $self;
}

#md_### error()
#md_
sub error { return shift->set_key_value('error', @_)->set_key_value('success', 'no') }

#md_### status()
#md_
sub status { return shift->set_key_value('status', @_) }

#md_### payload()
#md_
sub payload { return shift->set_key_value('payload', @_) }

#md_### render()
#md_
sub render {
    my ($self) = @_;
    my $response = $self->_response;
    my $content = $self->_content;
    $response->status(delete $content->{status});
    if ($response->content_type =~ m!json!) {
        $response->body(encode_json($content));
    }
    elsif ($response->content_type =~ m!xml!) {
        $response->body(hash2xml($content));
    }
    else {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => 'Le contenu de la réponse est de type inconnu',
            params  => [content_type => $response->content_type]
        });
    }
    $self->logger->debug('Response', ['@id' => $self->id, status => $response->status, content => $content])
        if $self->_debug;
    return $self;
}

#md_### render_404()
#md_
sub render_404 { $_[0]->error('Ressource non trouvée')->status(404)->render }

#md_### render_405()
#md_
sub render_405 { $_[0]->error('Méthode de requête non autorisée')->status(405)->render }

#md_### render_500()
#md_
sub render_500 { shift->error(@_)->status(500)->render }

#md_### finalize()
#md_
sub finalize {
    return $_[0]->_response->finalize;
}

1;
__END__
