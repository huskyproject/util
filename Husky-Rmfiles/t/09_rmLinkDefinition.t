#
# A script for testing Husky::Rmfiles
# t/09_rmLinkDefinition.t
#
use diagnostics;
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token 2.0;
use Husky::Rmfiles;
use File::Spec::Functions;
use Cwd 'abs_path';
use File::Compare;
use File::Copy qw/cp mv/;
use 5.008;

# This function is used as the third argument to File::Compare::compare
my $cmp1 = sub
{
    $_[0] =~ s/[\r\n]+//;
    $_[1] =~ s/[\r\n]+//;
    return $_[0] ne $_[1];
};

$ENV{FIDOCONFIG} = undef;
my $basedir = catdir(abs_path("t"), "fido");
$ENV{BASEDIR} = $basedir;
my $cfgdir = catdir($basedir, "cfg");
$ENV{CFGDIR} = $cfgdir;
$ENV{MBASEDIR} = catdir($basedir, "msg");
$log = "rmLink.log";
$listterm = 1;
$listlog = 1;

# test#1
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
$link = "2:345/678";
init();
put(6, "###### 09_rmLinkDefinition.t ######");
put(6, "test#1");
my $error;
eval
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$error);
    rmLinkDefinition();
};
like($@, qr%^Line \"AKA 2:345/678\" not found%, "test#1");

# test#2
$fidoconfig = catfile($cfgdir, "15_rmLink.cfg");
init();
put(6, "test#2");
eval
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$error);
    rmLinkDefinition();
};
like($@, qr%^Cannot find 'Link' token for 2:345/678%, "test#2");

# test#3
my $src = catfile($cfgdir, "16_rmLink.cfg");
my $tmp = catfile($cfgdir, "16_rmLink1.cfg");
my $sampleDir = catdir($cfgdir, "sample");
my $sample = catfile($sampleDir, "16_rmLink1.cfg");
cp($src, $tmp);
$fidoconfig = catfile($cfgdir, "16_rmLink1.cfg");
$delete = 0;
$backup = 0;
init();
put(6, "test#3");
my $out;
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmLinkDefinition();
}
like($out, qr%^Link 2:345/678 Dmitry Medvedev%, "test#3 sysop");
is(compare($tmp, $sample, $cmp1), 0, "test#3 cmp files");
unlink($tmp);

# test#3dry
$dryrun = 1;
$src = catfile($cfgdir, "16_rmLink.cfg");
$tmp = catfile($cfgdir, "16_rmLink1.cfg");
$sampleDir = catdir($cfgdir, "sample");
$sample = catfile($sampleDir, "16_rmLink1.cfg");
cp($src, $tmp);
$fidoconfig = catfile($cfgdir, "16_rmLink1.cfg");
$delete = 0;
$backup = 0;
init();
put(6, "test#3dry");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmLinkDefinition();
}
like($out, qr%^Link 2:345/678 Dmitry Medvedev%, "test#3dry sysop");
is(compare($tmp, $src, $cmp1), 0, "test#3dry cmp files");
unlink($tmp);
$dryrun = undef;

# test#4
$src = catfile($cfgdir, "17_rmLink.cfg");
$tmp = catfile($cfgdir, "17_rmLink1.cfg");
$sample = catfile($sampleDir, "17_rmLink1.cfg");
cp($src, $tmp);
$fidoconfig = $tmp;
$delete = 0;
$backup = 0;
init();
put(6, "test#4");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmLinkDefinition();
}
like($out, qr%^Link 2:345/678 Dmitry Medvedev%, "test#4 sysop");
is(compare($tmp, $sample, $cmp1), 0, "test#4 cmp files");
unlink($tmp);

# test#4dry
$dryrun = 1;
$src = catfile($cfgdir, "17_rmLink.cfg");
$tmp = catfile($cfgdir, "17_rmLink1.cfg");
$sample = catfile($sampleDir, "17_rmLink1.cfg");
cp($src, $tmp);
$fidoconfig = $tmp;
$delete = 0;
$backup = 0;
init();
put(6, "test#4dry");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmLinkDefinition();
}
like($out, qr%^Link 2:345/678 Dmitry Medvedev%, "test#4dry sysop");
is(compare($tmp, $src, $cmp1), 0, "test#4dry cmp files");
unlink($tmp);
$dryrun = undef;

# test#5
$src = catfile($cfgdir, "17_rmLink.cfg");
my $bak = catfile($cfgdir, "17_rmLink.cfg.bak");
$sample = catfile($sampleDir, "17_rmLink2.cfg");
$fidoconfig = $src;
$delete = 1;
$backup = 1;
init();
put(6, "test#5");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmLinkDefinition();
}
like($out, qr%^Link 2:345/678 Dmitry Medvedev%, "test#5 sysop");
is(compare($src, $sample, $cmp1), 0, "test#5 cmp files");
mv($bak, $src);

# test#5dry
$dryrun = 1;
$src = catfile($cfgdir, "17_rmLink.cfg");
$bak = catfile($cfgdir, "17_rmLink.cfg.bak");
$sample = catfile($sampleDir, "17_rmLink2.cfg");
$fidoconfig = $src;
$delete = 1;
$backup = 1;
init();
put(6, "test#5dry");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmLinkDefinition();
}
like($out, qr%^Link 2:345/678 Dmitry Medvedev%, "test#5dry sysop");
is(compare($src, $bak, $cmp1), 0, "test#5dry cmp files");
mv($bak, $src);
$dryrun = undef;

# test#6
$src = catfile($cfgdir, "18_rmLink.cfg");
$bak = catfile($cfgdir, "18_rmLink.cfg.bak");
$sample = catfile($sampleDir, "18_rmLink.cfg");
$fidoconfig = $src;
$delete = 0;
$backup = 1;
init();
put(6, "test#6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmLinkDefinition();
}
like($out, qr%^Link 2:345/678 Dmitry Medvedev%, "test#6 sysop");
is(compare($src, $sample, $cmp1), 0, "test#6 cmp files");
mv($bak, $src);

# test#6dry
$dryrun = 1;
$src = catfile($cfgdir, "18_rmLink.cfg");
$bak = catfile($cfgdir, "18_rmLink.cfg.bak");
$sample = catfile($sampleDir, "18_rmLink.cfg");
$fidoconfig = $src;
$delete = 0;
$backup = 1;
init();
put(6, "test#6dry");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmLinkDefinition();
}
like($out, qr%^Link 2:345/678 Dmitry Medvedev%, "test#6dry sysop");
is(compare($src, $bak, $cmp1), 0, "test#6dry cmp files");
mv($bak, $src);
$dryrun = undef;

# test#7
$src = catfile($cfgdir, "18_rmLink.cfg");
$bak = catfile($cfgdir, "18_rmLink.cfg.bak");
$sample = catfile($sampleDir, "18_rmLink_d.cfg");
$fidoconfig = $src;
$delete = 1;
$backup = 1;
init();
put(6, "test#7");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmLinkDefinition();
}
like($out, qr%^Link 2:345/678 Dmitry Medvedev%, "test#7 sysop");
is(compare($src, $sample, $cmp1), 0, "test#7 cmp files");
mv($bak, $src);

# test#7dry
$dryrun = 1;
$src = catfile($cfgdir, "18_rmLink.cfg");
$bak = catfile($cfgdir, "18_rmLink.cfg.bak");
$sample = catfile($sampleDir, "18_rmLink_d.cfg");
$fidoconfig = $src;
$delete = 1;
$backup = 1;
init();
put(6, "test#7dry");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmLinkDefinition();
}
like($out, qr%^Link 2:345/678 Dmitry Medvedev%, "test#7dry sysop");
is(compare($src, $bak, $cmp1), 0, "test#7dry cmp files");
mv($bak, $src);
$dryrun = undef;

# test#8
$src = catfile($cfgdir, "19_rmLink_2.cfg");
$bak = catfile($cfgdir, "19_rmLink_2.cfg.bak");
$sample = catfile($sampleDir, "19_rmLink_2.cfg");
$fidoconfig = catfile($cfgdir, "19_rmLink_1.cfg");
$delete = 0;
$backup = 1;
init();
put(6, "test#8");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmLinkDefinition();
}
like($out, qr%^Link 2:345/678 Dmitry Medvedev%, "test#8 sysop");
is(compare($src, $sample, $cmp1), 0, "test#8 cmp files");
mv($bak, $src);

# test#8dry
$dryrun = 1;
$src = catfile($cfgdir, "19_rmLink_2.cfg");
$bak = catfile($cfgdir, "19_rmLink_2.cfg.bak");
$sample = catfile($sampleDir, "19_rmLink_2.cfg");
$fidoconfig = catfile($cfgdir, "19_rmLink_1.cfg");
$delete = 0;
$backup = 1;
init();
put(6, "test#8dry");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmLinkDefinition();
}
like($out, qr%^Link 2:345/678 Dmitry Medvedev%, "test#8dry sysop");
is(compare($src, $bak, $cmp1), 0, "test#8dry cmp files");
mv($bak, $src);
$dryrun = undef;

done_testing();
