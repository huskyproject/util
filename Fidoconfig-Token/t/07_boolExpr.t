#
# t/07_boolExpr.t
#
use diagnostics;
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token qw(:DEFAULT boolExpr);

eval {boolExpr("expr", "bad");};
like($@, qr/^boolExpr\(\): extra arguments/, "extra arguments");

$module = "hpt";
is(boolExpr("  module  ==  hpt  "), "1", "module==hpt");
isnt(boolExpr("  module  ==  htick  "), "1", "module==htick");
is(boolExpr("  hpt  ==  module  "), "1", "hpt==module");
isnt(boolExpr("  htick  ==  module  "), "1", "htick==module");
is(boolExpr("  hpt  ==  hpt  "), "1", "hpt==hpt");
isnt(boolExpr("  htick  ==  hpt  "), "1", "htick==hpt");
is(boolExpr("  hpt  !=  htick  "), "1", "hpt!=htick");
isnt(boolExpr("  hpt  !=  hpt  "), "1", "hpt!=hpt");
is(boolExpr("  aBc qwerty dEg  =~  a?c*d?g  "), "1", "expression=~template");
isnt(boolExpr("  aBc qwerty dEg  =~  ak?c*d?g  "), "1", "expression=~template2");
is(boolExpr("  aBc qwerty dEg  !~  ak?c*d?g  "), "1", "expression!~template");
isnt(boolExpr("  aBc qwerty dEg  !~  a?c*d?g  "), "1", "expression!~template2");

is(boolExpr(" not  module  ==  hpt  "), "", "not module==hpt");
is(boolExpr(" not  module  ==  htick  "), "1", "not module==htick");

done_testing();
