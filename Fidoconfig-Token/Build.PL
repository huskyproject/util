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
    "dist_abstract" => "Perl functions for accessing values of single fidoconfig tokens",
    "dist_author" => "Michael Dukelsky 2:5020/1042\@fidonet",
    "dist_version_from" => "lib/Fidoconfig/Token.pm",
    "license" => "perl",
    "module_name" => "Fidoconfig::Token",
    "requires" =>
    {
        "Carp" => 0,
        "Config" => 0,
        "File::Spec::Functions" => 0,
        "perl" => "5.008",
        "strict" => 0,
        "warnings" => 0
    },
    "test_requires" =>
    {
        "Cwd" => 0,
        "diagnostics" => 0,
        "Test::More" => "0.88",
        "strict" => 0,
        "warnings" => 0
    }
);

my $build = Module::Build->new(%module_build_args);
$build->create_build_script;
