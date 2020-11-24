#
# t/02_OS.t
#
use diagnostics;
use warnings;
use strict;
use Test::More;

# $OS is not supported
my $OS = $^O;
$OS = $Config::Config{'osname'} if(!defined($OS));
if ($OS =~ /^VMS/i or $OS =~ /^MacOS/i or $OS =~ /^epoc/i or $OS =~ /NetWare/i)
{
    plan skip_all => '$OS is not supported';
    BAIL_OUT("Sorry, cannot continue with $OS");
}
else
{
    unlike($OS, qr/^VMS/i, "It is not VMS");
    unlike($OS, qr/^MacOS/i, "It is not MacOS");
    unlike($OS, qr/^epoc/i, "It is not epoc");
    unlike($OS, qr/^NetWare/i, "It is not NetWare");
}
done_testing();

