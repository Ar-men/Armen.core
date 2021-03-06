#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Resources::Plugin::MongoDB;

#md_# Obscur::Resources::Plugin::MongoDB
#md_

use Exclus::Exclus;
use Moo;
use Exclus::Crypt qw(decrypt);
use Exclus::Databases::MongoDB;
use namespace::clean;

extends qw(Obscur::Resources::Plugin);

#md_## Les méthodes
#md_

#md_### _set_auth()
#md_
sub _set_auth {
    my ($self, $options) = @_;
    my $auth = $self->cfg->create({default => {}}, 'auth');
    my $db_name = $auth->maybe_get_str('db_name');
    $options->{db_name} = $db_name
        if defined $db_name;
    my $username = $auth->maybe_get_str('username');
    $options->{username} = $username
        if defined $username;
    my $password = $auth->maybe_get_str('password');
    $options->{password} = decrypt($password)
        if defined $password;
    return $options
}

#md_### build_resource()
#md_
sub build_resource {
    my ($self, $runner, $name) = @_;
    my $cfg = $self->cfg;
    return Exclus::Databases::MongoDB->new(
        host    =>      'mongodb://' . join(',', @{$cfg->get_arrayref('servers')}),
        options => $self->_set_auth($cfg->get_hashref({default => {}}, 'options'))
    )
}

1;
__END__
