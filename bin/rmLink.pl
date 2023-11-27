#!/usr/bin/perl
#
# Remove a link from Husky configuration
#
# Usage:
#           rmLink.pl [options]
# For full usage information run
#           perldoc rmLink.pl
#
# It is free software and license is the same as for Perl,
# see http://dev.perl.org/licenses/
#
use Getopt::Long;
use Fcntl qw(:flock);
use Fidoconfig::Token qw(findTokenValue getOS normalize $commentChar);
use File::Basename;
use Husky::Rmfiles qw(init unsubscribeLink rmFilesFromOutbound publishReport
    rmFilesFromFilebox rmOrphanFilesFromPassFileAreaDir rmLinkDefinition
    $fidoconfig $link $delete $backup $report $log $quiet $listterm $listlog
    $listreport $dryrun $huskyBinDir);
use Pod::Usage;
use strict;
use warnings;

our $VERSION = "1.5";

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
    exit(255);
}

# Just check that the current OS is supported
getOS();

# Values on default
$log = 1;
$listlog = 1;
$listterm = 1;

$fidoconfig = $ENV{FIDOCONFIG} if defined $ENV{FIDOCONFIG};
Getopt::Long::Configure("auto_abbrev", "gnu_compat", "permute");
GetOptions( 
            "config|c=s"    => \$fidoconfig,
            "bindir=s"      => \$huskyBinDir,
            "address|a=s"   => \$link,
            "delete!"       => \$delete,
            "d"             => \$delete,
            "backup!"       => \$backup,
            "b"             => \$backup,
            "report:s"      => \$report,
            "log!"          => \$log,
            "quiet!"        => \$quiet,
            "q"             => \$quiet,
            "report-list!"  => \$listreport,
            "log-list!"     => \$listlog,
            "term-list!"    => \$listterm,
            "dry-run!"      => \$dryrun,
            "version|v"     => \&version,
            "help|h"        => \&usage,
          )
or die("Error in command line arguments\n");

my $fatal = 0;
if(!defined($link))
{
    print STDERR "\n#### Please supply the link FTN address ####\n\n";
    $fatal = 1;
}
if (!(defined($fidoconfig) && -f $fidoconfig && -s $fidoconfig))
{
    print STDERR "\n#### Please supply the path to fidoconfig ####\n\n";
    $fatal = 1;
}

my ($hpt, $htick);
if(defined($huskyBinDir) && $huskyBinDir ne "" && -d $huskyBinDir)
{
    $hpt   = normalize(catfile($huskyBinDir, "hpt"));
    $htick = normalize(catfile($huskyBinDir, "htick"));
}
else
{
    $hpt   = "hpt";
    $htick = "htick";
}
if(getOS() ne 'UNIX')
{
    $hpt   .= ".exe";
    $htick .= ".exe";
}
my $hpt_exists = grep(/hpt/,
    eval
    {
        no warnings 'all';
        qx($hpt -h 2>&1)
    }) > 1 ? 1 : 0;
my $htick_exists = grep(/htick/,
    eval
    {
        no warnings 'all';
        qx($htick -h 2>&1)
    }) > 1 ? 1 : 0;
if(!$hpt_exists && !$htick_exists)
{
    print STDERR "\n#### Please supply the directory where hpt and htick reside ####\n\n";
    $fatal = 1;
}

usage() if($fatal);

$log = "rmLink.log" if($log);

init();
unsubscribeLink();
rmFilesFromOutbound();
rmFilesFromFilebox();
rmOrphanFilesFromPassFileAreaDir();
rmLinkDefinition();
my ($subject, $fromname, @header, @footer);
$commentChar = '#';
my ($path, $address) = findTokenValue($fidoconfig, "address");
$subject = "Removing link $link";
$fromname = "rmLink Robot";
@header = ("  ", "$link did not pick up mail for 180 or more days.",
           "I am deleting all his netmail, echomail and file echos.");
@footer = ("$link has been removed from $address configuration files.", " ");
publishReport($subject, $fromname, \@header, \@footer);

__END__

=head1 NAME

rmLink.pl - remove a link

=head1 SYNOPSIS

perl rmLink.pl [options]

  Options:
    --config path         path to fidoconfig
    --bindir directory    the directory holding hpt if it is not in the PATH
    --address ftnAddress  the link address
    --delete              delete the link definition lines instead of
                          commenting them out
    --backup              backup configuration file before changing
    --report [area]       send a report to the echo or netmail area
    --nolog               do not log the actions in the rmLink.log file
    --quiet               do not print to terminal window
    --report-list         include the listing of deleted files in the report
    --nolog-list          do not include the list of deleted files
                          in the log file
    --noterm-list         do not print the list of deleted files to the
                          terminal
    --dry-run             perform a trial run with no changes made
    --version             print version and exit
    --help                print help and exit

  To print full documentation run `perldoc rmLink.pl`.

=head1 DESCRIPTION

rmLink.pl unsubscribes the specified link from all echos and file echos,
removes netmail, echomail and files intended for the link taking all the
necessary information from fidoconfig and comments out or deletes the lines of
the link definition.

=head1 OPTIONS

All options are case insensitive and their names may be abbreviated to
uniqueness. One may also use single-character option names with one dash
instead of long option names with two dashes for some options.

=over 4

=item B<-c> path

=item B<--config> path

You have to supply full path to fidoconfig here if FIDOCONFIG environment
variable is not defined. Otherwise you may omit the option.

=item B<--bindir> directory

You have to specify the directory where hpt resides if it is not in the PATH.

=item B<-a> ftnAddress

=item B<--address> ftnAddress

The address of the link which will be deleted.

=item B<-d>

=item B<--delete>

=item B<--nodelete>

On default (or when --nodelete is used), the link definition is commented out.
If --delete option is used, the link definition is deleted.

=item B<-b>

=item B<--backup>

=item B<--nobackup>

On default (or when --nobackup is used), the configuration file is not backed
up before deleting link definition from it.  If the --backup option is used, a
backup of the configuration file with the link definition is made with the .bak
filename extension.

=item B<--report> [area]

Send a report about deleting the link to the echo or netmail area.

If the name of the area is omitted, then  B<ReportTo> statement
in fidoconfig is used to define the area to send report to.

If the whole option is omitted, a report will not be sent. This option does not
influence printing to the log file or to the terminal.

=item B<--log>

=item B<--nolog>

On default (or when --log option is used), logging to rmLink.log is switched
on. If the --nolog option is used, the script does not print anything to the
log file. This option does not influence sending a report or printing to
terminal window. The rmLink.log file is created in the directory defined by
B<logFileDir> statement in fidoconfig. If the statement is absent, there is no
logging even when --log option is used.

=item B<-q>

=item B<--quiet>

=item B<--noquiet>

On default (or when --noquiet option is used), printing to terminal window is
switched on. If the --quiet option is used, the script does not print to the
terminal window. This option does not influence sending a report or printing
to a log file.

=item B<--report-list>

=item B<--noreport-list>

On default (or when --noreport-list is used), the list of deleted files is
excluded from the report. Please use --report-list if you want to include
the list of deleted files in the report.

=item B<--log-list>

=item B<--nolog-list>

On default (or when --log-list is used), the list of deleted files is included
in the log file. Please use --nolog-list if you want to exclude the list of
deleted files from the log file.

=item B<--term-list>

=item B<--noterm-list>

On default (or when --term-list is used), the list of deleted files is printed
to the terminal window. Please use --nolog-list if you do not want to print the
list of deleted files to the terminal window.

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

If the required operation is successfully done, the exit code is 0. If help is
printed, the exit code is 1, otherwise it is more than 1.

=head1 RESTRICTION

SeparateBundles keyword in fidoconfig is not supported.

=head1 AUTHOR

Michael Dukelsky 2:5020/1042

=cut
