#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Email;

#md_# Exclus::Email
#md_

use Exclus::Exclus;
use Email::Simple;
use Email::Sender::Simple qw(sendmail try_to_sendmail);
use Email::Sender::Transport::SMTP;
use Moo;
use Sys::Hostname::FQDN qw(fqdn);
use Types::Standard qw(InstanceOf Int Maybe Str);
use Exclus::Crypt qw(decrypt);
use Exclus::Util qw(time_to_string);
use namespace::clean;

#md_## Les attributs
#md_

#md_### config
#md_
has 'config' => (
    is => 'ro', isa => InstanceOf['Exclus::Data'], required => 1
);

#md_### node
#md_
has 'node' => (
    is => 'ro', isa => Str, default => sub { fqdn }
);

#md_### smtp_host
#md_
has 'smtp_host' => (
    is => 'ro', isa => Str, lazy => 1, default => sub { $_[0]->config->get_str(qw(smtp host)) }
);

#md_### smtp_port
#md_
has 'smtp_port' => (
    is => 'ro', isa => Int, lazy => 1, default => sub { $_[0]->config->get_str(qw(smtp port)) }
);

#md_### smtp_username
#md_
has 'smtp_username' => (
    is => 'ro', isa => Maybe[Str], default => sub { $_[0]->config->maybe_get_str(qw(smtp username)) }
);

#md_### smtp_password
#md_
has 'smtp_password' => (
    is => 'ro', isa => Maybe[Str], default => sub { $_[0]->config->maybe_get_str(qw(smtp password)) }
);

#md_### from
#md_
has 'from' => (
    is => 'ro', isa => Str, lazy => 1, default => sub { 'armen@' . $_[0]->node }
);

#md_### to
#md_
has 'to' => (
    is => 'ro', isa => Str, lazy => 1, default => sub { $_[0]->config->get_str('email_to') }
);

#md_### cc
#md_
has 'cc' => (
    is => 'ro', isa => Maybe[Str], default => sub { undef }
);

#md_### subject
#md_
has 'subject' => (
    is => 'ro', isa => Str, lazy => 1, default => sub { 'armen' }
);

#md_## Les méthodes
#md_

#md_### _get_background_color()
#md_
sub _get_background_color {
    state $_severities = {
        error   => 'IndianRed',
        warning => 'PeachPuff',
        info    => 'LightCyan'
    };
    my ($self, $severity) = @_;
    return exists $_severities->{$severity} ? $_severities->{$severity} : 'Gainsboro';
}

#md_### _html()
#md_
sub _html {
    my ($self, $severity, $content, $runner, $timestamp) = @_;
    my $bg_color = $self->_get_background_color($severity);
    my $title = $self->subject;
    my $node = $self->node;
    $timestamp = time_to_string($timestamp);
###::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::###
    my $html = <<END;
<!doctype html>
<html>
<head>
    <meta name="viewport" content="width=device-width">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>armen</title>
</head>
<body style="color:black;">
<pre><code>
 ___ _______ _  ___ ___
/ _ `/ __/  ' \\/ -_) _ \\
\\_,_/_/ /_/_/_/\\__/_//_/
</code></pre>
<ul>
    <li>node=$node</li>
    <li>runner=$runner</li>
    <li>timestamp=$timestamp</li>
</ul>
<table border="0" cellpadding="20" cellspacing="0" width="100%" id="bodyTable" style="background-color:$bg_color;">
<tr><td style="padding:20px;">
<h3>$title</h3>
$content
</td></tr>
</table>
<p style="text-align:center;"><small>Powered By Archivage Num&eacute;rique</small></p>
</body>
</html>
END
###::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::###
    return $html;
}

#md_### _create_email()
#md_
sub _create_email {
    my $self = shift;
    my $email = Email::Simple->create(
        header => [
            From => $self->from,
            To => $self->to,
            Cc => $self->cc,
            Subject => $self->subject,
            'Content-Type' => 'text/html',
            'MIME-Version' => '1.0'
        ],
        body => $self->_html(@_)
    );
    return $email;
}

#md_### _create_transport()
#md_
sub _create_transport {
    my $self = shift;
    my $options = {
        host => $self->smtp_host,
        port => $self->smtp_port
    };
    if ($self->smtp_username) {
        $options->{sasl_username} = $self->smtp_username;
        $options->{sasl_password} = $self->smtp_password ? decrypt($self->smtp_password) : undef;
    }
    return {transport => Email::Sender::Transport::SMTP->new($options)};
}

#md_### send()
#md_
sub send {
    my $self = shift;
    sendmail($self->_create_email(@_), $self->_create_transport);
}

#md_### try_to_send()
#md_
sub try_to_send {
    my $self = shift;
    try_to_sendmail($self->_create_email(@_), $self->_create_transport);
}

1;
__END__
