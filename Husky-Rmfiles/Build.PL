#
# Build.PL
#
use Module::Build 0.28;
use strict;
use warnings;

my %module_build_args =
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
        "Fcntl" => 0,
        "File::Find" => 0,
        "File::Spec" => 0,
        "Config" => 0,
        "File::Basename" => 0,
        "File::Temp" => 0,
        "POSIX" => 0,
        "Fidoconfig::Token" => 2.0,
        "File::Copy" => 0,
        "perl" => "5.008",
        "strict" => 0,
        "warnings" => 0
    },
    "test_requires" =>
    {
        "Test::More" => "0.88",
        "Fidoconfig::Token" => 1.6,
        "File::Spec" => 0,
        "Cwd" => 0,
        "File::Compare" => 0,
        "File::Copy" => 0,
        "perl" => "5.008",
        "diagnostics" => 0,
        "strict" => 0,
        "warnings" => 0
    }
);

my $build = Module::Build->new(%module_build_args);
$build->create_build_script;
