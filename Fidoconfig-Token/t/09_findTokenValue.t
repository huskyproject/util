#
# t/09_findTokenValue.t
#
use diagnostics;
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token 2.3 qw(:DEFAULT findTokenValue);
use Cwd 'abs_path';
use File::Spec;

$Fidoconfig::Token::module = "hpt";
$Fidoconfig::Token::commentChar = '#';
my $basedir = File::Spec->catdir(Cwd::abs_path("t"), "fido");
$ENV{BASEDIR} = $basedir;
my $cfgdir = File::Spec->catdir($basedir, "cfg");
$ENV{CFGDIR} = $cfgdir;

eval {findTokenValue("tokenFile", "token", "mode", "desiredValue", "bad");};
like($@, qr/^findTokenValue\(\): extra arguments/, "extra arguments");

eval {findTokenValue("tokenFile", "token", "mode");};
like($@, qr/^findTokenValue\(\): the fourth argument is not defined/, "desiredValue not defined");

my $fidoconfig = File::Spec->catfile($cfgdir, "01_findTokenValue.cfg");
my ($file, $value) = findTokenValue($fidoconfig, "ProtInbound");
like($value, qr%/in/inbound%, "env var#1");
is($file, $fidoconfig, "env var#2");

$Fidoconfig::Token::commentChar = '#';
($file, $value) = findTokenValue($fidoconfig, "ROBOT");
is($value, "AreaFix", "if#1");
is(normalize($file), normalize(File::Spec->catfile($cfgdir, "02_findTokenValue.cfg")), "if#2");

$Fidoconfig::Token::commentChar = '#';
$Fidoconfig::Token::module = "htick";
($file, $value) = findTokenValue($fidoconfig, "roBOT");
is($value, "FileFix", "if#3");
is(normalize($file), normalize(File::Spec->catfile($cfgdir, "03_findTokenValue.cfg")), "if#4");

$Fidoconfig::Token::commentChar = '#';
($file, $value) = findTokenValue($fidoconfig, "KillRequests");
is($value, "on", "empty value#1");
is(normalize($file), normalize(File::Spec->catfile($cfgdir, "03_findTokenValue.cfg")), "empty value#2");

$Fidoconfig::Token::commentChar = '#';
($file, $value) = findTokenValue($fidoconfig, "FileAreaCreatePerms");
is($value, "", "token not found#1");
is($file, $fidoconfig, "token not found#2");

$Fidoconfig::Token::commentChar = '#';
$Fidoconfig::Token::module = "hpt";
($file, $value) = findTokenValue($fidoconfig, "AdvStatisticsFile");
like($value, qr%log/hpt.sta$%, "set#1");
is(normalize($file), normalize(File::Spec->catfile($cfgdir, "02_findTokenValue.cfg")), "set#2");

$Fidoconfig::Token::commentChar = '#';
($file, $value) = findTokenValue($fidoconfig, "HelpFile");
like($value, qr%/etc/husky/areafix.hlp$%, "set#3");
is(normalize($file), normalize(File::Spec->catfile($cfgdir, "02_findTokenValue.cfg")), "set#4");

$Fidoconfig::Token::commentChar = '#';
($file, $value) = findTokenValue($fidoconfig, "HptPerlFile");
like($value, qr%/filter.pl$%, "set#4");
is(normalize($file), normalize(File::Spec->catfile($cfgdir, "02_findTokenValue.cfg")), "set#5");

$Fidoconfig::Token::commentChar = '#';
$Fidoconfig::Token::module = "hpt";
($file, $value) = findTokenValue($fidoconfig, "FileBoxesDir");
like($value, qr%fido/out/boxes$%, "commentChar#1");
is($file, $fidoconfig, "commentChar#2");

# commentChar has been changed by previous test
($file, $value) = findTokenValue($fidoconfig, "MsgBaseDir");
isnt($value, "passthrough", "bad comment#1");
is($file, $fidoconfig, "bad comment#2");

$fidoconfig = File::Spec->catfile($cfgdir, "07_findTokenValue.cfg");
$Fidoconfig::Token::commentChar = '#';
($file, $value) = findTokenValue($fidoconfig, "AdvisoryLock");
is($value, "on", "wrong AdvisoryLock#1");

$Fidoconfig::Token::valueType = "integer";
($file, $value) = findTokenValue($fidoconfig, "AdvisoryLock");
$Fidoconfig::Token::valueType = undef;
is($value, "yes", "wrong AdvisoryLock#2");

$fidoconfig = File::Spec->catfile($cfgdir, "08_findTokenValue.cfg");
($file, $value) = findTokenValue($fidoconfig, "AdvisoryLock");
is($value, "on", "wrong result since valueType was not specified");

$Fidoconfig::Token::valueType = "integer";
($file, $value) = findTokenValue($fidoconfig, "AdvisoryLock");
is($value, "1", "correct AdvisoryLock value");

done_testing();
