#
# A script for testing Husky::Rmfiles
# t/06_rmFilesFromFilebox.t
#
use diagnostics;
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token 2.0;
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
        my $filename = createBasename().".rar";
        my $filepath = catfile($filebox, $filename);
        while(-f $filepath)
        {
            $filename = createBasename().".rar";
            $filepath = catfile($filebox, $filename);
        }
        createFile($filepath);
    }
}

$ENV{FIDOCONFIG} = undef;
my $basedir = normalize(catdir(abs_path("t"), "fido"));
$ENV{BASEDIR} = $basedir;
my $cfgdir = normalize(catdir($basedir, "cfg"));
$ENV{MBASEDIR} = normalize(catdir($basedir, "msg"));
$log = "rmLink.log";
$listterm = 1;
$listlog = 1;
my $fileBoxesDir = normalize(catdir($basedir, "out", "boxes"));
$huskyBinDir = $ENV{HUSKYBINDIR};

# test#1
$fidoconfig = normalize(catfile($cfgdir, "12_rmFiles.cfg"));
$link = "2:345/678";
my $fileboxname = normalize(catdir($fileBoxesDir, "2.345.678.0"));
if(-d $fileboxname)
{
    my $files_to_delete = catfile($fileboxname, "*");
    unlink glob($files_to_delete);
    rmdir($fileboxname) or die("Cannot delete directory $fileboxname: $!");
}
$fileboxname = catdir($fileBoxesDir, "2.345.678.0.h");
if(-d $fileboxname)
{
    my $files_to_delete = catfile($fileboxname, "*");
    unlink glob($files_to_delete);
    rmdir($fileboxname) or die("Cannot delete directory $fileboxname: $!");
}
$fileboxname = catdir($fileBoxesDir, "2.345.678.0.H");
if(-d $fileboxname)
{
    my $files_to_delete = catfile($fileboxname, "*");
    unlink glob($files_to_delete);
    rmdir($fileboxname) or die("Cannot delete directory $fileboxname: $!");
}
init();
put(6, "###### 06_rmFilesFromFilebox.t ######");
put(6, "test#1");
my $out;
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
like($out, qr%^There is no filebox for 2:345/678%, "no filebox");

# test#2
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "2:345/678";
init();
put(6, "test#2");
$filebox = 0;
$fileboxname = catdir($fileBoxesDir, "2.345.678.0");
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
my @lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0/, @lines), 1, "test#2 Header");
my $num = grep(/^\S+ deleted$/, @lines);
is($num, 23, "filebox 2.345.678.0");
is(grep(/^Filebox 2.345.678.0 was deleted/, @lines), 1, "test#2 Footer");
ok(! -d $fileboxname, "test#2 filebox deleted");

# test#2dry
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "2:345/678";
init();
put(6, "test#2dry");
$dryrun = 1;
$filebox = 0;
$fileboxname = catdir($fileBoxesDir, "2.345.678.0");
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0/, @lines), 1, "test#2dry Header");
$num = grep(/^\S+ deleted$/, @lines);
is($num, 23, "test#2dry filebox 2.345.678.0");
is(grep(/^Filebox 2.345.678.0 was deleted/, @lines), 1, "test#2dry Footer");
ok(-d $fileboxname, "test#2dry filebox not deleted");
#clean
my $files_to_del = catfile($fileboxname, "*");
unlink glob($files_to_del);
rmdir($fileboxname);
$dryrun = undef;

# test#3
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "2:345/678";
init();
put(6, "test#3");
$filebox = 1;
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0/, @lines), 1, "test#3 Header");
$num = grep(/^\S+ deleted$/, @lines);
is($num, 23, "test#3 filebox 2.345.678.0");
ok(-d $fileboxname, "test#3 filebox not deleted");
# clean
$files_to_del = catfile($fileboxname, "*");
unlink glob($files_to_del);
rmdir($fileboxname);

# test#3dry
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
init();
put(6, "test#3dry");
$dryrun = 1;
$filebox = 1;
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0/, @lines), 1, "test#3dry Header");
$num = grep(/^\S+ deleted$/, @lines);
is($num, 23, "test#3dry filebox 2.345.678.0");
ok(-d $fileboxname, "test#3dry filebox not deleted");
my $files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
is($num, 23, "test#3dry remained");
rmdir($fileboxname);
ok(! -d $fileboxname, "test#3dry filebox deleted");
# clean
$files_to_del = catfile($fileboxname, "*");
unlink glob($files_to_del);
rmdir($fileboxname);
$dryrun = undef;

# test#4 hold flavour
init();
put(6, "test#4 hold flavour");
$filebox = 0;
$fileboxname = catdir($fileBoxesDir, "2.345.678.0.H");
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0.H/, @lines), 1, "test#4 Header");
$num = grep(/^\S+ deleted$/, @lines);
is($num, 23, "test#4 filebox 2.345.678.0.H");
is(grep(/^Filebox 2.345.678.0.H was deleted/, @lines), 1, "test#4 Footer");
ok(! -d $fileboxname, "test#4 filebox deleted");

# test#5
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
init();
put(6, "test#5");
$fileboxname = normalize(catdir($fileBoxesDir, "2.345.678.0"));
mkdir($fileboxname);
my $zip = normalize(catfile($fileboxname, createBasename().".zip"));
createFile($zip);
if(getOS() eq "UNIX")
{
    chmod(0555, $fileboxname);
}
else
{
    my @cmd = ("attrib", "+R", "\"$fileboxname\"");
    (system(@cmd) >> 8) == 0 or die("system(\"@cmd\") failed: $!");
}
my $error;
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$error);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $error);
is(grep(/Could not delete /, @lines), 1, "Cannot delete file");

if(getOS() eq "UNIX")
{
    chmod(0775, $fileboxname);
}
else
{
    my @cmd = ("attrib", "-R", "\"$fileboxname\"");
    (system(@cmd) >> 8) == 0 or die("system(\"@cmd\") failed: $!");
}
unlink $zip;
rmdir($fileboxname);
ok(! -d $fileboxname, "test#5 filebox deleted");

# test#6
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
init();
put(6, "test#6");
$netmail = 1;
$fileboxname = catdir($fileBoxesDir, "2.345.678.0");
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0/, @lines), 1, "test#6 Header");
$num = grep(/^\S+ deleted$/, @lines);
is($num, 20, "test#6 filebox 2.345.678.0");
is(grep(/^Filebox \S+2.345.678.0 deleted/, @lines), 0, "test#6 Footer");
# Clean
$files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
is($num, 3, "test#6 remained");
rmdir($fileboxname);
ok(! -d $fileboxname, "test#6 filebox deleted");
$netmail = 0;

# test#6dry
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
init();
put(6, "test#6dry");
$dryrun = 1;
$netmail = 1;
$fileboxname = catdir($fileBoxesDir, "2.345.678.0");
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0/, @lines), 1, "test#6dry Header");
$num = grep(/^\S+ deleted$/, @lines);
is($num, 20, "test#6dry filebox 2.345.678.0");
is(grep(/^Filebox \S+2.345.678.0 deleted/, @lines), 0, "test#6dry Footer");
# Clean
$files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
is($num, 23, "test#6dry remained");
rmdir($fileboxname);
ok(! -d $fileboxname, "test#6dry filebox deleted");
$netmail = 0;
$dryrun = undef;

# test#7
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
init();
put(6, "test#7");
$echomail = 1;
$fileboxname = catdir($fileBoxesDir, "2.345.678.0");
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0/, @lines), 1, "test#7 Header");
$num = grep(/^\S+ deleted$/, @lines);
is($num, 14, "test#7 filebox 2.345.678.0");
is(grep(/^Filebox \S+2.345.678.0 deleted/, @lines), 0, "test#7 Footer");
# Clean
$files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
is($num, 9, "test#7 remained");
rmdir($fileboxname);
ok(! -d $fileboxname, "test#7 filebox deleted");
$echomail = 0;

# test#7dry
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
init();
put(6, "test#7dry");
$dryrun = 1;
$echomail = 1;
$fileboxname = catdir($fileBoxesDir, "2.345.678.0");
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0/, @lines), 1, "test#7dry Header");
$num = grep(/^\S+ deleted$/, @lines);
is($num, 14, "test#7dry filebox 2.345.678.0");
is(grep(/^Filebox \S+2.345.678.0 deleted/, @lines), 0, "test#7dry Footer");
# Clean
$files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
is($num, 23, "test#7dry remained");
rmdir($fileboxname);
ok(! -d $fileboxname, "test#7 filebox deleted");
$echomail = 0;
$dryrun = undef;

# test#8
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
init();
put(6, "test#8");
$fileecho = 1;
$fileboxname = catdir($fileBoxesDir, "2.345.678.0");
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0/, @lines), 1, "test#8 Header");
$num = grep(/^\S+\.hut deleted$/, @lines);
is($num, 1, "test#8 netmail");
$num = grep(/^\S+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/, @lines);
is($num, 7, "test#8 echomail");
is(grep(/^Filebox \S+2.345.678.0 deleted/, @lines), 0, "test#8 Footer");
$num = grep(/^\S+\.rar deleted$/, @lines);
is($num, 3, "test#8 otherfiles");
# Clean
$files_to_delete = catfile($fileboxname, "*.zip");
$num = unlink glob($files_to_delete);
is($num, 5, "test#8 zip");
$files_to_delete = catfile($fileboxname, "*.tic");
$num = unlink glob($files_to_delete);
is($num, 5, "test#8 tics");
$files_to_delete = catfile($fileboxname, "*.try");
$num = unlink glob($files_to_delete);
is($num, 1, "test#8 .try");
$files_to_delete = catfile($fileboxname, "*.hld");
$num = unlink glob($files_to_delete);
is($num, 1, "test#8 .hld");
$files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
is($num, 0, "test#8 remained");
rmdir($fileboxname);
ok(! -d $fileboxname, "test#8 filebox deleted");
$fileecho = 0;

# test#8dry
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
init();
put(6, "test#8dry");
$dryrun = 1;
$fileecho = 1;
$fileboxname = catdir($fileBoxesDir, "2.345.678.0");
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0/, @lines), 1, "test#8dry Header");
$num = grep(/^\S+\.hut deleted$/, @lines);
is($num, 1, "test#8dry netmail");
$num = grep(/^\S+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/, @lines);
is($num, 7, "test#8dry echomail");
is(grep(/^Filebox \S+2.345.678.0 deleted/, @lines), 0, "test#8 Footer");
$num = grep(/^\S+\.rar deleted$/, @lines);
is($num, 3, "test#8dry otherfiles");
# Clean
$files_to_delete = catfile($fileboxname, "*.zip");
$num = unlink glob($files_to_delete);
is($num, 5, "test#8dry zip");
$files_to_delete = catfile($fileboxname, "*.tic");
$num = unlink glob($files_to_delete);
is($num, 5, "test#8dry tics");
$files_to_delete = catfile($fileboxname, "*.try");
$num = unlink glob($files_to_delete);
is($num, 1, "test#8dry .try");
$files_to_delete = catfile($fileboxname, "*.hld");
$num = unlink glob($files_to_delete);
is($num, 1, "test#8dry .hld");
$files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
is($num, 11, "test#8dry remained");
rmdir($fileboxname);
ok(! -d $fileboxname, "test#8 filebox deleted");
$fileecho = 0;
$dryrun = undef;

# test#9
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
init();
put(6, "test#9");
$otherfile = 1;
$fileboxname = catdir($fileBoxesDir, "2.345.678.0");
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0/, @lines), 1, "test#9 Header");
$num = grep(/^\S+ deleted$/, @lines);
is($num, 18, "test#9 filebox 2.345.678.0");
is(grep(/^Filebox \S+2.345.678.0 deleted/, @lines), 0, "test#9 Footer");
# Clean
$files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
is($num, 5, "test#9 remained");
rmdir($fileboxname);
ok(! -d $fileboxname, "test#9 filebox deleted");
$otherfile = 0;

# test#9dry
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
init();
put(6, "test#9dry");
$dryrun = 1;
$otherfile = 1;
$fileboxname = catdir($fileBoxesDir, "2.345.678.0");
createFileboxMail($fileboxname, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromFilebox();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting files from filebox 2.345.678.0/, @lines), 1, "test#9dry Header");
$num = grep(/^\S+ deleted$/, @lines);
is($num, 18, "test#9dry filebox 2.345.678.0");
is(grep(/^Filebox \S+2.345.678.0 deleted/, @lines), 0, "test#9dry Footer");
# Clean
$files_to_delete = catfile($fileboxname, "*");
$num = unlink glob($files_to_delete);
is($num, 23, "test#9dry remained");
rmdir($fileboxname);
ok(! -d $fileboxname, "test#9dry filebox deleted");
$otherfile = 0;
$dryrun = undef;

done_testing();
