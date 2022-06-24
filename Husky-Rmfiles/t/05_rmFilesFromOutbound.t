#
# A script for testing Husky::Rmfiles
# t/05_rmFilesFromOutbound.t
#
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token 2.0;
use Husky::Rmfiles;
use File::Spec::Functions;
use Cwd 'abs_path';
use File::Copy;
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
sub createAsoMail
{
    my ($outbound, $basename) = @_;
    my $files_to_delete = catfile($outbound, "*");
    unlink glob($files_to_delete);
    createFile(catfile($outbound, "$basename.hut"));
    my $hlo = catfile($outbound, "$basename.hlo");
    createFile($hlo);
    for (1..20)
    {
        my $filename = "$basename." . createExt(\@weekday, (0..9, 'a'..'z'));
        my $filepath = catfile($outbound, $filename);
        while(-f $filepath)
        {
            $filename = "$basename." . createExt(\@weekday, (0..9, 'a'..'z'));
            $filepath = catfile($outbound, $filename);
        }
        createFile($filepath);
        open(FH, ">>", "$hlo") or die("Cannot open $hlo: $!");
        print FH "#$filepath\n";
        close(FH);
    }
}

sub createBsoMail
{
    my ($outbound, $ticOutbound, $busyFileDir, $loname) = @_;
    my $files_to_delete = catfile($busyFileDir, "*.[tT][iI][cC]");
    unlink glob($files_to_delete);
    if(!-d $outbound)
    {
        mkdir($outbound) or die("Cannot create $outbound: $!");
    }
    $files_to_delete = catfile($outbound, "*");
    unlink glob($files_to_delete);
    $files_to_delete = catfile($ticOutbound, "*");
    unlink glob($files_to_delete);
    my $notUsedDir = catdir($outbound, "notused");
    if(-d $notUsedDir)
    {
        $files_to_delete = catfile($notUsedDir, "*");
        unlink glob($files_to_delete);
    }
    else
    {
        mkdir($notUsedDir) or die("Cannot create $notUsedDir: $!");
    }
    mkdir($busyFileDir) or die("Cannot create $busyFileDir: $!") if(!-d $busyFileDir);
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
        copy($filepath, catfile($notUsedDir, $filename));
        open(FH, ">>", "$hlo") or die("Cannot open $hlo: $!");
        print FH "#$filepath\n";
        close(FH);
        copy($hlo, catfile($notUsedDir, "$loname.hlo"));
    }
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
    }
    for (1..5)
    {
        my $filename = createBasename() . ".TIC";
        my $filepath = catfile($ticOutbound, $filename);
        while(-f $filepath)
        {
            $filename = createBasename() . ".TIC";
            $filepath = catfile($ticOutbound, $filename);
        }
        createFile($filepath);
        open(FH, ">>", "$hlo") or die("Cannot open $hlo: $!");
        print FH "^$filepath\n";
        close(FH);
    }
    for (1..11)
    {
        my $filename = createBasename() . ".TIC";
        my $filepath = catfile($ticOutbound, $filename);
        while(-f $filepath)
        {
            $filename = createBasename() . ".TIC";
            $filepath = catfile($ticOutbound, $filename);
        }
        createFile($filepath);
    }
    for (1..13)
    {
        my $filename = createBasename() . ".TIC";
        my $filepath = catfile($busyFileDir, $filename);
        while(-f $filepath)
        {
            $filename = createBasename() . ".TIC";
            $filepath = catfile($busyFileDir, $filename);
        }
        open(FH, ">", "$filepath") or die("Cannot open $filepath: $!");
        print FH "To $link\n";
        close(FH);
    }
    for (1..3)
    {
        my $filename = createBasename() . ".TIC";
        my $filepath = catfile($busyFileDir, $filename);
        while(-f $filepath)
        {
            $filename = createBasename() . ".TIC";
            $filepath = catfile($busyFileDir, $filename);
        }
        open(FH, ">", "$filepath") or die("Cannot open $filepath: $!");
        print FH "To 1:2/3.456\n";
        close(FH);
    }
    # Empty file
    my $filename = createBasename() . ".TIC";
    my $filepath = catfile($busyFileDir, $filename);
    while(-f $filepath)
    {
        $filename = createBasename() . ".TIC";
        $filepath = catfile($busyFileDir, $filename);
    }
    createFile($filepath);
}

sub isDirEmpty
{
    my $dir = shift;
    return 2 if(! -d $dir);
    opendir(DIR, $dir) or die("Cannot opendir $dir: $!");
    my @files = grep(-f catfile($dir, $_), readdir(DIR));
    closedir(DIR);
    return 0 if(@files);
    return 1;
}

$ENV{FIDOCONFIG} = undef;
my $basedir = catdir(abs_path("t"), "fido");
$ENV{BASEDIR} = $basedir;
my $cfgdir = catdir($basedir, "cfg");
$ENV{MBASEDIR} = catdir($basedir, "msg");
my $outbound =  catdir($basedir, "out", "outbound");
my $busyFileDir = catdir($outbound, "busy.htk");
my $outbound1 =  catdir($basedir, "out", "outbound.001");
my $passFileAreaDir = catdir($basedir, "pass");
my $ticOutbound = catdir($basedir, "out", "tic");
$log = "rmLink.log";
$listterm = 1;
$listlog = 1;
$huskyBinDir = $ENV{HUSKYBINDIR};

# test#1
$fidoconfig = catfile($cfgdir, "11_rmFiles.cfg");
$link = "1:23/456.666";
init();
put(6, "###### 05_rmFilesFromOutbound.t ######");
put(6, "test#1");
my $error;
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$error);
    rmFilesFromOutbound();
}
like($error, qr/^Outbound directory \S+ does not exist$/, "Outbound does not exist#1");

# test#2
#$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
#$link = "3:23/456";
#init();
#{
#    # redirect STDERR to a variable locally inside the block
#    open(local(*STDERR), '>', \$error);
#    rmFilesFromOutbound();
#}
#like($error, qr/^The outbound directory \S+ does not exist$/, "Outbound does not exist#2");

# test#3
#$link = "2:5020/1042.666";
#init();
#{
#    # redirect STDERR to a variable locally inside the block
#    open(local(*STDERR), '>', \$error);
#    rmFilesFromOutbound();
#}
#like($error, qr/^Directory \S+ does not exist$/, "Outbound does not exist#3");

# test#4
$fidoconfig = catfile($cfgdir, "13_rmFiles.cfg");
$link = "1:23/456.666";
init();
put(6, "test#4");
# create netmail and echomail in ASO outbound for testing
createAsoMail($outbound, "1.23.456.666");
my $out;
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
my @lines = split(/\n/, $out);
is(grep(/^Deleting echomail and tics from outbound/, @lines), 1, "ASO#1");
my $num = grep(/^\S+ deleted$/, @lines);
is($num, 22, "ASO#1 echomail and flow files");
# Clean outbound
my $files_to_delete = catfile($outbound, "*");
unlink glob($files_to_delete);

# test#4dry
put(6, "test#4dry");
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "13_rmFiles.cfg");
$link = "1:23/456.666";
init();
# create netmail and echomail in ASO outbound for testing
createAsoMail($outbound, "1.23.456.666");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
is(grep(/^Deleting echomail and tics from outbound/, @lines), 1, "ASO#1dry");
$num = grep(/^\S+ deleted$/, @lines);
is($num, 22, "ASO#1dry echomail and flow files");
# Clean outbound
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 22, "ASO#1dry remained");
$dryrun = undef;

# test#5
put(6, "test#5");
$fidoconfig = catfile($cfgdir, "13_rmFiles.cfg");
$link = "1:23/456.666";
init();
# create netmail and echomail in ASO outbound for testing
createAsoMail($outbound, "1.23.456.666");
createFile(catfile($outbound, "1.23.456.666.bsy"));
eval
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$error);
    rmFilesFromOutbound();
};
like($@, qr/If the busy flag is stale/, "ASO#2");
# Clean outbound
$files_to_delete = catfile($outbound, "*");
unlink glob($files_to_delete);

# test#6
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "2:345/678";
init();
put(6, "test#6");
# create netmail, echomail in default outbound and tics for testing
createBsoMail($outbound, $passFileAreaDir, $busyFileDir, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
$num = grep(/^.+\.hut deleted$/i, @lines);
is($num, 1, "BSO#1 netmail");
$num = grep(/^.+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/i, @lines);
is($num, 7, "BSO#1 echomail");
$num = grep(/^.+\.tic deleted$/i, @lines);
is($num, 18, "BSO#1 tic");
is(isDirEmpty($busyFileDir), 0, "BSO#1 BusyFileDir not empty");
$num = grep(/^.+\.hlo deleted$/i, @lines);
is($num, 1, "BSO#1 lo");
$num = grep(/^.+\.(?:try|hld) deleted$/i, @lines);
is($num, 2, "BSO#1 try, hld");
# Clean the rest
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 4, "BSO#1 remained in BusyFileDir");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 9, "BSO#1 remained in outbound");
$files_to_delete = catfile($passFileAreaDir, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 11, "BSO#1 remained in ticOutbound");
my $notUsedDir = catdir($outbound, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#1 files in notused directory");

# test#6dry
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "2:345/678";
init();
put(6, "test#6dry");
# create netmail, echomail in default outbound and tics for testing
createBsoMail($outbound, $passFileAreaDir, $busyFileDir, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
$num = grep(/^\S+\.hut deleted$/i, @lines);
is($num, 1, "BSO#1dry netmail");
$num = grep(/^.+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/i, @lines);
is($num, 7, "BSO#1dry echomail");
$num = grep(/^.+\.tic deleted$/i, @lines);
is($num, 18, "BSO#1dry tic");
is(isDirEmpty($busyFileDir), 0, "BSO#1 BusyFileDir not empty");
$num = grep(/^\S+\.hlo deleted$/i, @lines);
is($num, 1, "BSO#1dry lo");
$num = grep(/^\S+\.(?:try|hld) deleted$/i, @lines);
is($num, 2, "BSO#1 try, hld");
# Clean the rest
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 17, "BSO#1dry remained in BusyFileDir");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 20, "BSO#1dry remained in outbound");
$files_to_delete = catfile($passFileAreaDir, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 16, "BSO#1dry remained in ticOutbound");
$dryrun = undef;
$notUsedDir = catdir($outbound, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#1 files in notused directory");

# test#7
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "1:23/456";
init();
put(6, "test#7");
# create netmail and echomail in non-default outbound for testing
createBsoMail($outbound1, $passFileAreaDir, $busyFileDir, "001701c8");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
$num = grep(/^\S+\.hut deleted$/, @lines);
is($num, 1, "BSO#2 netmail");
$num = grep(/^.+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/i, @lines);
is($num, 7, "BSO#2 echomail");
$num = grep(/\.tic deleted$/i, @lines);
is($num, 18, "BSO#2 tic");
$num = grep(/^\S+\.hlo deleted$/, @lines);
is($num, 1, "BSO#2 lo");
$num = grep(/^\S+\.(?:try|hld) deleted$/, @lines);
is($num, 2, "BSO#2 try, hld");
# Clean outbound
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 4, "BSO#2 remained in BusyFileDir");
$files_to_delete = catfile($outbound1, "*");
$num = unlink glob($files_to_delete);
is($num, 9, "BSO#2 remained in outbound");
$files_to_delete = catfile($passFileAreaDir, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 11, "BSO#2 remained in ticOutbound");
$notUsedDir = catdir($outbound1, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#2 files in notused directory");

# test#7dry
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "1:23/456";
init();
put(6, "test#7dry");
# create netmail and echomail in non-default outbound for testing
createBsoMail($outbound1, $passFileAreaDir, $busyFileDir, "001701c8");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
$num = grep(/^\S+\.hut deleted$/, @lines);
is($num, 1, "BSO#2dry netmail");
$num = grep(/^.+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/i, @lines);
is($num, 7, "BSO#2dry echomail");
$num = grep(/\.tic deleted$/i, @lines);
is($num, 18, "BSO#2dry tic");
$num = grep(/^\S+\.hlo deleted$/, @lines);
is($num, 1, "BSO#2dry lo");
$num = grep(/^\S+\.(?:try|hld) deleted$/, @lines);
is($num, 2, "BSO#2dry try, hld");
# Clean outbound
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 17, "BSO#2dry remained in BusyFileDir");
$files_to_delete = catfile($outbound1, "*");
$num = unlink glob($files_to_delete);
is($num, 20, "BSO#2dry remained in outbound");
$files_to_delete = catfile($passFileAreaDir, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 16, "BSO#2dry remained in ticOutbound");
$notUsedDir = catdir($outbound1, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#2dry files in notused directory");
$dryrun = undef;

# test#8
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "1:23/456";
init();
put(6, "test#8");
# create netmail and echomail in non-default outbound for testing
createBsoMail($outbound1, $passFileAreaDir, $busyFileDir, "001701c8");
createFile(catfile($outbound1, "001701c8.bsy"));
# Run rmFilesFromOutbound()
eval
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$error);
    rmFilesFromOutbound();
};
like($@, qr/If the busy flag is stale/, "BSO#3");
# Clean outbound
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 17, "BSO#3 remained in BusyFileDir");
$files_to_delete = catfile($outbound1, "*");
$num = unlink glob($files_to_delete);
is($num, 21, "BSO#3 remained in outbound");
$files_to_delete = catfile($passFileAreaDir, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 16, "BSO#3 remained in ticOutbound");
$notUsedDir = catdir($outbound1, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#3 files in notused directory");

# test#9
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "2:345/678";
$netmail = 1;
init();
put(6, "test#9");
# create netmail, echomail in default outbound and tics for testing
createBsoMail($outbound, $passFileAreaDir, $busyFileDir, "015902a6");
# Run rmFilesFromOutbound()
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
$num = grep(/^\S+\.hut deleted$/, @lines);
is($num, 0, "BSO#4 netmail");
$num = grep(/^.+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/i, @lines);
is($num, 7, "BSO#4 echomail");
$num = grep(/\.tic deleted$/i, @lines);
is($num, 18, "BSO#4 tic");
$num = grep(/^\S+\.hlo deleted$/, @lines);
is($num, 1, "BSO#4 lo");
$num = grep(/^\S+\.(?:try|hld) deleted$/, @lines);
is($num, 0, "BSO#4 try, hld");
# Clean the rest
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 4, "BSO#4 remained in BusyFileDir");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 12, "BSO#4 remained in outbound");
$files_to_delete = catfile($passFileAreaDir, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 11, "BSO#4 remained in ticOutbound");
$notUsedDir = catdir($outbound, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#4 files in notused directory");
$netmail = 0;

# test#9dry
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "2:345/678";
$netmail = 1;
init();
put(6, "test#9dry");
# create netmail, echomail in default outbound and tics for testing
createBsoMail($outbound, $passFileAreaDir, $busyFileDir, "015902a6");
# Run rmFilesFromOutbound()
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
$num = grep(/^\S+\.hut deleted$/, @lines);
is($num, 0, "BSO#4dry netmail");
$num = grep(/^.+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/i, @lines);
is($num, 7, "BSO#4dry echomail");
$num = grep(/\.tic deleted$/i, @lines);
is($num, 18, "BSO#4dry tic");
$num = grep(/^\S+\.hlo deleted$/, @lines);
is($num, 1, "BSO#4dry lo");
$num = grep(/^\S+\.(?:try|hld) deleted$/, @lines);
is($num, 0, "BSO#4dry try, hld");
# Clean the rest
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 17, "BSO#4dry remained in BusyFileDir");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 20, "BSO#4dry remained in outbound");
$files_to_delete = catfile($passFileAreaDir, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 16, "BSO#4dry remained in ticOutbound");
$notUsedDir = catdir($outbound, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#4dry files in notused directory");
$netmail = 0;
$dryrun = undef;

# test#10
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "2:345/678";
$echomail = 1;
init();
put(6, "test#10");
# create netmail, echomail in default outbound and tics for testing
createBsoMail($outbound, $passFileAreaDir, $busyFileDir, "015902a6");
# Run rmFilesFromOutbound()
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
$num = grep(/^\S+\.hut deleted$/, @lines);
is($num, 1, "BSO#5 netmail");
$num = grep(/^.+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/i, @lines);
is($num, 0, "BSO#5 echomail");
$num = grep(/\.tic deleted$/i, @lines);
is($num, 18, "BSO#5 tic");
$num = grep(/^\S+\.hlo deleted$/, @lines);
is($num, 0, "BSO#5 lo");
$num = grep(/^\S+\.(?:try|hld) deleted$/, @lines);
is($num, 0, "BSO#5 try, hld");
# Clean the rest
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 4, "BSO#5 remained in BusyFileDir");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 19, "BSO#5 remained in outbound");
$files_to_delete = catfile($passFileAreaDir, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 11, "BSO#5 remained in ticOutbound");
$notUsedDir = catdir($outbound, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#5 files in notused directory");
$echomail = 0;

# test#10dry
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "2:345/678";
$echomail = 1;
init();
put(6, "test#10dry");
# create netmail, echomail in default outbound and tics for testing
createBsoMail($outbound, $passFileAreaDir, $busyFileDir, "015902a6");
# Run rmFilesFromOutbound()
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
$num = grep(/^\S+\.hut deleted$/, @lines);
is($num, 1, "BSO#5dry netmail");
$num = grep(/^.+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/i, @lines);
is($num, 0, "BSO#5dry echomail");
$num = grep(/\.tic deleted$/i, @lines);
is($num, 18, "BSO#5dry tic");
$num = grep(/^\S+\.hlo deleted$/, @lines);
is($num, 0, "BSO#5dry lo");
$num = grep(/^\S+\.(?:try|hld) deleted$/, @lines);
is($num, 0, "BSO#5dry try, hld");
# Clean the rest
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 17, "BSO#5dry remained in BusyFileDir");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 20, "BSO#5dry remained in outbound");
$files_to_delete = catfile($passFileAreaDir, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 16, "BSO#5dry remained in ticOutbound");
$notUsedDir = catdir($outbound, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#5dry files in notused directory");
$echomail = 0;
$dryrun = undef;

# test#11
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "2:345/678";
$fileecho = 1;
init();
put(6, "test#11");
# create netmail, echomail in default outbound and tics for testing
createBsoMail($outbound, $passFileAreaDir, $busyFileDir, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
$num = grep(/^\S+\.hut deleted$/, @lines);
is($num, 1, "BSO#6 netmail");
$num = grep(/^.+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/i, @lines);
is($num, 7, "BSO#6 echomail");
$num = grep(/^.+\.tic deleted$/i, @lines);
is($num, 0, "BSO#6 tic");
$num = grep(/^\S+\.hlo deleted$/, @lines);
is($num, 0, "BSO#6 lo");
$num = grep(/^\S+\.(?:try|hld) deleted$/, @lines);
is($num, 0, "BSO#6 try, hld");
# Clean the rest
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 17, "BSO#2 remained in BusyFileDir");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 12, "BSO#6 remained in outbound");
$files_to_delete = catfile($passFileAreaDir, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 16, "BSO#6 remained in ticOutbound");
$notUsedDir = catdir($outbound, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#6 files in notused directory");
$fileecho = 0;

# test#11dry
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "12_rmFiles.cfg");
$link = "2:345/678";
$fileecho = 1;
init();
put(6, "test#11dry");
# create netmail, echomail in default outbound and tics for testing
createBsoMail($outbound, $passFileAreaDir, $busyFileDir, "015902a6");
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
$num = grep(/^\S+\.hut deleted$/, @lines);
is($num, 1, "BSO#6dry netmail");
$num = grep(/^.+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/i, @lines);
is($num, 7, "BSO#6dry echomail");
$num = grep(/^.+\.tic deleted$/i, @lines);
is($num, 0, "BSO#6dry tic");
$num = grep(/^\S+\.hlo deleted$/, @lines);
is($num, 0, "BSO#6dry lo");
$num = grep(/^\S+\.(?:try|hld) deleted$/, @lines);
is($num, 0, "BSO#6dry try, hld");
# Clean the rest
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 17, "BSO#6dry remained in BusyFileDir");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 20, "BSO#6dry remained in outbound");
$files_to_delete = catfile($passFileAreaDir, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 16, "BSO#6dry remained in ticOutbound");
$notUsedDir = catdir($outbound, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#6 files in notused directory");
$fileecho = 0;
$dryrun = undef;

# test#12
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
$link = "2:345/678";
init();
put(6, "test#12");
# create netmail, echomail in default outbound and tics for testing
createBsoMail($outbound, $ticOutbound, $busyFileDir, "015902a6");
# Run rmFilesFromOutbound()
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
$num = grep(/^\S+\.hut deleted$/, @lines);
is($num, 1, "BSO#7 netmail");
$num = grep(/^.+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/i, @lines);
is($num, 7, "BSO#7 echomail");
$num = grep(/\.tic deleted$/i, @lines);
is($num, 18, "BSO#7 tic");
$num = grep(/^\S+\.hlo deleted$/, @lines);
is($num, 1, "BSO#7 lo");
$num = grep(/^\S+\.(?:try|hld) deleted$/, @lines);
is($num, 2, "BSO#7 try, hld");
# Clean the rest
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 4, "BSO#7 remained in BusyFileDir");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 9, "BSO#7 remained in outbound");
$files_to_delete = catfile($ticOutbound, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 11, "BSO#7 remained in ticOutbound");
$notUsedDir = catdir($outbound, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#7 files in notused directory");

# test#12dry
$dryrun = 1;
$fidoconfig = catfile($cfgdir, "14_rmFiles.cfg");
$link = "2:345/678";
init();
put(6, "test#12dry");
# create netmail, echomail in default outbound and tics for testing
createBsoMail($outbound, $ticOutbound, $busyFileDir, "015902a6");
# Run rmFilesFromOutbound()
{
    # redirect STDOUT to a variable locally inside the block
    open(local(*STDOUT), '>', \$out);
    rmFilesFromOutbound();
}
@lines = split(/\n/, $out);
$num = grep(/^\S+\.hut deleted$/, @lines);
is($num, 1, "BSO#7dry netmail");
$num = grep(/^.+\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z] deleted$/i, @lines);
is($num, 7, "BSO#7dry echomail");
$num = grep(/\.tic deleted$/i, @lines);
is($num, 18, "BSO#7dry tic");
$num = grep(/^\S+\.hlo deleted$/, @lines);
is($num, 1, "BSO#7dry lo");
$num = grep(/^\S+\.(?:try|hld) deleted$/, @lines);
is($num, 2, "BSO#7dry try, hld");
# Clean the rest
$files_to_delete = catfile($busyFileDir, "*");
$num = unlink glob($files_to_delete);
is($num, 17, "BSO#7dry remained in BusyFileDir");
$files_to_delete = catfile($outbound, "*");
$num = unlink glob($files_to_delete);
is($num, 20, "BSO#7dry remained in outbound");
$files_to_delete = catfile($ticOutbound, "*.[tT][iI][cC]");
$num = unlink glob($files_to_delete);
is($num, 16, "BSO#7dry remained in ticOutbound");
$notUsedDir = catdir($outbound, "notused");
$files_to_delete = catfile($notUsedDir, "*");
$num = unlink glob($files_to_delete);
is($num, 8, "BSO#7 files in notused directory");
$dryrun = undef;


done_testing();
