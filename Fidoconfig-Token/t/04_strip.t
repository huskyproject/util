#
# t/04_strip.t
#
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token;

# stripSpaces()
my @arr = stripSpaces(undef);
is($arr[0], undef, "stripSpaces from undef");
@arr = stripSpaces("");
is($arr[0], "", "stripSpaces from empty string");
@arr = stripSpaces("word");
is($arr[0], "word", "no spaces to strip");
@arr = stripSpaces("    first word  ");
is($arr[0], "first word", "stripSpaces");
@arr = stripSpaces("	first word		");
is($arr[0], "first word", "strip tabs");
@arr = stripSpaces("\n\rfirst word\r\n");
is($arr[0], "first word", "strip 0x0A and 0x0D");
@arr = stripSpaces("", "    first word  ", "\n Wow! \r");
is($arr[0], "", "stripSpaces from array #1");
is($arr[1], "first word", "stripSpaces from array #2");
is($arr[2], "Wow!", "stripSpaces from array #3");

# stripQuotes()
@arr = stripQuotes(undef);
is($arr[0], undef, "stripQuotes from undef");
@arr = stripQuotes("");
is($arr[0], "", "stripQuotes from empty string");
@arr = stripQuotes("word");
is($arr[0], "word", "no quotes to strip");
@arr = stripQuotes("\"first word\"");
is($arr[0], "first word", "stripQuotes");
@arr = stripQuotes("\"first word");
isnt($arr[0], "first word", "strip initial quote");
@arr = stripQuotes("first word\"");
isnt($arr[0], "first word", "strip ending quote");
@arr = stripQuotes("\'first word\'");
isnt($arr[0], "first word", "strip single quotes");
@arr = stripQuotes("\"one\"", "\"two\"", "\"three\"");
is($arr[0], "one", "stripQuotes from array #1");
is($arr[1], "two", "stripQuotes from array #2");
is($arr[2], "three", "stripQuotes from array #3");

# stripComment
$commentChar = '#';
@arr = stripComment(undef);
is($arr[0], undef, "stripComment from undef");
@arr = stripComment("");
is($arr[0], "", "stripComment from empty string");
@arr = stripComment("word");
is($arr[0], "word", "no comments to strip");
@arr = stripComment("code	 # a long comment");
is($arr[0], "code	", "stripComment from end of a line");
@arr = stripComment("	 	# a long comment");
is($arr[0], "", "stripComment from beginning of a line");
$commentChar = ';';
@arr = stripComment("code	 ; a long comment");
is($arr[0], "code	", "strip ';'-based comment from end of line");
@arr = stripComment("	 	; a long comment");
is($arr[0], "", "strip ';'-based comment from beginning of a line");

done_testing();
