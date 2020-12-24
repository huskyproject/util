#
# A script for testing Husky::Rmfiles
# t/10_report.t
#
use diagnostics;
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token 2.0;
use Husky::Rmfiles;
use File::Spec::Functions qw/splitdir catdir catfile/;
use Cwd qw/cwd abs_path/;
use File::Compare;
use File::Copy qw/cp mv/;
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
    my ($outbound, $passAreaDir, $ticOutbound, $busyFileDir, $loname) = @_;
    my $files_to_delete = catfile($busyFileDir, "*");
    unlink glob($files_to_delete);
    $files_to_delete = catfile($outbound, "*");
    unlink glob($files_to_delete);
    $files_to_delete = catfile($passAreaDir, "*");
    unlink glob($files_to_delete);
    $files_to_delete = catfile($ticOutbound, "*");
    unlink glob($files_to_delete);
    mkdir($busyFileDir);
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
    my $age = 190 * 24 * 3600; # 190 days
    my $filetime = time() - $age;
    # Orphan files
    for (1..9)
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
    # Truncated echomail bundles not to be deleted
    for (1..13)
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
    for my $i (1..5)
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
        open(FH, ">>", "$hlo") or die("Cannot open $hlo: $!");
        print FH "$filepath\n";
        print FH "^$ticpath\n";
        close(FH);
        if($i < 4)
        {
            # Create .TIC referring to the same file
            my $ticpath = catfile($ticOutbound, createBasename() . ".tic");
            while(-f $ticpath)
            {
                $ticpath = catfile($ticOutbound, createBasename() . ".tic");
            }
            open(FH, ">", $ticpath) or die("Cannot open $ticpath: $!");
            print FH "File $filename\n";
            close($ticpath);
        }
    }
#    for (1..13)
#    {
#        my $ticpath = catfile($busyFileDir, createBasename() . ".tic");
#        while(-f $ticpath)
#        {
#            $ticpath = catfile($busyFileDir, createBasename() . ".tic");
#        }
#        open(FH, ">", "$ticpath") or die("Cannot open $ticpath: $!");
#        print FH "To $link\n";
#        close(FH);
#    }
}

sub createFileboxMail
{
    my ($filebox, $loname) = @_;
    if(-d $filebox)
    {
        my $files_to_delete = catfile($filebox, "*");
        unlink glob($files_to_delete);
    }
    else
    {
        mkdir($filebox);
    }
    createFile(catfile($filebox, "$loname.hut"));
    createFile(catfile($filebox, "$loname.try"));
    createFile(catfile($filebox, "$loname.hld"));
    for (1..7)
    {
        my $filename = createBasename() . '.' . createExt(\@weekday, (0..9, 'a'..'z'));
        my $filepath = catfile($filebox, $filename);
        while(-f $filepath)
        {
            $filename = createBasename() . '.' . createExt(\@weekday, (0..9, 'a'..'z'));
            $filepath = catfile($filebox, $filename);
        }
        createFile($filepath);
    }
    for (1..5)
    {
        my $filename = createBasename() . ".zip";
        my $filepath = catfile($filebox, $filename);
        while(-f $filepath)
        {
            $filename = createBasename() . ".zip";
            $filepath = catfile($filebox, $filename);
        }
        createFile($filepath);
        my $ticpath = catfile($filebox, createBasename() . ".tic");
        while(-f $ticpath)
        {
            $ticpath = catfile($filebox, createBasename() . ".tic");
        }
        open(FH, ">", $ticpath) or die("Cannot open $ticpath: $!");
        print FH "File $filename\n";
        close($ticpath);
    }
    for (1..3)
    {
        my $filename = createBasename() . ".rar";
        my $filepath = catfile($filebox, $filename);
        while(-f $filepath)
        {
            $filename = createBasename() . ".rar";
            $filepath = catfile($filebox, $filename);
        }
        createFile($filepath);
    }
}

$ENV{FIDOCONFIG} = undef;
my $cwd = cwd();
my @dirs = splitdir($cwd);
my $t;
$t = $dirs[$#dirs] eq "t" ? $cwd : normalize(catdir($cwd, "t"));
my $basedir = normalize(catdir($t, "fido"));
$ENV{BASEDIR} = $basedir;
my $cfgdir = normalize(catdir($basedir, "cfg"));
$ENV{CFGDIR} = $cfgdir;
my $sampleDir = normalize(catdir($cfgdir, "sample"));
$ENV{MBASEDIR} = normalize(catdir($basedir, "msg"));
my $outbound = catdir($basedir, "out", "outbound");
my $busyFileDir = catdir($outbound, "busy.htk");
my $PassFileAreaDir = catdir($basedir, "pass");
my $ticOutbound = catdir($basedir, "out", "tic");
$link = "2:345/678";
my $loname = "015902a6";
my $fileBoxesDir = catdir($basedir, "out", "boxes");
my $fileboxname = catdir($fileBoxesDir, "2.345.678.0");
my $netmailDir = catdir($basedir, "msg", "netmail");
$log = "rmLink.log";
$report = "";
$listterm = 1;
$listlog = 1;
my ($subject, $fromname, @header, @footer);
$subject = "Removing link $link";
$fromname = "rmLink Robot";
@header = ("  ", "$link did not pick up mail for 183 days.",
           "I am deleting all its netmail, echomail and fileechos.", "  ");
@footer = ("", "$link has been removed from 2:5020/1042 configuration files.", "  ");

# Check whether htick is accessible
my $huskyBinDir = defined($ENV{HUSKYBINDIR}) ? $ENV{HUSKYBINDIR} : "";
my $exe = getOS() ne 'UNIX' ? ".exe" : "";
my $htick;
if($huskyBinDir ne "" && -d $huskyBinDir)
{
    $htick   = normalize(catfile($huskyBinDir, "htick".$exe));
    $Husky::Rmfiles::huskyBinDir = $huskyBinDir;
}
else
{
    $htick   = "htick".$exe;
}
my $htick_exists = grep(/htick/,
    eval
    {
        no warnings 'all';
        qx($htick -h 2>&1);
    }) > 1 ? 1 : 0;


# test #1
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
my $error;
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$error);
    init();
}
put(6, "###### 10_report.t ######");
put(6, "test #1");
like($error, qr/ReportTo is not defined in your fidoconfig/, "ReportTo is not defined");

# Skip the tests not using htick if htick is accessible
goto WITH_HTICK if($htick_exists);

TEST2:
# test #2 Report to an echo area (file areas are absent)
$fidoconfig = normalize(catfile($cfgdir, "21_report.cfg"));
$ENV{FIDOCONFIG} = $fidoconfig;
init();
put(6, "test #2");
# initialize JAM msgbase
my $srcdir = catdir($sampleDir, "jam");
my $destdir = catdir($ENV{MBASEDIR}, "jam");
sub initJAM
{
    if(!-d $destdir)
    {
        mkdir($destdir) or die("Cannot create $destdir: $!");
    }
    if(-f catfile($destdir, "qqq.jhr"))
    {
        my $files_to_delete = catfile($destdir, "*");
        unlink glob($files_to_delete);
    }
    my $files_to_copy = catfile($srcdir, "qqq.*");
    for my $file (glob($files_to_copy))
    {
        cp($file, $destdir);
    }
}
initJAM();
# backup config
my $bak = "$fidoconfig" . ".bak";
cp("$fidoconfig", "$bak") or die "Copy to $bak failed: $!";
# create test data
createBsoMail($outbound, $PassFileAreaDir, $ticOutbound, $busyFileDir, $loname);
createFileboxMail($fileboxname, $loname);
# run the tested functions
unsubscribeLink();
rmFilesFromOutbound();
rmFilesFromFilebox();
rmOrphanFilesFromPassFileAreaDir();
rmOrphanFilesFromOutbound($outbound, 183);
rmLinkDefinition();
publishReport($subject, $fromname, \@header, \@footer);
# test
my $sample = normalize(catfile($sampleDir, "qqq.jdt"));
my $result = normalize(catfile($destdir, "qqq.jdt"));
my $reported = is(compare($result, $sample), 0, "report to JAM echobase");
# restore config
mv("$bak", "$fidoconfig") or die("Restoring $fidoconfig failed: $!");
# clean
if($reported)
{
    put(6, "Report was posted to qqq echo");
}
my $files_to_delete = catfile($outbound, "*");
my $num = unlink glob($files_to_delete);
$files_to_delete = catfile($busyFileDir, "*.tic");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($ticOutbound, "*.tic");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($PassFileAreaDir, "*");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
rmdir($fileboxname);

TEST3:
# test #3  Post report to netmail in Opus msgbase (file areas are absent)
$ENV{FIDOCONFIG} = undef;
$report = "";
$fidoconfig = normalize(catfile($cfgdir, "22_report.cfg"));
$ENV{FIDOCONFIG} = $fidoconfig;
init();
put(6, "test #3");
# backup config
$bak = "$fidoconfig" . ".bak";
cp("$fidoconfig", "$bak") or die "Copy to $bak failed: $!";
# create test data
createBsoMail($outbound, $PassFileAreaDir, $ticOutbound, $busyFileDir, $loname);
createFileboxMail($fileboxname, $loname);
# run the tested functions
unsubscribeLink();
rmFilesFromOutbound();
rmFilesFromFilebox();
rmOrphanFilesFromPassFileAreaDir();
rmOrphanFilesFromOutbound($outbound, 183);
rmLinkDefinition();
publishReport($subject, $fromname, \@header, \@footer);
# restore config
mv("$bak", "$fidoconfig") or die("Restoring $fidoconfig failed: $!");
# extract text from netmail
opendir(DIR, $netmailDir) or die "Could not open $netmailDir";
my @netmailFiles = grep(/^\d+\.msg$/, readdir(DIR));
closedir(DIR);
my ($reportNetmail) = grep {
                            my $file = $_; my $path = catfile($netmailDir, $file);
                            open(FH, "<", $path) or die("Cannot open $path: $!");
                            my @lines = <FH>; close(FH);
                            grep(m%Removing link 2:345/678%, @lines) ? $file : undef
                           } @netmailFiles;
my $reportPath = catfile($netmailDir, $reportNetmail);
open(FH, "<", $reportPath) or die("Cannot open $reportPath: $!");
my $line = <FH>;
close(FH);
my @lines = split /\r/, $line;
for(my $i = 0; $i < @lines; $i++)
{
    if($lines[$i] =~ /^\001PID:/)
    {
        splice(@lines, $#lines, 1);
        splice(@lines, 0, $i + 1);
        last;
    }
}
my $sampleText = catfile($sampleDir, "20_report.cfg");
open(FH, "<", $sampleText) or die("Cannot open $sampleText: $!");
my @sample = grep {s/\n//} <FH>;
close(FH);
my $cmp = 1;
if(@lines != @sample)
{
    $cmp = 0;
    put(6, "Size not equal");
    my $numlines = @lines;
    my $numsample = @sample;
    put(6, "numlines=$numlines  numsample=$numsample");
}
else
{
    for(my $i = 0; $i < @lines; $i++)
    {
        if($lines[$i] ne $sample[$i])
        {
            $cmp = 0;
            put(6, "Line number $i differs from the sample!!!");
            put(6, "Line #$i: $lines[$i]");
            last;
        }
    }
}
is($cmp, 1, "test #3");
# clean
if($cmp == 1)
{
    $files_to_delete = catfile($netmailDir, "*");
    unlink glob($files_to_delete);
}
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($busyFileDir, "*.tic");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($ticOutbound, "*.tic");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($PassFileAreaDir, "*");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
rmdir($fileboxname);

# Skip the tests using htick if there is no htick
goto END unless($htick_exists);

WITH_HTICK:
TEST4:
# test #4 Report to an echo area (file areas are absent)
$fidoconfig = normalize(catfile($cfgdir, "23_report.cfg"));
$ENV{FIDOCONFIG} = $fidoconfig;
init();
put(6, "test #4");
# initialize JAM msgbase
$srcdir = catdir($sampleDir, "jam");
$destdir = catdir($ENV{MBASEDIR}, "jam");
initJAM();
# backup config
$bak = "$fidoconfig" . ".bak";
cp("$fidoconfig", "$bak") or die "Copy to $bak failed: $!";
# create test data
createBsoMail($outbound, $PassFileAreaDir, $ticOutbound, $busyFileDir, $loname);
createFileboxMail($fileboxname, $loname);
# run the tested functions
unsubscribeLink();
rmFilesFromOutbound();
rmFilesFromFilebox();
rmOrphanFilesFromPassFileAreaDir();
rmOrphanFilesFromOutbound($outbound, 183);
rmLinkDefinition();
publishReport($subject, $fromname, \@header, \@footer);
# test
$sample = normalize(catfile($sampleDir, "qqq2.jdt"));
$result = normalize(catfile($destdir, "qqq.jdt"));
$reported = is(compare($result, $sample), 0, "report to JAM echobase");
# restore config
mv("$bak", "$fidoconfig") or die("Restoring $fidoconfig failed: $!");
# clean
if($reported)
{
    put(6, "Report was posted to qqq echo");
}
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($busyFileDir, "*.tic");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($ticOutbound, "*.tic");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($PassFileAreaDir, "*");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
rmdir($fileboxname);
goto END;

TEST5:
# test #5  Post report to netmail in Opus msgbase
$ENV{FIDOCONFIG} = undef;
$report = "";
$fidoconfig = normalize(catfile($cfgdir, "24_report.cfg"));
$ENV{FIDOCONFIG} = $fidoconfig;
init();
put(6, "test #5");
# backup config
$bak = "$fidoconfig" . ".bak";
cp("$fidoconfig", "$bak") or die "Copy to $bak failed: $!";
# create test data
createBsoMail($outbound, $PassFileAreaDir, $ticOutbound, $busyFileDir, $loname);
createFileboxMail($fileboxname, $loname);
# run the tested functions
unsubscribeLink();
rmFilesFromOutbound();
rmFilesFromFilebox();
rmOrphanFilesFromPassFileAreaDir();
rmOrphanFilesFromOutbound($outbound, 183);
rmLinkDefinition();
publishReport($subject, $fromname, \@header, \@footer);
# restore config
mv("$bak", "$fidoconfig") or die("Restoring $fidoconfig failed: $!");
# extract text from netmail
opendir(DIR, $netmailDir) or die "Could not open $netmailDir";
@netmailFiles = grep(/^\d+\.msg$/, readdir(DIR));
closedir(DIR);
($reportNetmail) = grep {
                            my $file = $_; my $path = catfile($netmailDir, $file);
                            open(FH, "<", $path) or die("Cannot open $path: $!");
                            my @lines = <FH>; close(FH);
                            grep(m%Removing link 2:345/678%, @lines) ? $file : undef
                        } @netmailFiles;
$reportPath = catfile($netmailDir, $reportNetmail);
open(FH, "<", $reportPath) or die("Cannot open $reportPath: $!");
$line = <FH>;
close(FH);
@lines = split /\r/, $line;
for(my $i = 0; $i < @lines; $i++)
{
    if($lines[$i] =~ /^\001PID:/)
    {
        splice(@lines, $#lines, 1);
        splice(@lines, 0, $i + 1);
        last;
    }
}
$sampleText = catfile($sampleDir, "20_report.cfg");
open(FH, "<", $sampleText) or die("Cannot open $sampleText: $!");;
@sample = grep {s/\n//} <FH>;
close(FH);
$cmp = 1;
if(@lines != @sample)
{
    $cmp = 0;
    put(6, "Size not equal");
    my $numlines = @lines;
    my $numsample = @sample;
    put(6, "numlines=$numlines  numsample=$numsample");
}
else
{
    for(my $i = 0; $i < @lines; $i++)
    {
        if($lines[$i] ne $sample[$i])
        {
            $cmp = 0;
            put(6, "Line number $i differs from the sample!!!");
            put(6, "Line #$i: $lines[$i]");
            last;
        }
    }
}
is($cmp, 1, "test #5");
# clean
if($cmp == 1)
{
    $files_to_delete = catfile($netmailDir, "*");
    unlink glob($files_to_delete);
}
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($busyFileDir, "*.tic");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($ticOutbound, "*.tic");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($PassFileAreaDir, "*");
$num = unlink glob($files_to_delete);
$files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
rmdir($fileboxname);

END:
done_testing();
