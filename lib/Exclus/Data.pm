#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Écosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Data;

#md_# Exclus::Data
#md_

use Exclus::Exclus;
use Moo;
use Ref::Util qw(is_hashref);
use Types::Standard qw(ArrayRef Bool HashRef Int Maybe Str);
use Exclus::Exceptions;
use Exclus::Util qw(deep_exists monkey_patch);
use namespace::clean;

#md_## Les attributs
#md_

#md_### data
#md_
has 'data' => (
    is => 'ro', isa => HashRef, default => sub { {} }
);

#md_## Les méthodes
#md_

#md_### count_keys()
#md_
sub count_keys { return scalar keys %{$_[0]->data} }

#md_### exists()
#md_
sub exists {
    my $self = shift;
    return deep_exists($self->data, @_);
}

#md_### find()
#md_
sub find {
    my (undef, $data) = (shift, shift);
    my $opts = is_hashref($_[0]) ? shift : {};
    my @keys = @_;
    foreach (@keys) {
        unless (is_hashref($data) && exists $data->{$_}) {
            if (exists $opts->{default}) {
                $data = $opts->{default};
                last;
            }
            EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////
                message => "La donnée est introuvable",
                params  => [keys => join('|', @keys)]
            });
        }
        $data = $data->{$_};
    }
    if (exists $opts->{type} && !$opts->{type}->check($data)) {
        EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////////////
            message => "La donnée trouvée n'est pas du bon type",
            params  => [type => "$opts->{type}", keys => join('|', @keys)]
        });
    }
    return $data;
}

#md_### get()
#md_
sub get { return __PACKAGE__->find(shift->data, @_) }

#md_### create()
#md_
sub create {
    my $self = shift;
    my $opts = is_hashref($_[0]) ? shift : {};
    $opts->{type} = exists $opts->{default}
        ? defined $opts->{default} ? HashRef : Maybe[HashRef]
        : HashRef;
    my $data = $self->get($opts, @_);
    return $data ? $self->new(data => $data) : undef;
}

#md_### get_(?:arrayref|bool|hashref|int|str)()
#md_
foreach my $type (ArrayRef, Bool, HashRef, Int, Str) {
    monkey_patch(
        __PACKAGE__,
        'get_' . lc($type),
        sub {
            my $self = shift;
            my $opts = is_hashref($_[0]) ? shift : {};
            $opts->{type} = $type;
            return $self->get($opts, @_);
        }
    );
    monkey_patch(
        __PACKAGE__,
        'maybe_get_' . lc($type),
        sub {
            my $self = shift;
            my $opts = is_hashref($_[0]) ? shift : {};
            $opts->{type} = Maybe[$type];
            $opts->{default} = undef;
            return $self->get($opts, @_);
        }
    );
}

1;
__END__
