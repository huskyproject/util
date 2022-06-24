#
# t/06_cmpPattern.t
#
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token qw(:DEFAULT cmpPattern);

eval {cmpPattern("string", "pattern", "bad");};
like($@, qr/^cmpPattern\(\): extra arguments/, "extra arguments");

eval {cmpPattern(undef, "pattern");};
like($@, qr/^cmpPattern\(\): string not defined/, "string not defined");

eval {cmpPattern("string", undef);};
like($@, qr/^cmpPattern\(\): pattern not defined/, "pattern not defined");

my $string = "";
is(cmpPattern($string, ""), 1, "cmp with empty");
is(cmpPattern($string, "0"), "", "cmp with zero");
is(cmpPattern($string, "3"), "", "cmp with digit");
$string = "?";
is(cmpPattern($string, "\?"), 1, "cmp with question mark#1");
is(cmpPattern($string, "?"), 1, "cmp with question mark#2");
$string = "aBc qwerty dEg";
is(cmpPattern($string, "a?c*d?g"), 1, "cmp with template#1");
is(cmpPattern($string, "*d?g"), 1, "cmp with template#2");
is(cmpPattern($string, "a?c*"), 1, "cmp with template#3");

done_testing();
