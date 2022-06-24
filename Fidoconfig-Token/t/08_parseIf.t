#
# t/08_parseIf.t
#
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token qw(:DEFAULT parseIf);

eval {parseIf("line", "bad");};
like($@, qr/^parseIf\(\): extra arguments/, "extra arguments");

$Fidoconfig::Token::commentChar = '#';
my $line;

# Test #1
my $test = 1;
$module = "hpt";
my @lines = ('if [module] == hpt', 'Robot Areafix', 'else', 'Robot Filefix', 'endif');
my $i = 0;
for $line (@lines)
{
    $i++;
    if($i != 2)
    {
        is(parseIf($line), 1, "test#$test skip line $i");
    }
    else
    {
        is(parseIf($line), 0, "test#$test don't skip line $i");
    }
}

# Test #2
$test = 2;
$module = "htick";
@lines = ('if [module] == hpt', 'Robot Areafix', 'else', 'Robot Filefix', 'endif');
$i = 0;
for $line (@lines)
{
    $i++;
    if($i != 4)
    {
        is(parseIf($line), 1, "test#$test skip line $i");
    }
    else
    {
        is(parseIf($line), 0, "test#$test don't skip line $i");
    }
}

# Test #3
$test = 3;
$ENV{LOGDIR} = "/home/user/fido/log";
@lines = ('ifdef [LOGDIR]', 'LogFileDir [LOGDIR]', 'endif');
$i = 0;
for $line (@lines)
{
    $i++;
    if($i != 2)
    {
        is(parseIf($line), 1, "test#$test skip line $i");
    }
    else
    {
        is(parseIf($line), 0, "test#$test don't skip line $i");
    }
}

# Test #4
$test = 4;
$ENV{LOGDIR} = "";
@lines = ('ifdef [LOGDIR]', 'LogFileDir [LOGDIR]', 'endif');
$i = 0;
for $line (@lines)
{
    $i++;
    is(parseIf($line), 1, "test#$test skip line $i");
}

# Test #5
$test = 5;
$ENV{LOGDIR} = "/home/user/fido/log";
@lines = ('ifndef [LOGDIR]', 'LogFileDir [LOGDIR]', 'endif');
$i = 0;
for $line (@lines)
{
    $i++;
    is(parseIf($line), 1, "test#$test skip line $i");
}

# Test #6
$test = 6;
$ENV{LOGDIR} = "";
@lines = ('ifndef [LOGDIR]', 'LogFileDir [LOGDIR]', 'endif');
$i = 0;
for $line (@lines)
{
    $i++;
    if($i != 2)
    {
        is(parseIf($line), 1, "test#$test skip line $i");
    }
    else
    {
        is(parseIf($line), 0, "test#$test don't skip line $i");
    }
}

# Test #7
$test = 7;
$module = "htick";
@lines = ('if [module] == hpt', 'Robot Areafix', 'elseif [module] == htick', 'Robot Filefix', 'endif');
$i = 0;
for $line (@lines)
{
    $i++;
    if($i != 4)
    {
        is(parseIf($line), 1, "test#$test skip line $i");
    }
    else
    {
        is(parseIf($line), 0, "test#$test don't skip line $i");
    }
}

# Test #8
$test = 8;
$module = "htick";
@lines = ('if [module] == hpt', 'Robot Areafix', 'elif [module] == htick', 'Robot Filefix', 'endif');
$i = 0;
for $line (@lines)
{
    $i++;
    if($i != 4)
    {
        is(parseIf($line), 1, "test#$test skip line $i");
    }
    else
    {
        is(parseIf($line), 0, "test#$test don't skip line $i");
    }
}

# Test #9
$test = 9;
$module = "tparser";
@lines = ('if [module] == hpt', 'Robot Areafix', 'elseif [module] == htick', 'Robot Filefix', 'endif');
$i = 0;
for $line (@lines)
{
    $i++;
    is(parseIf($line), 1, "test#$test skip line $i");
}

# Test #10
$test = 10;
$module = "tparser";
@lines = ('if [module] == hpt', 'Robot Areafix', 'elif [module] == htick', 'Robot Filefix', 'endif');
$i = 0;
for $line (@lines)
{
    $i++;
    is(parseIf($line), 1, "test#$test skip line $i");
}

done_testing();
