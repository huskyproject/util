#
# A script for testing Husky::Rmfiles
# t/04_unsubscribe.t
#
use diagnostics;
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token 2.0;
use Husky::Rmfiles;
use File::Spec::Functions;
use Cwd 'abs_path';
use File::Copy qw/cp mv/;
use 5.008;

$ENV{FIDOCONFIG} = undef;
my $basedir = catdir(Cwd::abs_path("t"), "fido");
$ENV{BASEDIR} = $basedir;
my $cfgdir = catdir($basedir, "cfg");
$ENV{MBASEDIR} = catdir($basedir, "msg");
$link = "1:23/456";
$log = "rmLink.log";

# test#1
$fidoconfig = catfile($cfgdir, "09_unsub.cfg");
my @makedirs = ("tparser", "-Dmodule=hpt", "-P", "$fidoconfig");
if(getOS() eq 'UNIX')
{
    my $cmd = join(" ", @makedirs);
    my $exitcode = system($cmd);
    lastError("system(\"$cmd\") failed: $!") if(($exitcode >> 8) != 0);
}
else
{
    my $exitcode = system(@makedirs);
    lastError("system(\"@makedirs\") failed: $!") if(($exitcode >> 8) != 0);
}
my $bak = "$fidoconfig" . ".bak";
cp("$fidoconfig", "$bak") or die "Copy to $bak failed: $!";
init();
put(7, '###### 04_unsubscribe.t ######');
put(6, "test#1");
my $out;
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    unsubscribeLink();
}
like($out, qr/was unsubscribed from all echos/, "unsubscribed from echos#1");
open(FC, "<", "$fidoconfig") or die("Cannot open $fidoconfig: $!");
my @lines = <FC>;
close(FC);
my $num_entries = grep {m/EchoArea/i;} grep {m/$link/;} @lines;
is($num_entries, 0, "unsubscribed from echos#2");
mv("$bak", "$fidoconfig") or die "Move from $bak failed: $!";

# test#1dry
put(6, "test#1dry");
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "09_unsub.cfg");
$bak = "$fidoconfig" . ".bak";
cp("$fidoconfig", "$bak") or die "Copy to $bak failed: $!";
init();
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    unsubscribeLink();
}
like($out, qr/was unsubscribed from all echos/, "unsubscribed from echos#1dry");
open(FC, "<", "$fidoconfig") or die("Cannot open $fidoconfig: $!");
@lines = <FC>;
close(FC);
$num_entries = grep {m/EchoArea/i;} grep {m/$link/;} @lines;
is($num_entries, 3, "not unsubscribed from echos");
mv("$bak", "$fidoconfig") or die "Move from $bak failed: $!";
$dryrun = undef;

# test#2
put(6, "test#2");
$fidoconfig = catfile($cfgdir, "10_unsub.cfg");
$ENV{FIDOCONFIG} = $fidoconfig;
my $netmailArea = catdir($basedir, "msg", "netmail");
@makedirs = ("tparser", "-Dmodule=htick", "-P", "$fidoconfig");
if(getOS() eq 'UNIX')
{
    my $cmd = join(" ", @makedirs);
    my $exitcode = system($cmd);
    lastError("system(\"$cmd\") failed: $!") if(($exitcode >> 8) != 0);
}
else
{
    my $exitcode = system(@makedirs);
    lastError("system(\"@makedirs\") failed: $!") if(($exitcode >> 8) != 0);
}
$bak = "$fidoconfig" . ".bak";
cp("$fidoconfig", "$bak") or die "Copy to $bak failed: $!";
init();
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    unsubscribeLink();
}
like($out, qr/was unsubscribed from all fileechos/, "unsubscribed from fileechos#1");
open(FC, "<", "$fidoconfig") or die("Cannot open $fidoconfig: $!");
@lines = <FC>;
close(FC);
$num_entries = grep {m/FileArea/i;} grep {m/$link/;} @lines;
is($num_entries, 0, "unsubscribed from fileechos#2");
mv("$bak", "$fidoconfig") or die "Move from $bak failed: $!";

# test#2dry
put(6, "test#2dry");
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "10_unsub.cfg");
$ENV{FIDOCONFIG} = $fidoconfig;
$netmailArea = catdir($basedir, "msg", "netmail");
$bak = "$fidoconfig" . ".bak";
cp("$fidoconfig", "$bak") or die "Copy to $bak failed: $!";
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    unsubscribeLink();
}
like($out, qr/was unsubscribed from all fileechos/, "unsubscribed from fileechos#1dry");
open(FC, "<", "$fidoconfig") or die("Cannot open $fidoconfig: $!");
@lines = <FC>;
close(FC);
$num_entries = grep {m/FileArea/i;} grep {m/$link/;} @lines;
is($num_entries, 3, "not unsubscribed from fileechos");
mv("$bak", "$fidoconfig") or die "Move from $bak failed: $!";
$dryrun = undef;

done_testing();
