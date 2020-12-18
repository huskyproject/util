#
# A script for testing Husky::Rmfiles
# t/00_mkdir.t
#
use warnings;
use strict;
use File::Spec::Functions qw/splitdir catdir catfile/;
use Cwd qw/cwd abs_path/;
use Test::More;
use Fidoconfig::Token 2.0;

# Check whether hpt is accessible
my $huskyBinDir = defined($ENV{HUSKYBINDIR}) ? $ENV{HUSKYBINDIR} : "";
my $exe = getOS() ne 'UNIX' ? ".exe" : "";
my $hpt;
if($huskyBinDir ne "" && -d $huskyBinDir)
{
    $hpt   = normalize(catfile($huskyBinDir, "hpt".$exe));
}
else
{
    $hpt   = "hpt".$exe;
}
my $hpt_exists = grep(/hpt/, qx($hpt -h)) > 1 ? 1 : 0;
$hpt_exists or die "Cannot access $hpt";

# Create a directory structure for use in the later tests
my $cwd = cwd();
my @dirs = splitdir($cwd);
my $t;
$t = $dirs[$#dirs] eq "t" ? $cwd : normalize(catdir($cwd, "t"));
my $basedir = normalize(catdir($t, "fido"));
chdir($basedir) or die "Cannot chdir $basedir";
if(!-d "dupebase")
{
    mkdir("dupebase") or die "Cannot mkdir dupebase";
}
if(!-d "in")
{
    mkdir("in") or die "Cannot mkdir in";
}
my $in = normalize(catdir($basedir, "in"));
chdir($in) or die "Cannot chdir $in";
if(!-d "inb")
{
    mkdir("inb") or die "Cannot mkdir inb";
}
if(!-d "inbound")
{
    mkdir("inbound") or die "Cannot mkdir inbound";
}
if(!-d "local")
{
    mkdir("local") or die "Cannot mkdir local";
}
if(!-d "tmp")
{
    mkdir("tmp") or die "Cannot mkdir tmp";
}
chdir($basedir) or die "Cannot chdir $basedir";
if(!-d "log")
{
    mkdir("log") or die "Cannot mkdir log";
}
if(!-d "msg")
{
    mkdir("msg") or die "Cannot mkdir msg";
}
if(!-d "nodelist")
{
    mkdir("nodelist") or die "Cannot mkdir nodelist";
}
if(!-d "out")
{
    mkdir("out") or die "Cannot mkdir out";
}
if(!-d "pass")
{
    mkdir("pass") or die "Cannot mkdir pass";
}
my $msg = normalize(catdir($basedir, "msg"));
chdir($msg) or die "Cannot chdir $msg";
if(!-d "bad")
{
    mkdir("bad") or die "Cannot mkdir bad";
}
if(!-d "dupes")
{
    mkdir("dupes") or die "Cannot mkdir dupes";
}
if(!-d "jam")
{
    mkdir("jam") or die "Cannot mkdir jam";
}
if(!-d "netmail")
{
    mkdir("netmail") or die "Cannot mkdir netmail";
}
if(!-d "robots")
{
    mkdir("robots") or die "Cannot mkdir robots";
}
chdir($basedir) or die "Cannot chdir $basedir";
my $out = normalize(catdir($basedir, "out"));
chdir($out) or die "Cannot chdir $out";
if(!-d "boxes")
{
    mkdir("boxes") or die "Cannot mkdir boxes";
}
if(!-d "outbound")
{
    mkdir("outbound") or die "Cannot mkdir outbound";
}
if(!-d "outbound.001")
{
    mkdir("outbound.001") or die "Cannot mkdir outbound.001";
}
if(!-d "tic")
{
    mkdir("tic") or die "Cannot mkdir tic";
}
if(!-d "tmp")
{
    mkdir("tmp") or die "Cannot mkdir tmp";
}
my $outbound = normalize(catdir($out, "outbound"));
chdir($outbound) or die "Cannot chdir $outbound";
if(!-d "busy.htk")
{
    mkdir("busy.htk") or die "Cannot mkdir busy.htk";
}
if(!-d "notused")
{
    mkdir("notused") or die "Cannot mkdir notused";
}
chdir($out) or die "Cannot chdir $out";
my $outbound_001 = normalize(catdir($out, "outbound.001"));
chdir($outbound_001) or die "Cannot chdir $outbound_001";
if(!-d "notused")
{
    mkdir("notused") or die "Cannot mkdir notused";
}
chdir($basedir) or die "Cannot chdir $basedir";

ok(1, "dummy");
done_testing();
