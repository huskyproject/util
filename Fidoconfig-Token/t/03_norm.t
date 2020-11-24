#
# t/03_norm.t
#
use diagnostics;
use warnings;
use strict;
use Test::More;
use Fidoconfig::Token;

eval {normalize("path", "bad");};
like($@, qr/^normalize\(\): extra arguments/, "extra arguments");

if(getOS() ne 'UNIX')
{
    my $path = "C:\\Users/donald/trump.jpg";
    is(normalize($path), "C:\\Users\\donald\\trump.jpg", "normalize");
}
else
{
    pass("normalize");
}
done_testing();
