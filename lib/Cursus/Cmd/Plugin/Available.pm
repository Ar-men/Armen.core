#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Cursus::Cmd::Plugin::Available;

#md_# Cursus::Cmd::Plugin::Available
#md_

use Exclus::Exclus;
use Moo;
use namespace::clean;

extends qw(Cursus::Cmd::Plugin);

#md_## Les méthodes
#md_

#md_### _disabled()
#md_
sub _disabled {
    my ($self, $service, $row) = @_;
    push @$row, $service->get_bool({default => 0}, 'disabled') ? 'true' : 'false';
}

#md_### _port()
#md_
sub _port {
    my ($self, $service, $row) = @_;
    my $port = $service->maybe_get_int('port');
    push @$row, $port ? $port : '#';
}

#md_### _deploy()
#md_
sub _deploy {
    my ($self, $service, $row) = @_;
    my $deploy = $service->create({default => {}}, 'deploy');
    my @deploy;
    foreach (qw(overall dc node)) {
        my $value = $deploy->maybe_get_int($_);
        push @deploy, sprintf("%s: %s", $_, defined $value ? $value : '#');
    }
    push @$row, join(', ', @deploy);
}

#md_### run()
#md_
sub run {
    my ($self) = @_;
    my $services = $self->config->create({default => {}}, 'services');
    if ($services->count_keys) {
        my $rows = [];
        $services->foreach_key(
            {create => 1, sort => 1},
            sub {
                my ($name, $service) = @_;
                my $row = [$name];
                $self->_disabled($service, $row);
                $self->_port(    $service, $row);
                $self->_deploy(  $service, $row);
                push @$rows, $row;
            }
        );
        $self->render_table($rows, qw(NAME DISABLED PORT DEPLOY));
    }
    else {
        say "Aucun µs n'a été déclaré.";
    }
}

1;
__END__

=encoding utf8

=head1 Commande:

    armen available

=head1 Description:

    Afficher la liste des µs déclarés

=cut
