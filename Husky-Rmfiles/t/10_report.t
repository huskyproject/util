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
use File::Spec::Functions;
use Cwd 'abs_path';
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
    for (1..13)
    {
        my $ticpath = catfile($busyFileDir, createBasename() . ".tic");
        while(-f $ticpath)
        {
            $ticpath = catfile($busyFileDir, createBasename() . ".tic");
        }
        open(FH, ">", "$ticpath") or die("Cannot open $ticpath: $!");
        print FH "To $link\n";
        close(FH);
    }
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
my $basedir = catdir(abs_path("t"), "fido");
$ENV{BASEDIR} = $basedir;
my $cfgdir = catdir($basedir, "cfg");
my $sampleDir = catdir($cfgdir, "sample");
$ENV{CFGDIR} = $cfgdir;
$ENV{MBASEDIR} = catdir($basedir, "msg");
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
@header = ("  ", "$link did not pick up mail for 90 days.",
           "I am deleting all its netmail, echomail and fileechos.", "  ");
@footer = ("", "$link has been removed from 2:5020/1042 configuration files.", "  ");

# test#1
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
my $error;
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$error);
    init();
}
put(7, "###### 10_report.t ######");
put(7, "test#1");
like($error, qr/ReportTo is not defined in your fidoconfig/, "ReportTo is not defined");

# test#2
put(7, "test#2");
$fidoconfig = catfile($cfgdir, "21_report.cfg");
$ENV{FIDOCONFIG} = $fidoconfig;
my $bak = "$fidoconfig" . ".bak";
cp("$fidoconfig", "$bak") or die "Copy to $bak failed: $!";
createBsoMail($outbound, $PassFileAreaDir, $ticOutbound, $busyFileDir, $loname);
createFileboxMail($fileboxname, $loname);
init();
unsubscribeLink();
rmFilesFromOutbound();
rmFilesFromFilebox();
rmOrphanFilesFromPassFileAreaDir();
rmOrphanFilesFromOutbound($outbound, 183);
rmLinkDefinition();
publishReport($subject, $fromname, \@header, \@footer);
opendir(DIR, $netmailDir) or die "Could not open $netmailDir";
my @netmailFiles = grep(/^\d+\.msg$/, readdir(DIR));
closedir(DIR);
my ($reportNetmail) = grep {my $file = $_; open(FH, "<", catfile($netmailDir, $file));
                            my @lines = <FH>; close(FH);
                            grep(/Removing link 2:345\/678/, @lines) ? $file : undef} @netmailFiles;
open(FH, "<", catfile($netmailDir, $reportNetmail));
my $line = <FH>;
close(FH);
my @lines = split /\r/, $line;
for(my $i = 0; $i < @lines; $i++)
{
    if($lines[$i] =~ /\001TID/)
    {
        splice(@lines, $#lines, 1);
        splice(@lines, 0, $i + 1);
    }
}
open(FH, "<", catfile($sampleDir, "20_report.cfg"));
my @sample = grep {s/\n//} <FH>;
close(FH);
my $cmp = 1;
if(@lines != @sample)
{
    $cmp = 0;
    print STDERR "Size not equal\n";
    my $numlines = @lines;
    my $numsample = @sample;
    print STDERR "numlines=$numlines  numsample=$numsample\n";
}
else
{
    for(my $i = 0; $i < @lines; $i++)
    {
        if($lines[$i] ne $sample[$i])
        {
            $cmp = 0;
            print STDERR "i=$i\n";
            last;
        }
    }
}
is($cmp, 1, "test#2");
mv("$bak", "$fidoconfig") or die "Move from $bak failed: $!";
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

done_testing();
