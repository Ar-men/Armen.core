#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

package Exclus::Util;

#md_# Exclus::Util
#md_

use Exclus::Exclus;
use Data::Dumper ();
use Data::UUID ();
use Exporter qw(import);
use File::Spec::Functions qw(canonpath);
use List::Util qw(min max);
use Module::Runtime qw(use_module);
use POSIX qw(strftime);
use Ref::Util qw(is_ref is_hashref);
use Scalar::Util qw(looks_like_number);
use String::Random;
use Term::Table;
use Time::HiRes qw(gettimeofday tv_interval usleep);
use Exclus::Environment;

our @EXPORT_OK = qw(
    $_call_if_can
    trim_left trim_right clean_string create_uuid time_to_string to_stderr maybe_undef dump_data
    monkey_patch key_value plugin deep_exists ms_sleep t0 t0_ms_elapsed to_priority format_table
    render_table generate_string build_path root_path
);

#md_## Les méthodes
#md_

#md_### $_call_if_can()
#md_
our $_call_if_can = sub {
    my ($object, $method) = (shift, shift);
    return $object->can($method) ? $object->$method(@_) : undef;
};

#md_### trim_left()
#md_
sub trim_left {
    my $string = shift;
    $string =~ s/^\s+//;
    return $string;
}

#md_### trim_right()
#md_
sub trim_right {
    my $string = shift;
    $string =~ s/\s+$//;
    return $string;
}

#md_### clean_string()
#md_
sub clean_string {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    $string =~ s/\n/ | /g;
    $string =~ s/\t/ /g;
    return $string;
}

#md_### create_uuid()
#md_
sub create_uuid {
    state $_uuid = Data::UUID->new;
    return $_uuid->create_str;
}

#md_### time_to_string()
#md_
sub time_to_string { strftime('%Y.%m.%d %H:%M:%S', localtime($_[0] // time)) }

#md_### to_stderr()
#md_
sub to_stderr {
    my ($message) = @_;
    my ($package, $file_name, $line) = caller;
    say STDERR trim_right(join ' >> ', time_to_string(), $file_name, $line, clean_string($message));
}

#md_### maybe_undef()
#md_
sub maybe_undef {
    my $value = shift;
    return defined $value ? "$value" : 'undef'
}

#md_### dump_data()
#md_
sub dump_data {
    my ($data, $ident) = @_;
    return
        is_ref($data)
            ? Data::Dumper->new([$data])->Indent($ident // 0)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump()
            : maybe_undef($data);
}

#md_### monkey_patch()
#md_
sub monkey_patch {
    my ($package, %patch) = @_;
    no strict 'refs';
####no warnings 'redefine';
    *{"${package}::$_"} = $patch{$_} foreach keys %patch;
}

#md_### key_value()
#md_
sub key_value {
    my ($hash, $key, $default) = @_;
    return exists $hash->{$key} ? $hash->{$key} : $default;
}

#md_### plugin()
#md_
sub plugin {
    my ($package, $name, $attributes) = @_;
    my $class = "${package}::Plugin::${name}";
    my $plugin = use_module($class)->new(%$attributes);
    return wantarray ? ($plugin, $class) : $plugin;
}

#md_### deep_exists()
#md_
sub deep_exists {
    my $data = shift;
    my $exists = 1;
    foreach (@_) {
        if (is_hashref($data) && exists $data->{$_}) {
            $data = $data->{$_}
        }
        else {
            $exists = 0;
            last;
        }
    }
    return wantarray ? ($exists, $data) : $exists;
}

#md_### t0()
#md_
sub t0 { [gettimeofday] }

#md_### t0_ms_elapsed()
#md_
#md_Millisecondes
#md_
sub t0_ms_elapsed { tv_interval($_[0]) * 1000 }

#md_### ms_sleep()
#md_
#md_Millisecondes
#md_
sub ms_sleep { usleep($_[0] * 1000) }

#md_### to_priority()
#md_
sub to_priority {
    state $_priorities = {
        NONE     => 0,
        LOW      => 20,
        MEDIUM   => 50,
        HIGH     => 80,
        CRITICAL => 100
    };
    my ($priority) = @_;
    return min(max($priority, 0), 100)
        if looks_like_number($priority);
    return
        exists $_priorities->{$priority} ? $_priorities->{$priority} : 0;
}

#md_### format_table()
#md_
sub format_table {
    my $rows = shift;
    return () unless @$rows;
    return Term::Table->new(max_width => 150, header => [@_], rows => $rows)->render;
}

#md_### render_table()
#md_
sub render_table { join("\n", format_table(@_)) }

#md_### generate_string()
#md_
sub generate_string {
    state $_generator = String::Random->new;
    return $_generator->randregex(@_);
}

#md_### build_path()
#md_
sub build_path { canonpath(join('/', @_)) }

#md_### root_path()
#md_
sub root_path { build_path(env()->{root}, @_) }

1;
__END__
