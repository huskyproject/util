#!/usr/bin/perl
#
# Remove all files of a link
#
# Usage:
#           rmLinkMail.pl [options]
# For full usage information run
#           perldoc rmLinkMail.pl
#
# It is free software and license is the same as for Perl,
# see http://dev.perl.org/licenses/
#
use Getopt::Long;
use Fcntl qw(:flock);
use Fidoconfig::Token 2.5;
use File::Basename;
use Husky::Rmfiles 1.10;
use Pod::Usage;
use strict;
use warnings;

our $VERSION = "1.4";

sub version
{
    my $base = basename($0);
    print "$base  version=$VERSION\n";
    print "    uses Fidoconfig::Token v.$Fidoconfig::Token::VERSION\n";
    print "    and  Husky::Rmfiles    v.$Husky::Rmfiles::VERSION\n";
    exit(1);
}

sub usage
{
    pod2usage("-verbose" => 99, "-sections" => "NAME|SYNOPSIS", "-exitval" => 1);
}


# Prevent running another copy of the same script
open(SELF, "< $0") or die "Unable to open the script source: $!\n";
unless(flock(SELF, LOCK_EX | LOCK_NB))
{
    print STDERR "$0 is already running. Exiting.\n";
    exit(2);
}

# Just check that the current OS is supported
getOS();

$quiet = $netmail = $echomail = $fileecho = $otherfile = $filebox = 0;
$log = 1;

$fidoconfig = $ENV{FIDOCONFIG} if defined $ENV{FIDOCONFIG};

Getopt::Long::Configure("auto_abbrev", "gnu_compat", "permute");
GetOptions( 
            "config|c=s"    => \$fidoconfig,
            "bindir=s"      => \$huskyBinDir,
            "address|a=s"   => \$link,
            "netmail|n"     => \$netmail,
            "echomail|e"    => \$echomail,
            "fileecho|f"    => \$fileecho,
            "other-files|o" => \$otherfile,
            "box|b"         => \$filebox,
            "report|r:s"    => \$report,
            "log!"          => \$log,
            "l"             => \$log,
            "quiet!"        => \$quiet,
            "q"             => \$quiet,
            "dry-run!"      => \$dryrun,
            "version|v"     => \&version,
            "help|h"        => \&usage,
          )
or die("Error in command line arguments\n");


if (!(defined($fidoconfig) && -f $fidoconfig && -s $fidoconfig))
{
    print STDERR "\nPlease supply the path to fidoconfig\n\n";
    usage();
}

if(!defined($link))
{
    print STDERR "\nPlease supply the link's FTN address\n\n";
    usage();
}

my $zone = $link =~ m!(\d+):\d+/\d+(?:\.\d+)?!;
if(!defined($zone))
{
    print STDERR "\naddress=$link but it should be zone:net/node or zone:net/node.point\n\n";
    exit 2;
}

$log = "rmLinkMail.log" if($log);

init();
$listterm = $listlog = $listreport = 1;
rmFilesFromOutbound();
rmFilesFromFilebox();
rmOrphanFilesFromPassFileAreaDir();
exit if(!$report);
my ($subject, $fromname, @header, @footer);
$subject = "Removing files of $link";
$fromname = "rmLinkMail Robot";
@header = ("  ");
@footer = ("  ");
publishReport($subject, $fromname, \@header, \@footer);


__END__

=head1 NAME

rmLinkMail.pl - remove netmail, echomail and files of a link

=head1 SYNOPSIS

perl rmLinkMail.pl [options]

  Options:
    --config path         path to fidoconfig
    --bindir directory    the directory holding hpt if it is not in the PATH
    --address ftnAddress  the link address
    --netmail             exclude netmail from the files to be deleted
    --echomail            exclude echomail from the files to be deleted
    --fileecho            exclude fileechomail from the files to be deleted
    --other-files         exclude other files in the link's filebox
    --box                 do not delete an empty filebox
    --report              send a report to the echo or netmail area
    --nolog               do not log anything in the rmLinkMail.log file
    --quiet               do not print to terminal window
    --version             print version and exit
    --help                print help and exit

  To print full documentation run `perldoc rmLinkMail.pl`.

=head1 DESCRIPTION

rmLinkMail.pl removes netmail, echomail and files of the specified link taking
all the necessary information from fidoconfig.

=head1 OPTIONS

All options are case insensitive and their names may be abbreviated to
uniqueness. One may also use single-character option names with one dash
instead of long option names with two dashes.

=over 4

=item B<-c> path

=item B<--config> path

You have to supply full path to fidoconfig here if FIDOCONFIG environment
variable is not defined. Otherwise you may omit the option.

=item B<--bindir> directory

You have to specify the directory where hpt resides if it is not in the PATH.

=item B<-a> ftnAddress

=item B<--address> ftnAddress

The link address, the files of which will be deleted.

=item B<--netmail>

Exclude netmail from the files to be deleted.

=item B<-e>

=item B<--echomail>

Exclude echomail from the files to be deleted.

=item B<-f>

=item B<--fileecho>

Exclude fileechomail from the files to be deleted.

=item B<-o>

=item B<--other-files>

Exclude files in the link's filebox not belonging to netmail, echomail or
fileechomail from the files to be deleted.

=item B<-b>

=item B<--box>

Do not delete an empty filebox. On default the empty filebox is deleted.

=item B<-r> [area]

=item B<--report> [area]

Send a report about the deleted files to the echo or netmail area.

If the name of the area is omitted, then  B<ReportTo> statement
in fidoconfig is used.

If the whole option is omitted, a report will not be sent.

=item B<-l>

=item B<--log>

Log all actions to rmLinkMail.log file if B<LogFileDir> is defined in
fidoconfig. It is not necessary to use it since on default logging is switched
on.

=item B<--nolog>

Do not print anything to rmLinkMail.log file. This option does not influence
printing to terminal window.

=item B<-q>

=item B<--quiet>

=item B<--noquiet>

On default (or when --noquiet option is used), printing to terminal window is
switched on. If the --quiet option is used, the script does not print to the
terminal window. This option does not influence printing
to a log file.

=item B<--dry-run>

=item B<--nodry-run>

If C<--dry-run> is used, perform a trial run with no changes made. Nothing is
deleted, but the same output is produced as in a real run except the error
messages that may appear during the actual run.

=item B<-v>

=item B<--version>

Print the program version and exit

=item B<-h>

=item B<--help>

Print a brief help and exit

=back

=head1 EXIT CODE

If required operation is successfully done, the exit code is 0. If help or
version is printed, the exit code is 1, otherwise it is more than 1.

=head1 RESTRICTION

SeparateBundles keyword in fidoconfig is not supported.

=head1 AUTHOR

Michael Dukelsky 2:5020/1042

=cut
