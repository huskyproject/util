#
# t/10_findByValue.t
#
use diagnostics;
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token qw(:DEFAULT findTokenValue);
use Cwd 'abs_path';
use File::Spec::Functions;

$Fidoconfig::Token::module = "hpt";
$Fidoconfig::Token::commentChar = '#';
my $basedir = catdir(Cwd::abs_path("t"), "fido");
$ENV{BASEDIR} = $basedir;
my $cfgdir = catdir($basedir, "cfg");
$ENV{CFGDIR} = $cfgdir;

# test#1
my $fidoconfig = catfile($cfgdir, "04_findByValue.cfg");
my ($file, $value, $linenum, @lines) = findTokenValue($fidoconfig, "Aka", "eq", "2:5020/4441");
is($linenum, 5, "find AKA#1");

# test#2
$fidoconfig = catfile($cfgdir, "06_findByValue.cfg");
($file, $value, $linenum, @lines) = findTokenValue($fidoconfig, "EchoArea", "=~", qr/robots/i);
is($linenum, 25, "myrobots instead of robots"); # incorrect

# test#3
($file, $value, $linenum, @lines) = findTokenValue($fidoconfig, "EchoArea", "=~", qr/^robots/i);
is($linenum, 26, "robots.loc instead of robots"); # incorrect

# test#4
($file, $value, $linenum, @lines) = findTokenValue($fidoconfig, "EchoArea", "=~", qr/^robots\s/i);
is($linenum, 27, "robots");         # correct line is found
isnt($value, "robots", "robots#1"); # but the value is incorrect

# test#5
($file, $value, $linenum, @lines) = findTokenValue($fidoconfig, "EchoArea", "=~", qr/^(robots)\s/i);
is($linenum, 27, "robots#2");     # correct line and
is($value, "robots", "robots#3"); # correct value

# test#6
my @values;
($file, @values) = findAllTokenValues($fidoconfig, "EchoArea", "robots");
($value) = grep {s/^(robots)\s+.+$/$1/} @values;
is($value, "robots", "robots#4");

done_testing();
