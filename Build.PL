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
    "dist_abstract" => "Four Perl utilities using functions from Fidoconfig::Token and Husky::Rmfiles",
    "dist_author" => "Michael Dukelsky 2:5020/1042\@fidonet",
    "dist_version" => 1.8,
    "license" => "perl",
    "dist_name" => "Husky-Util",
    "requires" =>
    {
        "Config" => 0,
        "Cwd" => 0,
        "Fcntl" => 0,
        "Fidoconfig::Token" => 2.5,
        "File::Basename" => 0,
        "File::Find" => 0,
        "File::Spec::Functions" => 0,
        "Getopt::Long" => 0,
        "Husky::Rmfiles" => 1.10,
        "perl" => "5.008",
        "Pod::Usage" => 0,
        "strict" => 0,
        "warnings" => 0
    },
    "test_requires" =>
    {
        "Test::More" => "0.88",
    }
);

my $build = Module::Build->new(%module_build_args);
$build->create_build_script;
