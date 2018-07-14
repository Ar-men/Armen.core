#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Data;

#md_# Exclus::Data
#md_

use Exclus::Exclus;
use List::Util qw(shuffle);
use Moo;
use Ref::Util qw(is_coderef is_hashref);
use Types::Standard qw(ArrayRef Bool HashRef Int Maybe Num Str);
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
sub count_keys { scalar keys %{$_[0]->data} }

#md_### exists()
#md_
sub exists {
    my $self = shift;
    return deep_exists($self->data, @_);
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

#md_### foreach_key()
#md_
sub foreach_key {
    my $self = shift;
    my $opts = is_hashref($_[0]) ? shift : {};
    $opts->{create} //= 0;
    my $cb = shift;
    my $data = $self->data;
    my @keys = keys %$data;
    $cb->($_, $opts->{create} ? $self->new(data => $data->{$_}) : $data->{$_}, @_)
        foreach
            exists $opts->{sort}
                ? $opts->{sort}
                    ? is_coderef($opts->{sort})
                        ? sort {$opts->{sort}->($data->{$a}, $data->{$b})} values @keys
                        : sort @keys
                    : shuffle @keys
                : @keys;
}

#md_### [maybe_]get_(arrayref|bool|hashref|int|num|str)()
#md_
foreach my $type (ArrayRef, Bool, HashRef, Int, Num, Str) {
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
            undef($opts->{default});
            return $self->get($opts, @_);
        }
    );
}

#md_### maybe_get_any()
#md_
sub maybe_get_any { shift->get({type => Maybe[ArrayRef|Bool|HashRef|Int|Num|Str], default => undef}, @_) }

#md_## Les méthodes de la classe
#md_

#md_### find()
#md_
sub find {
    my ($class, $data) = (shift, shift);
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

1;
__END__
