#!/usr/bin/perl
#
# fixOutbound.pl
#
use Getopt::Long;
use Pod::Usage;
use Config;
use Cwd 'abs_path';
use File::Spec::Functions;
use Fcntl qw(:flock);
use Fidoconfig::Token 2.4;
use Husky::Rmfiles 1.6;
use strict;
use warnings;

our $VERSION = "1.2";

sub version
{
    use File::Basename;
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
my $age = 183;  # 183 days
$log = 1;
$listlog = 1;
$listterm = 1;
$dryrun = 0;
$fidoconfig = $ENV{FIDOCONFIG} if defined $ENV{FIDOCONFIG};

my $help;
$help = 1 unless(@ARGV);

Getopt::Long::Configure("auto_abbrev", "gnu_compat", "permute");
GetOptions(
            "config=s"      => \$fidoconfig,
            "age=i"         => \$age,
            "report:s"      => \$report,
            "log!"          => \$log,
            "quiet!"        => \$quiet,
            "report-list!"  => \$listreport,
            "log-list!"     => \$listlog,
            "term-list!"    => \$listterm,
            "dry-run!"      => \$dryrun,
            "version"       => \&version,
            "help"          => \$help,
          )
or die("Error in command line arguments\n");

usage() if($help);

if (!(defined($fidoconfig) && -f $fidoconfig && -s $fidoconfig))
{
    print STDERR "\nPlease supply the path to fidoconfig\n\n";
    usage();
}

if($age < 0)
{
    print STDERR "\nThe \"age\" argument must be a non-negative integer\n\n";
    usage();
}
$age = int($age);

$log = "fixOutbound.log" if($log);

init("nolink");
# Default outbound
$commentChar = '#';
my ($path, $defOutbound) = findTokenValue($fidoconfig, "Outbound");
lastError("Outbound is not defined") if(!$defOutbound);
lastError("Outbound does not exist") if(! -d $defOutbound);
$defOutbound = abs_path($defOutbound);

my @dirs = File::Spec->splitdir($defOutbound);
lastError("One cannot use root directory as outbound!") if($#dirs == 1);
my $last = $dirs[$#dirs];
$#dirs--;
my $parent = catdir(@dirs);
lastError("Cannot open $parent directory ($!)") if(!opendir(DIR, $parent));
@dirs = grep(/^$last/i, readdir(DIR));
closedir(DIR);
for(my $i = $#dirs; $i >= 0; $i--)
{
    my $fulldir = catdir($parent, $dirs[$i]);
    if(! -d $fulldir)
    {
        splice(@dirs, $i, 1);
        next;
    }
    lastError("Cannot open $fulldir directory ($!)") if(!opendir(DIR, $fulldir));
    my @points = grep(/^[0-9a-f]{8}\.pnt/i, readdir(DIR));
    closedir(DIR);
    $dirs[$i] = $fulldir;
    splice @dirs, $i + 1, 0, grep {-d $_} map {catdir($fulldir, $_)} @points;
}

for my $outbound (@dirs)
{
    rmOrphanFilesFromOutbound($outbound, $age);
}

__END__

=head1 NAME

 fixOutbound.pl - remove from outbound the echomail bundles not referred by any
                  flow file

=head1 SYNOPSIS

perl fixOutbound.pl [options]

  Options:
    --config path           path to fidoconfig
    --age lower_limit       truncated bundles older than lower_limit days
                            will be deleted
    --report [area]         send a report to the echo or netmail area
    --nolog                 do not log the actions in the fixOutbound.log file
    --quiet                 do not print to terminal window
    --noreport-list         exclude the listing of deleted files from the
                            report
    --nolog-list            do not include the list of deleted files
                            in the log file
    --noterm-list           do not print the list of deleted files to the
                            terminal
    --dry-run               a trial run with no changes made
    --version               print version and exit
    --help                  print help and exit

  To view full documentation run `perldoc fixOutbound.pl`.

=head1 DESCRIPTION

The script removes from the outbound the echomail bundles not referred by any
flow file (AKA orphan files). Echomail bundles may become orphan as a result
of erroneous manual deleting files from outbound or after software or hardware
crashes. Orphan echomail bundles truncated by tosser to zero length as a result
of normal processing are also deleted.

=head1 OPTIONS

All options are case insensitive and their names may be abbreviated to
uniqueness. One may also use single-character option names with one dash
instead of long option names with two dashes for some options.

=over 4

=item B<-c> path

=item B<--config> path

You have to supply full path to fidoconfig here if FIDOCONFIG environment
variable is not defined. Otherwise you may omit the option.

=item B<-a> lower_limit

=item B<--age> lower_limit

Here C<lower_limit> is a non-negative integer. All truncated to zero length
echomail bundles older than C<lower_limit> days will be deleted. If you omit
the option, the default value of 183 days (half a year) is used.

=item B<--report> [area]

Send a report about deleting the orphan files to the echo or netmail area.

If the name of the area is omitted, then  B<ReportTo> statement
in fidoconfig is used to define the area to send report to.

If the whole option is omitted, a report will not be sent. This option does not
influence printing to the log file or to the terminal.

=item B<--log>

=item B<--nolog>

On default (or when --log option is used), logging to fixOutbound.log is
switched on. If the --nolog option is used, the script does not print anything
to the log file. This option does not influence sending a report or printing to
terminal window. The fixOutbound.log file is created in the directory defined
by B<logFileDir> statement in fidoconfig. If the statement is absent, there is
no logging even when --log option is used.

=item B<-q>

=item B<--quiet>

=item B<--noquiet>

On default (or when --noquiet option is used), printing to terminal window is
switched on. If the --quiet option is used, the script does not print to the
terminal window. This option does not influence sending a report or printing
to a log file.

=item B<--report-list>

=item B<--noreport-list>

On default (or when --report-list is used), the list of deleted files is
included in the report. Please use --noreport-list if you want to exclude
the list of deleted files from the report.

=item B<--log-list>

=item B<--nolog-list>

On default (or when --log-list is used), the list of deleted files is
included in the log file. Please use --nolog-list if you want to exclude
the list of deleted files from the log file.

=item B<--term-list>

=item B<--noterm-list>

On default (or when --term-list is used), the list of deleted files is
printed to the terminal window. Please use --nolog-list if you do not want
to print the list of deleted files to the terminal window.

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
printed, the exit code is 1, otherwise it is 255.

=head1 RESTRICTION

SeparateBundles keyword in fidoconfig is not supported.

=head1 AUTHOR

Michael Dukelsky 2:5020/1042

=cut
