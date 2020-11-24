#
# t/05_expandVars.t
#
use diagnostics;
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token qw(:DEFAULT expandVars);

eval {expandVars("expr", "bad");};
like($@, qr/^expandVars\(\): extra arguments/, "extra arguments");

is(expandVars(undef), undef, "expandVars undefined");
is(expandVars(""), "", "expandVars empty");

# backtics
if(getOS() eq "UNIX" or getOS() eq "OS/2")
{
    is(expandVars(`echo 5`), "5", "expandVars backticks#1");
    is(expandVars("`echo 5`2"), "52", "expandVars backticks#2");
    is(expandVars("2`echo 5`"), "25", "expandVars backticks#3");
    is(expandVars("2`echo 5`3"), "253", "expandVars backticks#4");
    is(expandVars("`echo 7`2`echo 5`3"), "7253", "expandVars backticks#5");
    is(expandVars("`echo 7` 2 `echo 5` 3"), "7 2 5 3", "expandVars backticks#6");
    is(expandVars("7`echo 5"), "7`echo 5", "expandVars backticks#7");
}

$ENV{MYTEST} = "OK";
is(expandVars("[MYTEST]"), "OK", "expandVars env_var#1");
is(expandVars("[MYTEST"), "[MYTEST", "expandVars env_var#2");
is(expandVars("MYTEST]"), "MYTEST]", "expandVars env_var#3");
is(expandVars("NOT_[MYTEST]"), "NOT_OK", "expandVars env_var#4");
is(expandVars("[MYTEST]_NOT"), "OK_NOT", "expandVars env_var#5");
$ENV{ONE}="1";
$ENV{TWO}="2";
is(expandVars("[ONE]_[MYTEST]_[TWO]"), "1_OK_2", "expandVars env_var#6");
$ENV{module} = "hpt";
is(expandVars("[Module]"), "module", "expandVars module#1");

done_testing();
