#
# A script for testing Husky::Rmfiles
# t/03_init.t
#
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token;
use Husky::Rmfiles;
use File::Spec::Functions;
use Cwd 'abs_path';
use 5.008;

$huskyBinDir = $ENV{HUSKYBINDIR};

$ENV{FIDOCONFIG} = undef;
eval {init()};
like($@, qr/^Please supply the path to fidoconfig/, "path to fidoconfig");

my $cfgdir = normalize(catdir(Cwd::abs_path("t"), "fido", "cfg"));
if(getOS() eq "UNIX")
{
    $fidoconfig = catfile($cfgdir, "01_init.cfg");
}
else
{
    $fidoconfig = normalize(catfile($cfgdir, "01w_init.cfg"));
}

eval {init()};
like($@, qr/^Please supply the link\'s FTN address/, "link FTN address");

eval {Husky::Rmfiles::init("nolink");};
is($@, "", "no link FTN address");

$link = "1:23/456";
$log = "rmLink.log";
eval {init()};
if(getOS() eq "UNIX")
{
    like($@, qr%^Cannot open /home/user8CTpbI97/fido/log/rmLink.log%, "wrong LogFileDir");
}
else
{
    like($@, qr%^Cannot open C:\\Users\\user8CTpbI97\\fido\\log\\rmLink.log%, "wrong LogFileDir");
}

$log = undef;
$ENV{BASEDIR} = "/home/user8CTpbI97/fido";
is(init(), 1, "init runs");

$report = "";

my $errors;
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$errors);
    init();
}
like($errors, qr/ReportTo is not defined in your fidoconfig/, "empty ReportTo");

$fidoconfig = catfile($cfgdir, "02a_init.cfg");
$report = "";
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$errors);
    eval{init()};
}
like($errors, qr/Cannot find either echo or netmail area/, "echo not found");

$report = undef;
$fidoconfig = catfile($cfgdir, "02_init.cfg");
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$errors);
    eval{init()};
}
like($errors, qr/SeparateBundles mode is not supported/, "SeparateBundles");

$fidoconfig = catfile($cfgdir, "03_init.cfg");
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$errors);
    eval{init()};
}
like($errors, qr/advisoryLock should be a non-negative integer/, "advisoryLock");

$fidoconfig = catfile($cfgdir, "04_init.cfg");
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$errors);
    eval{init()};
}
like($errors, qr/advisoryLock should be a non-negative integer/, "advisoryLock on");

$fidoconfig = catfile($cfgdir, "05_init.cfg");
$link = "5020/1042";
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$errors);
    eval{init()};
}
like($errors, qr!but it should be zone:net/node!, "incorrect link address#1");

$link = "2:5020";
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$errors);
    eval{init()};
}
like($errors, qr!but it should be zone:net/node!, "incorrect link address#2");

$link = "/1042.1";
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$errors);
    eval{init()};
}
like($errors, qr!but it should be zone:net/node!, "incorrect link address#3");

$fidoconfig = catfile($cfgdir, "06_init.cfg");
$link = "1:23/456";
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$errors);
    eval{init()};
}
like($errors, qr/Your FTN address is not defined/, "incorrect system address");

$fidoconfig = catfile($cfgdir, "07_init.cfg");
$link = "1:23/456";
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$errors);
    eval{init()};
}
like($errors, qr!fileBoxesDir \'/home/user8CTpbI97/fido/boxes\' is not a directory!, "incorrect fileBoxesDir");

$fidoconfig = catfile($cfgdir, "08_init.cfg");
$link = "1:23/456";
{
    # redirect STDERR to a variable locally inside the block
    open(local(*STDERR), '>', \$errors);
    eval{init()};
}
like($errors, qr/Outbound is not defined/, "Outbound not defined");

END:
done_testing();
