#
# A script for testing Husky::Rmfiles
# t/07_rmOrphanFiles.t
#
use diagnostics;
use warnings;
use strict;
use Test::More;
use Husky::Rmfiles;
use File::Spec::Functions;
use Cwd 'abs_path';
use 5.008;

sub createBasename
{
    my $name = "";
    for (1..8)
    {
        $name .= (0..9, 'a'..'f')[int(rand(16))];
    }
    return $name;
}

sub createFile
{
    my $file = shift;
    open(FH, ">", $file) or die("Cannot create $file: $!");
    close(FH);
}

sub createPassAreaFiles
{
    my ($passAreaDir, $ticOutbound) = @_;
    # Files with tics
    for (1..5)
    {
        my $filename = createBasename() . ".zip";
        my $filepath = catfile($passAreaDir, $filename);
        while(-f $filepath)
        {
            $filename = createBasename() . ".zip";
            $filepath = catfile($passAreaDir, $filename);
        }
        createFile($filepath);
        my $ticpath = catfile($ticOutbound, createBasename() . ".tic");
        while(-f $ticpath)
        {
            $ticpath = catfile($ticOutbound, createBasename() . ".tic");
        }
        open(FH, ">", $ticpath) or die("Cannot open $ticpath: $!");
        print FH "File $filename\n";
        close($ticpath);
    }

    # Files without tics
    for (1..3)
    {
        my $filename = createBasename() . ".rar";
        my $filepath = catfile($passAreaDir, $filename);
        while(-f $filepath)
        {
            $filename = createBasename() . ".rar";
            $filepath = catfile($passAreaDir, $filename);
        }
        createFile($filepath);
    }
}

$ENV{FIDOCONFIG} = undef;
my $basedir = catdir(abs_path("t"), "fido");
$ENV{BASEDIR} = $basedir;
my $cfgdir = catdir($basedir, "cfg");
$ENV{MBASEDIR} = catdir($basedir, "msg");
my $passAreaDir = catdir($basedir, "pass");
my $ticOutbound = catdir($basedir, "out", "tic");
$log = "rmLink.log";
$listterm = 1;
$listlog = 1;

# test#1
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
$link = "2:345/678";
init();
put(6, "###### 07_rmOrphanFiles.t ######");
put(6, "test#1");
createPassAreaFiles($passAreaDir, $ticOutbound);
my $out;
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmOrphanFilesFromPassFileAreaDir();
}
my @lines = split(/\n/, $out);
like($out, qr/3 orphan files were deleted/, "test#1 number of deleted files");
my $num = grep(m%^File \S+ deleted%, @lines);
is($num, 3, "test#1");
my $files_to_delete = catfile($passAreaDir, "*.zip");
$num = unlink glob($files_to_delete);
is($num, 5, "test#1 .zip remained in passAreaDir");
$files_to_delete = catfile($passAreaDir, "*.rar");
$num = unlink glob($files_to_delete);
is($num, 0, "test#1 .rar remained in passAreaDir");
$files_to_delete = catfile($ticOutbound, "*.tic");
$num = unlink glob($files_to_delete);
is($num, 5, "test#1 .tic remained in ticOutbound");

# test#1dry
put(6, "test#1dry");
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
$link = "2:345/678";
init();
createPassAreaFiles($passAreaDir, $ticOutbound);
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmOrphanFilesFromPassFileAreaDir();
}
@lines = split(/\n/, $out);
like($out, qr/3 orphan files were deleted/, "test#1dry number of deleted files");
$num = grep(m%^File \S+ deleted%, @lines);
is($num, 3, "test#1dry");
$files_to_delete = catfile($passAreaDir, "*.zip");
$num = unlink glob($files_to_delete);
is($num, 5, "test#1dry remained in passAreaDir");
$files_to_delete = catfile($passAreaDir, "*.rar");
$num = unlink glob($files_to_delete);
is($num, 3, "test#1dry .rar remained in passAreaDir");
$files_to_delete = catfile($ticOutbound, "*.tic");
$num = unlink glob($files_to_delete);
is($num, 5, "test#1dry remained in ticOutbound");
$dryrun = undef;

done_testing();
