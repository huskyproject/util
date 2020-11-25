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
use Pod::Usage;
use Fcntl qw(:flock);
use File::Find qw/&find/;
use File::Spec;
use Config;
use File::Basename;
use Fidoconfig::Token 1.5;
use Husky::Rmfiles;
use Data::Dumper::Simple as => 'display', autowarn => 1;
use strict;
use warnings;

#
##### There is nothing to change below this line #####

our (
     $loname, $flowFile, @filesToRemove, $fileBoxesDir, $zone, $net, $node,
     $point, $box, $boxh, $boxH, $fileboxname, $logfile, $lockFile,
     $debuglog, $filebox, $advisoryLock, $fh, $lh, $dh, $asoname, $VERSION,
     $debug);
my ($fidoconfig, $defZone, $defOutbound, $link);
$debug = $quiet = $netmail = $echomail = $fileecho = $otherfile = $filebox = 0;
$log = 1;

$VERSION = 1.1;

sub usage
{
    pod2usage("-verbose" => 99, "-sections" => "NAME|SYNOPSIS", "-exitval" => 1);
}

sub finish
{
    my $exitCode = shift;
    close($lh) if($log != 0);
    if($debug == 1 && defined($dh))
    {
        *STDERR = *OLD_STDERR;
        close($dh);
    }
    exit $exitCode;
}

###################### The main program starts here ##########################


# Prevent running another copy of the same script
open(SELF, "< $0") or die "Unable to open the script source: $!\n";
unless(flock(SELF, LOCK_EX | LOCK_NB))
{
    print STDERR "$0 is already running. Exiting.\n";
    exit(2);
}

# Just check that the current OS is supported
getOS();


$fidoconfig = $ENV{FIDOCONFIG} if defined $ENV{FIDOCONFIG};

Getopt::Long::Configure("auto_abbrev", "gnu_compat", "permute");
GetOptions( 
            "config=s"  => \$fidoconfig,
            "address=s" => \$link,
            "n"         => \$netmail,
            "netmail"   => \$netmail,
            "echomail"  => \$echomail,
            "fileecho"  => \$fileecho,
            "other-files"=>\$otherfile,
            "box"       => \$filebox,
            "report:s"  => \$report,
            "log!"      => \$log,
            "quiet"     => \$quiet,
            "debug"     => \$debug,
            "help"      => \&usage,
          )
or die("Error in command line arguments\n");

if($debug == 1)
{
    display($debug);
    display($fidoconfig) if(defined($fidoconfig));
    display($link) if(defined($link));
    display($netmail);
    display($echomail);
    display($fileecho);
    display($filebox);
    display($report) if(defined($report));
    display($log) if(defined($log));
    display($quiet) if(defined($log));
}

if (!(defined($fidoconfig) && -f $fidoconfig && -s $fidoconfig))
{
    print STDERR "\nPlease supply the path to fidoconfig\n\n";
    usage();
}

if(!defined($link))
{
    print STDERR "\nPlease supply the link FTN address\n\n";
    usage();
}

($zone, $net, $node, $point) = $link =~ m!(\d+):(\d+)/(\d+)(?:\.(\d+))?!;
if(!defined($zone))
{
    print STDERR "\naddress=$link but it should be zone:net/node or zone:net/node.point\n\n";
    exit 2;
}
$point = 0 if(!defined($point));

my ($address, $path, $logfileDir);
$fidoconfig = normalize($fidoconfig);

$Husky::Fidoconfig::module = "hpt";

if($log != 0)
{
    $Husky::Fidoconfig::commentChar = '#';
    ($path, $logfileDir) = findTokenValue($fidoconfig, "LogFileDir");
    $logfileDir = expandVars($logfileDir) if($logfileDir ne "");
    $logfile = ($logfileDir eq "") ? "" : File::Spec->catfile($logfileDir, "rmLinkMail.log");
    if($logfile ne "")
    {
        if(!open($lh, ">>", $logfile))
        {
            print STDERR "Cannot open $logfile\n";
            exit(2);
        }
        if($debug == 1)
        {
            $debuglog = ($logfileDir eq "") ? "" : File::Spec->catfile($logfileDir, "rmLinkMail_debug.log");
            if(!open($dh, ">>", $debuglog))
            {
                print STDERR "Cannot open $debuglog\n";
                exit(2);
            }
            *OLD_STDERR = *STDERR;
            *STDERR = $dh;
        }
    }
}

if(defined($report) && $report eq "")
{
    # fetch ReportTo from fidoconfig
    $Husky::Fidoconfig::commentChar = '#';
    ($path, $report) = findTokenValue($fidoconfig, "ReportTo");
    if($report eq "no")
    {
        $report = "";
        error("ReportTo is not defined in your fidoconfig; no report will be issued.");
    }
}

my $separateBundles;
$Husky::Fidoconfig::commentChar = '#';
($path, $separateBundles) = findTokenValue($fidoconfig, "SeparateBundles");
if(isOn($separateBundles))
{
    error("SeparateBundles mode is not supported");
    finish(2);
}

$Husky::Fidoconfig::commentChar = '#';
($path, $address) = findTokenValue($fidoconfig, "address");
$defZone = $1 if($address ne "" && $address =~ /^(\d+):\d+\/\d+(?:\.\d+)?(?:@\w+)?$/);
if(!defined($defZone))
{
    error("Your FTN address is not defined or has a syntax error");
    finish(2);
}

$Husky::Fidoconfig::commentChar = '#';
($path, $fileBoxesDir) = findTokenValue($fidoconfig, "FileBoxesDir");
if($fileBoxesDir ne "")
{
    if(! -d $fileBoxesDir)
    {
        error("fileBoxesDir \'$fileBoxesDir\' is not a directory");
        finish(2);
    }
    $fileBoxesDir = normalize($fileBoxesDir);
}

# Default outbound
$Husky::Fidoconfig::commentChar = '#';
($path, $defOutbound) = findTokenValue($fidoconfig, "Outbound");
if($defOutbound eq "")
{
    error("Outbound is not defined");
    finish(2);
}

my $outbound;
if(! -d $defOutbound)
{
    error("Outbound directory $defOutbound does not exist");
}
else
{
    $defOutbound = normalize($defOutbound);

    # Enumerate ASO files to delete
    $asoname = "$zone.$net.$node.$point";
    find(\&getAsoFileToRemove, $defOutbound);

    # Flow filename
    $loname = sprintf("%04x%04x", $net, $node);
    # Outbound hex extension
    my $hexzone = sprintf("%03x", $zone);
    $outbound = ($zone != $defZone) ? "$defOutbound.$hexzone" : $defOutbound;
    if(! -d $outbound)
    {
        error("Outbound directory $outbound does not exist");
    }
    else
    {
        my $outboundExists = 1;
        if($point != 0)
        {
            $outbound = File::Spec->catdir($outbound,  $loname . ".pnt");
            $loname = sprintf("%08x", $point);
            if(! -d $outbound)
            {
                $outboundExists = 0;
                error("Directory $outbound does not exist");
            }
        }

        if($outboundExists == 1)
        {
            # Remove files from $outbound
            find(\&getFlowFile, $outbound);
            rmFilesFromLo($flowFile) if(defined($flowFile) && $flowFile ne "" && -f $flowFile);

            find(\&getFileToRemove, $outbound);
        }

        for my $file (@filesToRemove)
        {
            my $num = unlink $file;
            if($num == 1)
            {
                put("$file deleted");
            }
            else
            {
                error("Cannot delete $file");
            }
        }
    }
}

# Remove files from filebox
rmFilesFromFilebox() if($fileBoxesDir ne "");

# Remove files without tics (AKA widow files) from passFileAreaDir
# (tics are taken either from passFileAreaDir or from ticOutbound)
my $passFileAreaDir;
$Husky::Fidoconfig::module = "htick";
$Husky::Fidoconfig::commentChar = '#';
($path, $passFileAreaDir) = findTokenValue($fidoconfig, "passFileAreaDir");

if($passFileAreaDir ne "" && -d $passFileAreaDir)
{
    my $ticOutbound;
    ($path, $ticOutbound) = findTokenValue($fidoconfig, "ticOutbound");
    display($ticOutbound) if($debug == 1);
    my $ticDir = ($ticOutbound ne "" && -d $ticOutbound) ? $ticOutbound : $passFileAreaDir;
    display($ticDir) if($debug == 1);

    if(!opendir(DIR, $passFileAreaDir))
    {
        error("Can't open $passFileAreaDir directory ($!)");
        finish(2);
    }
    my @files = grep(-f File::Spec->catfile($passFileAreaDir, $_) && !/\.tic$/, readdir(DIR));
    closedir(DIR);
    display(@files) if($debug == 1);

    if(!opendir(DIR, $ticDir))
    {
        error("Can't open $ticDir directory ($!)");
        finish(2);
    }
    my @tics = grep(/\.tic$/, readdir(DIR));
    closedir(DIR);
    display(@tics) if($debug == 1);

    my %filenames;
    foreach my $ticname (@tics)
    {
        my $ticpath = File::Spec->catfile($ticDir, $ticname);
        display($ticpath) if($debug == 1);
        if(!open(TIC, "<", $ticpath))
        {
            error("Can't open $ticpath $!");
            finish(2);
        }
        my @lines = grep {s/[\r\n]+//;} readline(TIC);
        close(TIC);
        display(@lines) if($debug == 1);
        my ($catched) = grep(/^File \S+$/i, @lines);
        display($catched) if($debug == 1);
        $catched =~ /^File (\S+)$/i;
        my $usedFile = $1;
        display($usedFile) if($debug == 1);
        if($usedFile ne "")
        {
            $filenames{$usedFile} = $ticpath;
            print STDERR "filenames\{$usedFile\}=$filenames{$usedFile}\n" if($debug == 1);
        }
    }

    my $n = 0;
    foreach my $file (@files)
    {
        my $used = 0;
        foreach my $usedFile (keys %filenames)
        {
            if(lc($file) eq lc($usedFile))
            {
                $used = 1;
                last;
            }
        }
        display($used) if($debug == 1);
        if($used == 0)
        {
            my $path = File::Spec->catfile($passFileAreaDir, $file);
            display($path) if($debug == 1);
            if(!unlink($path))
            {
                error("Can't delete file \"$path\" ($!)");
                finish(2);
            }
            put("File $path deleted");
            $n++;
        }
    }
    put("$n widow files deleted") if($n > 0);
}



finish(0);


__END__

=head1 NAME

rmLinkMail.pl - remove netmail, echomail and files of a link

=head1 SYNOPSIS

perl rmLinkMail.pl [options]

  Options:
    --config path           path to fidoconfig
    --address ftnAddress    the link address
    --netmail               exclude netmail from the files to be deleted
    --echomail              exclude echomail from the files to be deleted
    --fileecho              exclude fileechomail from the files to be deleted
    --other-files           exclude other files in the link's filebox
    --box                   do not delete an empty filebox
    --report [area]         send a report to the echo area
    --nolog                 do not log anything in the rmLinkMail.log file
    --quiet                 do not print to terminal window
    --help                  print help and exit

  To print full documentation run `perldoc rmLinkMail.pl`.

=head1 DESCRIPTION

rmLinkMail.pl removes netmail, echomail and files of the specified link taking
all the necessary information from fidoconfig.

=head1 OPTIONS

All options are case insensitive and their names may be abbreviated to uniqueness.
One may also use single-character option names with one dash instead of long option
names with two dashes.

=over 4

=item B<-c> path

=item B<--config> path

You have to supply full path to fidoconfig here if FIDOCONFIG environment
variable is not defined. Otherwise you may omit the option.

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

Send a report about the deleted files to the echo area.

If the name of the area is omitted, then  B<ReportTo> statement
in fidoconfig is used.

If the whole option is omitted, a report will not be sent.

=item B<-l>

=item B<--log>

Log all actions to rmLinkMail.log file if B<LogFileDir> is defined in fidoconfig.
It is not necessary to use it since on default logging is switched on.

=item B<--nolog>

Do not print anything to rmLinkMail.log file. This option does not influence sending
a report or printing to terminal window.

=item B<-q>

=item B<--quiet>

Do not print to terminal window. This option does not influence sending
a report or printing to a log file.

=item B<-h>

=item B<--help>

Print a brief help and exit

=back

=head1 EXIT CODE

If required operation is successfully done, the exit code is 0. If help is
printed, the exit code is 1, otherwise it is 2.

=head1 RESTRICTION

SeparateBundles keyword in fidoconfig is not supported.

=head1 AUTHOR

Michael Dukelsky 2:5020/1042

=cut
