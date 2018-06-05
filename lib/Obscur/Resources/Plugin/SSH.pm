#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Obscur::Resources::Plugin::SSH;

#md_# Obscur::Resources::Plugin::SSH
#md_

use Exclus::Exclus;
use Moo;
use Types::Standard qw(ArrayRef Str);
use Exclus::Exceptions;
use Exclus::SSH::Cluster;
use Exclus::SSH::Node;
use namespace::clean;

extends qw(Obscur::Resources::Plugin);

#md_## Les méthodes
#md_

#md_### build_resource()
#md_
sub build_resource {
    my ($self, $runner, $name) = @_;
    $name //= 'no_name';
    my $cfg = $self->cfg;
    if ($cfg->exists('cluster')) {
        my $nodes = {};
        foreach (@{$cfg->get({type => ArrayRef[Str]}, 'cluster')}) {
            if ($_ eq $name) {
                EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////
                    message => "Ce cluster SSH ne peut dépendre de lui-même",
                    params  => [cluster => $name]
                });
            }
            my $resource = $runner->get_resource('SSH', $_);
##          if ($resource->is_cluster) {
##              EX->throw({ ##//////////////////////////////////////////////////////////////////////////////////////////
##                  message => "Ce cluster SSH ne peut utiliser un autre cluster",
##                  params  => [cluster => $name]
##              });
##          }
            $nodes->{$_} = $resource;
        }
        return Exclus::SSH::Cluster->new(name => $name, nodes => $nodes);
    }
    else {
        return Exclus::SSH::Node->new(name => $name, %{$cfg->data});
    }
}

1;
__END__
