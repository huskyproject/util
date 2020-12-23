#
# A script for testing Husky::Rmfiles
# t/11_rmdir.t
#
use warnings;
use strict;
use File::Spec::Functions qw/splitdir catdir catfile/;
use File::Path qw(remove_tree);
use Cwd qw/cwd abs_path/;
use Test::More;
use Fidoconfig::Token 2.0;

# Remove the directory structure created in 01_mkdir.t
#goto END;
my $cwd = cwd();
my @dirs = splitdir($cwd);
my $t;
$t = $dirs[$#dirs] eq "t" ? $cwd : normalize(catdir($cwd, "t"));
my $basedir = normalize(catdir($t, "fido"));
chdir($basedir) or die "Cannot chdir $basedir";
my $dupebase = normalize(catdir($basedir, "dupebase"));
my $in = normalize(catdir($basedir, "in"));
my $log = normalize(catdir($basedir, "log"));
my $msg = normalize(catdir($basedir, "msg"));
my $nodelist = normalize(catdir($basedir, "nodelist"));
my $out = normalize(catdir($basedir, "out"));
my $pass = normalize(catdir($basedir, "pass"));
remove_tree($dupebase, $in, $log, $msg, $nodelist, $out, $pass);

END:
ok(1, "dummy");
done_testing();
