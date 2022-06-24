#
# Build.PL
#
use Module::Build 0.28;
use strict;
use warnings;

my $class = Module::Build->subclass(
    class => "Module::Build::Husky",
    code => <<'SUBCLASS' );

sub ACTION_test
{
    my $self = shift;
    my $dir = ($^O =~ /Win/) ? $ARGV[2] : $ARGV[1];
    $ENV{HUSKYBINDIR} = $dir if(defined($dir) && $dir ne "" && -d $dir);
    $self->SUPER::ACTION_test;
}
SUBCLASS

my $build = $class->new
  (
    "configure_requires" =>
    {
        "Module::Build" => "0.28"
    },
    "build_requires" =>
    {
        "Module::Build" => "0.28"
    },
    "dist_abstract" => "Perl functions for deleting a link files and the link itself from fidoconfig",
    "dist_author" => "Michael Dukelsky 2:5020/1042\@fidonet",
    "dist_version_from" => "lib/Husky/Rmfiles.pm",
    "license" => "perl",
    "module_name" => "Husky::Rmfiles",
    "requires" =>
    {
        "Carp" => 0,
        "Config" => 0,
        "Fcntl" => 0,
        "Fidoconfig::Token" => 2.3,
        "File::Basename" => 0,
        "File::Copy" => 0,
        "File::Find" => 0,
        "File::Spec::Functions" => 0,
        "File::Temp" => 0,
        "IO::Handle" => 0,
        "perl" => "5.008",
        "POSIX" => 0,
        "strict" => 0,
        "warnings" => 0
    },
    "test_requires" =>
    {
        "Cwd" => 0,
        "Fidoconfig::Token" => 2.2,
        "File::Compare" => 0,
        "File::Copy" => 0,
        "File::Path" => 0,
        "File::Spec::Functions" => 0,
        "perl" => "5.008",
        "Test::More" => "0.88",
        "strict" => 0,
        "warnings" => 0
    }
  );
$build->create_build_script;
