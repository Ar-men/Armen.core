#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Databases::MongoDB;

#md_# Exclus::Databases::MongoDB
#md_

use Exclus::Exclus;
use MongoDB;
use Moo;
use Ref::Util qw(is_hashref);
use Types::Standard qw(HashRef InstanceOf Maybe Str);
use Exclus::Crypt qw(decrypt);
use namespace::clean;

#md_## Les attributs
#md_

#md_### uri
#md_
has 'uri' => (
    is => 'ro', isa => Maybe[Str], default => sub { undef }
);

#md_### host
#md_
has 'host' => (
    is => 'ro', isa => Str, default => sub { 'mongodb://localhost:27017' }
);

#md_### options
#md_
has 'options' => (
    is => 'ro', isa => HashRef, default => sub { {} }
);

#md_### _client
#md_
has '_client' => (
    is => 'lazy', isa => InstanceOf['MongoDB::MongoClient'], init_arg => undef
);

#md_## Les méthodes
#md_

#md_### _build__client()
#md_
sub _build__client {
    my $self = shift;
    my $codec = MongoDB::BSON->new(dt_type => 'Time::Moment');
    return MongoDB::MongoClient->new(host => decrypt($self->uri), app_name => 'armen', bson_codec => $codec)
        if $self->uri;
    return MongoDB::MongoClient->new(
        host       => $self->host,
        bson_codec => $codec,
        app_name   => 'armen',
        %{$self->options}
    );
}

#md_### get_database()
#md_
sub get_database {
    return shift->_client->db(@_);
}

#md_### get_collection()
#md_
sub get_collection {
    my ($self, $db, $coll, $prefer_numeric) = @_;
    return $self->_client->ns("$db.$coll")->with_codec(prefer_numeric => $prefer_numeric // 1);
}

#md_### dot_patch()
#md_
sub dot_patch {
    my ($self, $data) = @_;
    foreach my $k (keys %$data) {
        my $v = $data->{$k};
        $self->dot_patch($v)
            if is_hashref($v);
        if ($k =~ m!\~!) {
            my $key = $k;
            $key =~ s!\~!\.!g;
            $data->{$key} = delete $data->{$k};
        }
    }
}

1;
__END__
