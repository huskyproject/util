#
# A script for testing Husky::Rmfiles
# t/08_rmOrphanFilesFromOutbound.t
#
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

sub createExt
{
    my ($rfirst, @second) = @_;
    my $firstSize = @$rfirst;
    my $secondSize = @second;
    return "$$rfirst[int(rand($firstSize))]$second[int(rand($secondSize))]";
}

sub createFile
{
    my $file = shift;
    open(FH, ">", $file) or die("Cannot create $file: $!");
    close(FH);
}

my @weekday = ('mo', 'tu', 'we', 'th', 'fr', 'sa', 'su');
sub createBsoMail
{
    my ($outbound, $lonumber, $youngnumber, $orphannumber) = @_;
    my $files_to_delete = catfile($outbound, "*");
    unlink glob($files_to_delete);
    my @lonames;
    for (1..$lonumber)
    {
        my $loname = createBasename();
        while(grep(/^$loname$/, @lonames))
        {
            $loname = createBasename();
        }
        push(@lonames, $loname);
        createFile(catfile($outbound, "$loname.hut"));
        createFile(catfile($outbound, "$loname.try"));
        createFile(catfile($outbound, "$loname.hld"));
        my $hlo = catfile($outbound, "$loname.hlo");
        createFile($hlo);
        for (1..7)
        {
            my $filename = createBasename() . '.' . createExt(\@weekday, (0..9, 'a'..'z'));
            my $filepath = catfile($outbound, $filename);
            while(-f $filepath)
            {
                $filename = createBasename() . '.' . createExt(\@weekday, (0..9, 'a'..'z'));
                $filepath = catfile($outbound, $filename);
            }
            createFile($filepath);
            open(FH, ">>", "$hlo") or die("Cannot open $hlo: $!");
            print FH "#$filepath\n";
            close(FH);
        }
    }
    for (1..$youngnumber)
    {
        my $filename = createBasename() . '.' . createExt(\@weekday, (0..9, 'a'..'z'));
        my $filepath = catfile($outbound, $filename);
        while(-f $filepath)
        {
            $filename = createBasename() . '.' . createExt(\@weekday, (0..9, 'a'..'z'));
            $filepath = catfile($outbound, $filename);
        }
        createFile($filepath);
    }
    my $age = 190 * 24 * 3600; # 190 days
    my $filetime = time() - $age;
    for (1..$orphannumber)
    {
        my $filename = createBasename() . '.' . createExt(\@weekday, (0..9, 'a'..'z'));
        my $filepath = catfile($outbound, $filename);
        while(-f $filepath)
        {
            $filename = createBasename() . '.' . createExt(\@weekday, (0..9, 'a'..'z'));
            $filepath = catfile($outbound, $filename);
        }
        createFile($filepath);
        utime $filetime, $filetime, $filepath;
    }
}

$ENV{FIDOCONFIG} = undef;
my $basedir = catdir(abs_path("t"), "fido");
$ENV{BASEDIR} = $basedir;
my $cfgdir = catdir($basedir, "cfg");
$ENV{MBASEDIR} = catdir($basedir, "msg");
my $outbound = catdir($basedir, "out", "outbound");
$log = "rmOrphan.log";
$listterm = 1;
$listlog = 1;
$huskyBinDir = $ENV{HUSKYBINDIR};

# test#1
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
createBsoMail($outbound, 4, 7, 9);
init("nolink");
put(6, "###### 08_rmOrphanFilesFromOutbound.t ######");
put(6, "test#1");
my $out;
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmOrphanFilesFromOutbound($outbound, 183);
}
my @lines = split(/\n/, $out);
like($out, qr/9 files were deleted/, "test#1 number of deleted files");
my $num = grep(m%^\S+ deleted%, @lines);
is($num, 9, "test#1");
my $files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 51, "test#1 remained in outbound");

# test#1dry
put(6, "test#1dry");
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
createBsoMail($outbound, 4, 7, 9);
init("nolink");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmOrphanFilesFromOutbound($outbound, 183);
}
@lines = split(/\n/, $out);
like($out, qr/9 files were deleted/, "test#1dry number of deleted files");
$num = grep(m%^\S+ deleted%, @lines);
is($num, 9, "test#1dry");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 60, "test#1dry remained in outbound");
$dryrun = undef;

# test#2
put(6, "test#2");
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
createBsoMail($outbound, 0, 7, 9);
init("nolink");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmOrphanFilesFromOutbound($outbound, 183);
}
@lines = split(/\n/, $out);
like($out, qr/9 files were deleted/, "test#2 number of deleted files");
$num = grep(m%^\S+ deleted%, @lines);
is($num, 9, "test#2");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 7, "test#2 remained in outbound");

# test#2dry
put(6, "test#2dry");
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
createBsoMail($outbound, 0, 7, 9);
init("nolink");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmOrphanFilesFromOutbound($outbound, 183);
}
@lines = split(/\n/, $out);
like($out, qr/9 files were deleted/, "test#2dry number of deleted files");
$num = grep(m%^\S+ deleted%, @lines);
is($num, 9, "test#2dry");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 16, "test#2dry remained in outbound");
$dryrun = undef;

# test#3
put(6, "test#3");
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
createBsoMail($outbound, 4, 7, 0);
init("nolink");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmOrphanFilesFromOutbound($outbound, 183);
}
@lines = split(/\n/, $out);
unlike($out, qr/files were deleted/, "test#3 number of deleted files");
$num = grep(m%^\S+ deleted%, @lines);
is($num, 0, "test#3");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 51, "test#3 remained in outbound");

# test#3dry
put(6, "test#3dry");
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
createBsoMail($outbound, 4, 7, 0);
init("nolink");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmOrphanFilesFromOutbound($outbound, 183);
}
@lines = split(/\n/, $out);
unlike($out, qr/files were deleted/, "test#3dry number of deleted files");
$num = grep(m%^\S+ deleted%, @lines);
is($num, 0, "test#3dry");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 51, "test#3dry remained in outbound");
$dryrun = undef;

done_testing();
