#
# Perl functions for deleting files from Amiga Style Outbound, BinkleyTerm
# Style Outbound, fileecho passthrough directory and fileboxes and also
# deleting links given fidoconfig as configuration file(s).
# Fidoconfig is common configuration of Husky Fidonet software.
#
# It is free software and license is the same as for Perl,
# see http://dev.perl.org/licenses/
#
package Husky::Rmfiles;
our (@ISA, @EXPORT, $VERSION);
our (
     $fidoconfig, $link,    $delete,     $backup,   $report,    $log,
     $quiet,      $netmail, $echomail,   $fileecho, $otherfile, $filebox,
     $listterm,   $listlog, $listreport, $dryrun,   $huskyBinDir
    );

# The package version
$VERSION = "1.10";

use Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(init unsubscribeLink rmFilesFromOutbound rmFilesFromFilebox
  rmOrphanFilesFromPassFileAreaDir rmLinkDefinition publishReport
  rmOrphanFilesFromOutbound put error lastError
  $fidoconfig $link $delete $backup $report $log
  $quiet $netmail $echomail $fileecho $otherfile $filebox
  $listterm $listlog $listreport $dryrun $huskyBinDir);

#@EXPORT_OK = qw(put error lastError);

use Carp;
use Fcntl qw(:flock);
use File::Find qw(&find);
use File::Spec::Functions;
use Config;
use File::Basename;
use File::Temp qw(tempfile tempdir);
use POSIX qw(strftime);
use Fidoconfig::Token 2.5;
use File::Copy qw/cp/;
use IO::Handle;
use 5.008;
use strict;
use warnings;

my (
    $address,      $fileBoxesDir,    $logfile,     $lockFile,
    $advisoryLock, $lh,              $defZone,     $defOutbound,
    $zone,         $net,             $node,        $point,
    $ASO,          $passFileAreaDir, $ticOutbound, $busyFileDir,
    $OS,           $reportToEcho,    $list,        $all,
    $hpt,          $htick,
   );

# Transliterate Windows path to Perl presentation
sub perlpath
{
    my $path = shift;
    if(getOS ne 'UNIX')
    {
        $path =~ tr!\\!/!;
    }
    return $path;
}

=head1 NAME

Husky::Rmfiles - delete files from ASO, BSO, fileboxes and so on. Delete links
from fidoconfig.

=head1 SYNOPSYS

    use Husky::Rmfiles;

    init();
    unsubscribeLink();
    rmFilesFromOutbound();
    rmFilesFromFilebox();
    rmOrphanFilesFromPassFileAreaDir();
    rmLinkDefinition();
    publishReport($subject, $fromname, \@header, \@footer);

    init("no link");
    rmOrphanFilesFromOutbound($outbound);
    publishReport($subject, $fromname, \@header, \@footer);

=head1 DESCRIPTION

Husky::Rmfiles contains Perl functions for deleting files from Amiga Style
Outbound, BinkleyTerm Style Outbound, fileecho passthrough directory,
fileboxes, htick busy directory and also deleting links given fidoconfig as
configuration file(s). Fidoconfig is common configuration of Husky Fidonet
software. All necessary configuration information is taken from fidoconfig
using Fidoconfig::Token package.

=head1 SUBROUTINES

=head2 init($nolink)

The subroutine checks some package variables and makes initializations. It is
necessary to call it before using any other subroutines of this package. If your
task is to delete files stored for one specific link and/or delete the link
itself from fidoconfig, you should call init() without arguments. If all you
want is to delete fileecho files without .TICs referring to them, or echomail
files without flow files referring to them, then you call init() with some
argument. The argument itself does not matter, it may be a non-empty string or
a non-zero number.

=cut

sub init
{
    my ($nolink) = @_;
    ($fidoconfig && -f $fidoconfig && -s $fidoconfig) or
      die("Please supply the path to fidoconfig\n");

    if(!$nolink)
    {
        $link or die("Please supply the link's FTN address\n");

        ($zone, $net, $node, $point) = $link =~ m!(\d+):(\d+)/(\d+)(?:\.(\d+))?!;
        if(!defined($zone))
        {
            lastError(
                     "\naddress=$link but it should be zone:net/node or zone:net/node.point\n");
        }
        $point = 0 if(!defined($point));
    }

    $fidoconfig = normalize($fidoconfig);

    $list = sub
    {
        my $res = 0;
        $res |= 4 if($listterm);
        $res |= 2 if($listlog);
        $res |= 1 if($listreport);
        return $res;
    };
    $all = 7;

    my ($path, $logfileDir);
    $module = "hpt";
    if($log)
    {
        $commentChar = '#';
        ($path, $logfileDir) = findTokenValue($fidoconfig, "LogFileDir");
        $logfileDir = expandVars($logfileDir) if($logfileDir);
        $logfile = (!$logfileDir) ? "" : normalize(catfile($logfileDir, $log));
        if($logfile)
        {
            open($lh, ">>", $logfile) or die("Cannot open $logfile\n");
        }
    }

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
    if(!$hpt_exists)
    {
        $report = "";
        $hpt = "";
    }
    my $htick_exists = grep(/htick/,
        eval
        {
            no warnings 'all';
            qx($htick -h 2>&1)
        }) > 1 ? 1 : 0;
    if(!$htick_exists)
    {
        $htick = "";
    }

    if(defined($report) && !$report)
    {
        # fetch ReportTo from fidoconfig
        $commentChar = '#';
        ($path, $report) = findTokenValue($fidoconfig, "ReportTo");
        if($report eq "" || $report eq "on")
        {
            $report = "";
            error($all, "ReportTo is not defined in your fidoconfig");
            error($all,
                  "and you did not specify an echo or netmail area to send report to.");
            error($all, "No report will be issued.");
        }
    }

    if($report)
    {
        my @areas;
        $reportToEcho = undef;
        $commentChar  = '#';
        my $areaName;
        ($path, $areaName) =
          findTokenValue($fidoconfig, "EchoArea", "=~", qr/^($report)\s/i);
        $reportToEcho = 1 if($areaName);

        if(!defined($reportToEcho))
        {
            $commentChar = '#';
            ($path, $areaName) =
              findTokenValue($fidoconfig, "NetmailArea", "=~", qr/^($report)\s/i);
            $reportToEcho = 0 if($areaName);
        }

        if(!defined($reportToEcho))
        {
            lastError("Cannot find either echo or netmail area \"$report\"\n");
        }
    }

    my $separateBundles;
    $commentChar = '#';
    ($path, $separateBundles) = findTokenValue($fidoconfig, "SeparateBundles");
    lastError("SeparateBundles mode is not supported") if(isOn($separateBundles));

    $commentChar = '#';
    $Fidoconfig::Token::valueType = "integer";
    ($path, $advisoryLock) = findTokenValue($fidoconfig, "advisoryLock");
    $Fidoconfig::Token::valueType = undef;

    sub is_non_negative_integer
    {
        defined $_[0] && $_[0] =~ /^\d+$/;
    }

    if($advisoryLock)
    {
        if(!is_non_negative_integer($advisoryLock))
        {
            lastError("advisoryLock should be a non-negative integer");
        }
        elsif($advisoryLock > 0)
        {
            $commentChar = '#';
            ($path, $lockFile) = findTokenValue($fidoconfig, "lockFile");
        }
    }

    $commentChar = '#';
    ($path, $address) = findTokenValue($fidoconfig, "address");
    $defZone = undef;
    $defZone = $1 if($address && $address =~ /^(\d+):\d+\/\d+(?:\.\d+)?$/);
    if(!defined($defZone))
    {
        lastError("Your FTN address is not defined or has a syntax error");
    }

    $commentChar = '#';
    ($path, $fileBoxesDir) = findTokenValue($fidoconfig, "FileBoxesDir");
    if($fileBoxesDir)
    {
        lastError("fileBoxesDir \'$fileBoxesDir\' is not a directory")
          if(!-d $fileBoxesDir);
        $fileBoxesDir = normalize($fileBoxesDir);
    }

    # Default outbound
    $commentChar = '#';
    ($path, $defOutbound) = findTokenValue($fidoconfig, "Outbound");
    lastError("Outbound is not defined") if(!$defOutbound);

    $module = "htick";

    $commentChar = '#';
    ($path, $busyFileDir) = findTokenValue($fidoconfig, "BusyFileDir");
    unless($busyFileDir)
    {
        $busyFileDir = normalize(catdir($defOutbound, "busy.htk"));
    }

    $commentChar = '#';
    ($path, $passFileAreaDir) = findTokenValue($fidoconfig, "passFileAreaDir");

    if($passFileAreaDir && -d $passFileAreaDir)
    {
        $commentChar = '#';
        ($path, $ticOutbound) = findTokenValue($fidoconfig, "ticOutbound");
        unless($ticOutbound && -d $ticOutbound)
        {
            $ticOutbound = $passFileAreaDir;
        }
    }

    $module = "hpt";

    $OS = getOS();
    put($all, "### It is a dry-run, no actual changes will be made ###")
      if($dryrun);
    return 1;
} ## end sub init

my @reportLines;
#
# put($level, $msg) - print a string to terminal, logfile and to the report.
#   $level is a number from 0 to 7 and it is a bitmask containing 3 bits.
#       A 1 in the most significant bit allows printing to terminal,
#       a 1 in the middle bit allows printing to logfile and
#       a 1 in the least significant bit allows printing to the report.
#       So $level == 7 means printing everywhere,
#          $level == 6 means printing to terminal and logfile,
#          $level == 5 means printing to terminal and report,
#          $level == 4 means printing to terminal,
#          $level == 3 means printing to logfile and report,
#          $level == 2 means printing to logfile,
#          $level == 1 means printing to report,
#          $level == 0 - do not print.
#   $msg is the string to print.
#
sub put
{
    my ($level, $msg) = @_;
    print "$msg\n" if(!$quiet && $level & 4);
    my $date = strftime("%Y-%m-%d %H:%M:%S", localtime);
    print $lh "$date  $msg\n" if($log && $level & 2);
    push(@reportLines, $msg) if($report && $level & 1);
}

sub error
{
    my ($level, $msg) = @_;
    print STDERR "$msg\n";
    my $date = strftime("%Y-%m-%d %H:%M:%S", localtime);
    print $lh "$date  $msg\n" if($log && $level & 2);
    push(@reportLines, $msg) if($report && $level & 1);
}

sub lastError
{
    my $msg = shift;
    print STDERR "$msg\n";
    my $date = strftime("%Y-%m-%d %H:%M:%S", localtime);
    print $lh "$date  $msg\n" if($log);
    close($lh) if($log);
    push(@reportLines, $msg) if($report);
    die("$msg\n");
}

=head2 unsubscribeLink

The subroutine has no arguments and it unsubsribes the link with the FTN address
in the C<link> package variable (see B<VARIABLES>) from all echos if the link is
subscribed to at least one echo and from all fileechos if the link is subscribed
to at least one fileecho. If you want to delete a link, you have to unsubscribe
it before deleting files stored for it.

=cut

sub unsubscribeLink
{
    # Unsubscribe from all echos if the link is subscribed at least to one echo
    $module      = "hpt";
    $commentChar = '#';
    my ($tokenFile, $value, $linenum, @lines) =
      findTokenValue($fidoconfig, 'EchoArea', '=~', $link);
    if($value eq "")
    {
        put($all, "$link was not subscribed to any echos");
    }
    elsif(!$hpt)
    {
        put($all, "hpt is not accessible, so unsubsribing from echos was skipped");
    }
    else
    {
        if(!$dryrun)
        {
            if($OS eq "UNIX")
            {
                my $cmd      = "$hpt -c $fidoconfig afix -s $link '-*'";
                my $exitcode = system("$cmd");
                lastError("system(\"$cmd\") failed: $!") if(($exitcode >> 8) != 0);
            }
            else
            {
                my @cmd = ("$hpt", "-c", "\"$fidoconfig\"", "afix", "-s", "$link", "-*");
                my $exitcode = system(@cmd);
                lastError("system(\"@cmd\") failed: $!") if(($exitcode >> 8) != 0);
            }
        }
        put($all, "$link was unsubscribed from all echos");
    }

    # Unsubscribe from all file echos if the link is subscribed at least to one file echo
    $module      = "htick";
    $commentChar = '#';
    ($tokenFile, $value, $linenum, @lines) =
      findTokenValue($fidoconfig, 'FileArea', '=~', $link);
    if($value eq "")
    {
        put($all, "$link was not subscribed to any fileechos");
    }
    elsif(!$htick)
    {
        put($all, "htick is not accessible, so");
        put($all, "unsubsribing from file echos was skipped");
    }
    else
    {
        if(!$dryrun)
        {
            if($OS eq "UNIX")
            {
                my $cmd = "$htick -c \"$fidoconfig\" ffix -s $link '-*'";
                !qx($cmd) or lastError("qx(\"$cmd\") failed: $!");
            }
            else
            {
                my @cmd = ("$htick", "-c", "\"$fidoconfig\"", "ffix", "-s", "$link", "-*");
                my $exitcode = system(@cmd);
                lastError("system(\"@cmd\") failed: $!") if(($exitcode >> 8) != 0);
            }
        }
        put($all, "$link was unsubscribed from all fileechos");
    }
    $module = "hpt";
} ## end sub unsubscribeLink

sub deleteFiles
{
    my @filesToDelete = @_;
    my ($deleted, $notdeleted);
    $deleted = $notdeleted = 0;
    for my $file (@filesToDelete)
    {
        $file = normalize($file);
        my $num = !$dryrun ? unlink $file : 1;
        if($num == 1)
        {
            put($list->(), "$file deleted");
            $deleted++;
        }
        else
        {
            error($list->(), "Cannot delete $file: $!");
            $notdeleted++;
        }
    }
    put($all, "$deleted files were deleted") if($deleted);
    error($all, "$notdeleted files were not deleted") if($notdeleted);
}

sub rmFilesFromLo
{
    my $lofile = shift;
    return unless($lofile);
    lastError("Can't open $lofile $!") if(!open(LO, "<", $lofile));
    my @lines = readline(LO);
    close(LO);

    my @files = ();

    # Remove echobundles and tics
    foreach my $line (@lines)
    {
        $line =~ s/[\n\r]//;
        my $directive = substr($line, 0, 1);
        my $fullname = $line;
        $fullname = substr($line, 1) if $directive =~ /^[\^~\-!@\#]$/;
        next unless(-f $fullname);
        my $basename = basename($fullname);
        if((!$echomail && $basename =~ /\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z]$/i) ||
            (!$fileecho && $basename =~ /\.tic$/i))
        {
            push(@files, $fullname);
        }
    }

    return unless(@files);

    put($all, "Deleting echomail and tics from outbound");
    deleteFiles(@files);
} ## end sub rmFilesFromLo

=head2 rmFilesFromOutbound

The subroutine has no arguments and it deletes files stored in the outbound for
the link with the FTN address in the C<$link> package variable (see B<VARIABLES>).
The files may be stored in one of two formats, either BinkleyTerm Style Outbound
or Amiga Style Outbound. If the link has files in the directory configured by
C<busyFileDir> fidoconfig statement, they are also handled. The package
variables C<$netmail>, C<$echomail> and C<$fileecho> control which files are
deleted and which are not. The package variables C<$report>, C<$log>,
C<$quiet> control where the information about deleted files is logged, the
variables C<$listterm>, C<$listlog>, C<$listreport> control the volume of the
logged information and the C<$dryrun> variable controls whether anything is
really deleted.

=cut

sub rmFilesFromOutbound
{
    my $outbound;
    $defOutbound = normalize($defOutbound);
    if(!-d $defOutbound)
    {
        error($all, "Outbound directory $defOutbound does not exist");
        return;
    }

    # Flow filename
    my $asoname = "$zone.$net.$node.$point";
    my $bsoname = sprintf("%04x%04x", $net, $node);

    # Outbound hex extension
    my $hexzone = sprintf("%03x", $zone);
    my $bsooutbound = ($zone != $defZone) ? "$defOutbound.$hexzone" : $defOutbound;
    $bsooutbound = "" if(!-d $bsooutbound);
    if($bsooutbound && $point)
    {
        $bsooutbound = normalize(catdir($bsooutbound, $bsoname . ".pnt"));
        $bsoname = sprintf("%08x", $point);
        $bsooutbound = "" if(!-d $bsooutbound);
    }

    for my $style ("aso", "bso")
    {
        $outbound = $style eq "aso" ? $defOutbound : $bsooutbound;
        next unless($outbound);
        my $loname = $style eq "aso" ? $asoname : $bsoname;

        my $bsy = normalize(catfile($outbound, "$loname.bsy"));
        if(-f $bsy)
        {
            error($all, "\nBusy flag $bsy found!");
            error(
                $all,
                "You may run the script again after the software that has set the flag removes it."
            );
            lastError("If the busy flag is stale, you may remove it manually.");
        }

        # Remove echomail and tics from $outbound
        my $flowFile;
        my $getFlowFile = sub
        {
            return if($File::Find::dir ne $outbound);
            if(-f $File::Find::name &&
                basename($File::Find::name) =~ /^$loname\.[icdfh]lo$/i)
            {
                $flowFile = $File::Find::name;
            }
        };
        find($getFlowFile, $outbound);
        rmFilesFromLo($flowFile) if($flowFile && -f $flowFile);

        # Remove flow files
        my @filesToRemove;
        my $getFlowFileToRemove = sub
        {
            return if($File::Find::dir ne $outbound);
            if(-f $File::Find::name)
            {
                my $base = basename($File::Find::name);
                if(!$echomail && !$fileecho && $base =~ /^$loname\.[icdfh]lo$/i ||
                    !$netmail && $base =~ /^$loname\.[icdoh]ut$/i ||
                    !$netmail &&
                    !$echomail &&
                    !$fileecho &&
                    ($base =~ /^$loname\.try$/i || $base =~ /^$loname\.hld$/i))
                {
                    push(@filesToRemove, $File::Find::name);
                }
            }
        };
        find($getFlowFileToRemove, $outbound);
        if(@filesToRemove)
        {
            put($all, "Deleting flow files from outbound");
            deleteFiles(@filesToRemove);
        }
    } ## end for my $style ("aso", "bso"...)

    if(-d $busyFileDir)
    {
        my @ticsToRemove;
        my $getTIC = sub
        {
            return if($File::Find::dir ne $busyFileDir);
            if(-f $File::Find::name &&
                basename($File::Find::name) =~ /\.tic$/i &&
                !$fileecho)
            {
                open(TIC, "<", $File::Find::name) or
                  croak("Could not open $File::Find::name: $!");
                my $tolink = grep {m/^To\s+$link/i} <TIC>;
                close(TIC);
                push(@ticsToRemove, $File::Find::name) if($tolink);
            }
        };
        find($getTIC, $busyFileDir);
        if(@ticsToRemove)
        {
            put($all, "Deleting TICs from BusyFileDir");
            deleteFiles(@ticsToRemove);
        }
    } ## end if(-d $busyFileDir)
} ## end sub rmFilesFromOutbound

=head2 rmFilesFromFilebox

The subroutine has no arguments and it deletes files stored in the filebox for
the link with the FTN address in the C<$link> package variable (see
B<VARIABLES>). The package variables C<$netmail>, C<$echomail>, C<$fileecho>
and C<$otherfile> control which files are deleted and which are not. The
package variable C<$filebox> controls whether the filebox is deleted after
deleting all files from it. The package variables C<$report>, C<$log>, C<$quiet>
control where the information about deleted files is logged, the variables
C<$listterm>, C<$listlog>, C<$listreport> control the volume of the logged
information and the C<$dryrun> variable controls whether anything is really
deleted.

=cut

sub rmFilesFromFilebox
{
    return if(!$fileBoxesDir);
    my ($box, $boxh, $fileboxname);
    $fileboxname = "";
    $box         = "$zone.$net.$node.$point";
    $boxh        = "$box.h";

    my $getFilebox = sub
    {
        return if($File::Find::dir ne $fileBoxesDir);
        if(-d $File::Find::name)
        {
            my $base = basename($File::Find::name);
            if($base eq $box || lc($base) eq $boxh)
            {
                $fileboxname = $File::Find::name;
            }
        }
    };

    find($getFilebox, $fileBoxesDir);
    if($fileboxname eq "")
    {
        put($all, "There is no filebox for $link");
        return;
    }

    my (@tics, @filesToRemove);
    my $getFileInFilebox = sub
    {
        return if($File::Find::dir ne $fileboxname);
        my $file = $File::Find::name;
        my $base = basename($file);
        return
          if(
             $netmail &&
             ($base =~ /\.[icdoh]ut$/i ||
                $base =~ /\.try$/i ||
                $base =~ /\.hld$/i)
            );
        return
          if(
             $echomail &&
             ($base =~ /\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z]$/i ||
                $base =~ /\.try$/i ||
                $base =~ /\.hld$/i)
            );
        if($base =~ /\.tic$/i)
        {
            push(@tics, $file) if(($fileecho || $otherfile) && -f $file);
            return if($fileecho);
        }
        return
          if(($netmail || $echomail || $fileecho || $otherfile) &&
             ($base =~ /\.try$/i || $base =~ /\.hld$/i));
        push(@filesToRemove, $file) if(-f $file);    # not a directory
    };

    find($getFileInFilebox, $fileboxname);

    # Collect all filenames in the filebox referred by TICs
    my @referredByTic;
    for my $tic (@tics)
    {
        # if $tic has non-zero size
        if((stat($tic))[7])
        {
            open(FH, "<", $tic) or lastError("Cannot open $tic: $!");
            my @ticlines = <FH>;
            close(FH);
            my ($file) = grep {s/[\r\n]//; s/^File (\S+)$/$1/i;} @ticlines;
            if($file && -f normalize(catfile($fileboxname, $file)))
            {
                push(@referredByTic, $file);
            }
        }
    }

    if($fileecho)
    {
        for(my $i = @filesToRemove - 1; $i >= 0; $i--)
        {
            my $base = basename($filesToRemove[$i]);
            if(grep(/^$base$/i, @referredByTic))
            {
                # Don't remove files referred by TICs
                splice(@filesToRemove, $i, 1);
            }
        }
    }

    # if $otherfile != 0, remove from @filesToRemove all files not referred
    # by TICS and not netmail and not echomail and not TICs
    if($otherfile)
    {
        for(my $i = @filesToRemove - 1; $i >= 0; $i--)
        {
            my $base = basename($filesToRemove[$i]);
            if($base !~ /\.[icdoh]ut$/i &&
                $base !~ /\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z]$/i &&
                $base !~ /\.tic$/i                              &&
                $base !~ /\.try$/i                              &&
                $base !~ /\.hld$/i                              &&
                !grep(/^$base$/i, @referredByTic))
            {
                splice(@filesToRemove, $i, 1);
            }
        }
    }

    my $first      = 1;
    my $basename   = basename($fileboxname);
    my $deleted    = 0;
    my $notdeleted = 0;
    for my $file (@filesToRemove)
    {
        $file = normalize($file);
        my $num = !$dryrun ? unlink $file : 1;
        if($num)
        {
            if($first)
            {
                put($all, "Deleting files from filebox $basename");
                $first = 0;
            }
            put($list->(), "$file deleted");
            $deleted++;
        }
        else
        {
            error($list->(), "Could not delete $file");
            $notdeleted++;
        }
    }
    put($all, "$deleted files were deleted")        if($deleted);
    put($all, "$notdeleted files were not deleted") if($notdeleted);
    if(!$filebox)
    {
        if($notdeleted == 0)
        {
            return if($netmail || $echomail || $fileecho || $otherfile);

            if(!$dryrun ? rmdir($fileboxname) : 1)
            {
                put($all, "Filebox $basename was deleted");
            }
            else
            {
                error($all, "Could not delete filebox $basename");
            }
        }
    }
} ## end sub rmFilesFromFilebox

sub readTIC
{
    my ($ticname) = @_;
    my $ticpath = normalize(catfile($ticOutbound, $ticname));
    lastError("Cannot open $ticpath $!") if(!open(TIC, "<", $ticpath));
    my @lines = grep {s/[\r\n]+//;} readline(TIC);
    close(TIC);
    return @lines;
}

=head2 rmOrphanFilesFromOutbound($outbound, $age)

The subroutine removes echomail bundles not referred by any flow file (AKA
orphan files) from the outbound. Echomail bundles may become orphan as a result
of erroneous manual deleting files from outbound or after software or hardware
crashes. Orphan files of zero length resulted from the normal processing by your
tosser may also be deleted. The subroutine has two arguments - the full path to the
outbound directory and the minimum age in days of truncated echomail bundles
required for the bundles to be deleted.

=cut

sub rmOrphanFilesFromOutbound
{
    my ($outbound, $age) = @_;
    return if(!-d $outbound);

    my $fileAge = time() - $age * 3600 * 24;

    my @allLoFiles;
    my $getAnyLoFile = sub
    {
        if(-f $File::Find::name && basename($File::Find::name) =~ /\.[icdfh]lo$/i)
        {
            push(@allLoFiles, $File::Find::name);
        }
    };
    find($getAnyLoFile, $outbound);

    # All echomail in outbound  mentioned in lo files
    my @filesFromLo;
    for my $lofile (@allLoFiles)
    {
        lastError("Can't open $lofile $!") if(!open(LO, "<", $lofile));
        my @lines = readline(LO);
        close(LO);

        foreach my $line (@lines)
        {
            $line =~ s/[\n\r]//;
            my $directive = substr($line, 0, 1);
            my $fullname = $line;
            $fullname = perlpath(substr($line, 1)) if $directive =~ /^[\^~\-!@\#]$/;
            next unless(-f $fullname);
            my $basename = basename($fullname);
            $outbound = perlpath($outbound);
            if($basename =~ /\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z]$/i &&
                $fullname =~ /^$outbound/)
            {
                push(@filesFromLo, $basename);
            }
        }
    }

    # All echomail in outbound
    my @echobundles;
    my $getEchomail = sub
    {
        return if($File::Find::dir ne $outbound);
        if(-f $File::Find::name &&
            basename($File::Find::name) =~ /\.(?:mo|tu|we|th|fr|sa|su)[0-9a-z]$/i)
        {
            # Do not push to @echobundles truncated echomail bundles newer than $age
            my @stat = stat($File::Find::name);
            return if($stat[7] == 0 && ($fileAge < $stat[9]));

            push(@echobundles, basename($File::Find::name));
        }
    };
    my $sortFiles = sub
    {
        return sort(@_);
    };
    find({wanted => $getEchomail, preprocess => $sortFiles}, $outbound);

    for(my $i = $#echobundles; $i >= 0; $i--)
    {
        my $file = $echobundles[$i];

        # Remove files present in @filesFromLo from @echobundles
        if(grep(/^$file$/, @filesFromLo))
        {
            splice(@echobundles, $i, 1);
        }
    }

    # Delete orphan files
    if(@echobundles)
    {
        my $base = basename($outbound);
        put($all, "Deleting orphan files from $base");
        my ($deleted, $notdeleted);
        $deleted = $notdeleted = 0;
        for my $file (@echobundles)
        {
            $file = normalize(catfile($outbound, $file));
            my $num = !$dryrun ? unlink $file : 1;
            if($num == 1)
            {
                put($list->(), "$file deleted");
                $deleted++;
            }
            else
            {
                error($list->(), "Cannot delete $file: $!");
                $notdeleted++;
            }
        }
        put($all, "$deleted files were deleted") if($deleted);
        error($all, "$notdeleted files were not deleted") if($notdeleted);
    } ## end if(@echobundles)
} ## end sub rmOrphanFilesFromOutbound

=head2 rmOrphanFilesFromPassFileAreaDir

The subroutine has no arguments and it removes fileecho files without .TICs (AKA
orphan files) from the directory configured by C<passFileAreaDir> fidoconfig
statement. .TICs are taken either from the directory configured by C<ticOutbound>
or C<passFileAreaDir> fidoconfig statement. Fileecho files become orphan after
.TICs deletion carried out normally by C<rmFilesFromOutbound()> or by htick.

=cut

sub rmOrphanFilesFromPassFileAreaDir
{
    if($passFileAreaDir && -d $passFileAreaDir)
    {
        if(!opendir(DIR, $passFileAreaDir))
        {
            lastError("Cannot open $passFileAreaDir directory ($!)");
        }
        my @files =
          grep(-f normalize(catfile($passFileAreaDir, $_)) && !/\.tic$/i, readdir(DIR));
        closedir(DIR);

        lastError("Cannot open $ticOutbound directory ($!)")
          if(!opendir(DIR, $ticOutbound));
        my @tics =
          grep(-f normalize(catfile($ticOutbound, $_)) && /\.tic$/i, readdir(DIR));
        closedir(DIR);

        put($all, "Deleting orphan files from PassFileAreaDir");
        my @usedFiles = ();
        foreach my $ticname (@tics)
        {
            my ($usedFile) = grep {s/[\r\n]//; s/^File (\S+)$/$1/i;} readTIC($ticname);
            push(@usedFiles, $usedFile) if($usedFile);
        }

        my $deleted    = 0;
        my $notdeleted = 0;
        foreach my $file (@files)
        {
            # If the $file is not used by any .tic
            unless(grep(/^$file$/i, @usedFiles))
            {
                my $path = normalize(catfile($passFileAreaDir, $file));
                if(!$dryrun ? unlink($path) : 1)
                {
                    put($list->(), "File $path deleted");
                    $deleted++;
                }
                else
                {
                    error($list->(), "Could not delete file \"$path\"");
                    $notdeleted++;
                }
            }
        }
        put($all, "$deleted orphan files were deleted");
        error($all, "$notdeleted orphan files were not deleted") if($notdeleted > 0);
    } ## end if($passFileAreaDir &&...)
} ## end sub rmOrphanFilesFromPassFileAreaDir

# Write the changed configuration file back
sub writeConfig
{
    my ($file, @lines) = @_;
    if(!$advisoryLock)
    {
        open(FILE, ">", $file) or
          lastError("Cannot open $file to write config back: $!");
        print FILE @lines;
        close(FILE);
        return;
    }
    my $count = $advisoryLock;
    open(LOCK, ">", $lockFile) or lastError("Cannot open $lockFile: $!");
    while($count > 0)
    {
        if(flock(LOCK, LOCK_EX))
        {
            open(FILE, ">", $file) or
              lastError("Cannot open $file to write config back: $!");
            print FILE @lines;
            close(FILE);
            close(LOCK);
            return;
        }
        else
        {
            $count--;
            sleep(1);
        }
    }
    close(LOCK);
    error($all, "Could not lock $file for $advisoryLock seconds.");
    lastError("The changed configuration was not written back to $file");
} ## end sub writeConfig

=head2 rmLinkDefinition

The subroutine has no arguments and it revokes the link definition from
fidoconfig for the link with the FTN address in the C<$link> package variable
(see B<VARIABLES>). There are two options of revoking the link definition. When
C<$delete> package variable is true (for instance, equals 1), the link
definition is deleted. When C<$delete> is false (for instance, not defined),
the link definition is not deleted but commented out. If C<$backup> package
variable is true, before changing the configuration file with the link
definition, the file is copied to another file with the same name but with
the ".bak" additional extension.

=cut

sub rmLinkDefinition
{
    if(!$hpt)
    {
        put($all, "hpt is not accessible, so removing link definition is skipped");
        return;
    }

    my $sysop;
    $commentChar = '#';
    my ($file, $value, $linenum, @lines) =
      findTokenValue($fidoconfig, 'Aka', 'eq', $link);
    lastError("Line \"AKA $link\" not found") if(!defined($linenum));
    my @index;    # Line numbers to be commented out or deleted
                  # Find "Link" line
    for(my $i = $linenum - 1; $i >= 0; $i--)
    {
        my $line = $lines[$i];
        $line =~ s/[\r\n]+//;
        ($line) = stripSpaces(stripComment($line));
        my $token = $line =~ /^([a-z]+)/i ? $1 : "";
        if(lc($token) eq "link")
        {
            $index[0] = $i;
            $sysop = $line =~ m/^link\s+(.+)$/i ? $1 : "";
            last;
        }
    }
    lastError("Cannot find 'Link' token for $link in $file")
      if(!defined($index[0]));

    for(my $i = $index[0] + 1, my $j = 1; $i < @lines; $i++)
    {
        my $line = $lines[$i];
        $line =~ s/[\r\n]+//;
        ($line) = stripSpaces(stripComment($line));
        my $token = $line =~ m/^([a-z0-9]+)/i ? $1 : undef;
        next if(!defined($token));
        $token = lc($token);
        if($token eq "aka")
        {

            if($i == $linenum)
            {
                $index[$j++] = $i;
                next;
            }
            else
            {
                lastError("Looks like something is wrong with $link definition in $file");
            }
        }
        if($token eq "email" ||
            $token eq "emailfrom"                     ||
            $token eq "emailsubj"                     ||
            $token eq "emailencoding"                 ||
            $token eq "ouraka"                        ||
            $token eq "password"                      ||
            $token eq "pktpwd"                        ||
            $token eq "ticpwd"                        ||
            $token eq "areafixpwd"                    ||
            $token eq "filefixpwd"                    ||
            $token eq "bbspwd"                        ||
            $token eq "sessionpwd"                    ||
            $token eq "areafixname"                   ||
            $token eq "filefixname"                   ||
            $token eq "handle"                        ||
            $token eq "packer"                        ||
            $token eq "autocreate"                    ||
            $token eq "areafixautocreate"             ||
            $token eq "filefixautocreate"             ||
            $token eq "autocreatefile"                ||
            $token eq "areafixautocreatefile"         ||
            $token eq "filefixautocreatefile"         ||
            $token eq "autocreatedefaults"            ||
            $token eq "areafixautocreatedefaults"     ||
            $token eq "filefixautocreatedefaults"     ||
            $token eq "autosubscribe"                 ||
            $token eq "areafixautosubscribe"          ||
            $token eq "filefixautosubscribe"          ||
            $token eq "forwardrequests"               ||
            $token eq "areafixforwardrequests"        ||
            $token eq "filefixforwardrequests"        ||
            $token eq "fwddenyfile"                   ||
            $token eq "areafixfwddenyfile"            ||
            $token eq "filefixfwddenyfile"            ||
            $token eq "fwddenymask"                   ||
            $token eq "areafixfwddenymask"            ||
            $token eq "filefixfwddenymask"            ||
            $token eq "denyfwdreqaccess"              ||
            $token eq "areafixdenyfwdreqaccess"       ||
            $token eq "filefixdenyfwdreqaccess"       ||
            $token eq "denyuncondfwdreqaccess"        ||
            $token eq "areafixdenyuncondfwdreqaccess" ||
            $token eq "filefixdenyuncondfwdreqaccess" ||
            $token eq "fwdfile"                       ||
            $token eq "areafixfwdfile"                ||
            $token eq "filefixfwdfile"                ||
            $token eq "fwdmask"                       ||
            $token eq "areafixfwdmask"                ||
            $token eq "filefixfwdmask"                ||
            $token eq "fwdpriority"                   ||
            $token eq "areafixfwdpriority"            ||
            $token eq "filefixfwdpriority"            ||
            $token eq "echolimit"                     ||
            $token eq "areafixecholimit"              ||
            $token eq "filefixecholimit"              ||
            $token eq "pause"                         ||
            $token eq "export"                        ||
            $token eq "import"                        ||
            $token eq "optgrp"                        ||
            $token eq "accessgrp"                     ||
            $token eq "linkgrp"                       ||
            $token eq "mandatory"                     ||
            $token eq "manual"                        ||
            $token eq "level"                         ||
            $token eq "advancedareafix"               ||
            $token eq "allowemptypktpwd"              ||
            $token eq "allowpktaddrdiffer"            ||
            $token eq "allowremotecontrol"            ||
            $token eq "arcmailsize"                   ||
            $token eq "arcnetmail"                    ||
            $token eq "areafix"                       ||
            $token eq "autopause"                     ||
            $token eq "availlist"                     ||
            $token eq "dailybundles"                  ||
            $token eq "denyrescan"                    ||
            $token eq "echomailflavour"               ||
            $token eq "flavour"                       ||
            $token eq "fileechoflavour"               ||
            $token eq "fileareadefaults"              ||
            $token eq "forwardpkts"                   ||
            $token eq "filebox"                       ||
            $token eq "fileboxalways"                 ||
            $token eq "linkbundlenamestyle"           ||
            $token eq "linkgrp"                       ||
            $token eq "linkmsgbasedir"                ||
            $token eq "netmailflavour"                ||
            $token eq "norules"                       ||
            $token eq "packaka"                       ||
            $token eq "pktsize"                       ||
            $token eq "reducedseenby"                 ||
            $token eq "rescangrp"                     ||
            $token eq "rescanlimit"                   ||
            $token eq "sendnotifymessages"            ||
            $token eq "unsubscribeonareadelete"       ||
            $token eq "notic"                         ||
            $token eq "autofilecreatesubdirs"         ||
            $token eq "delnotreceivedtic"             ||
            $token eq "tickerpacktobox"               ||
            $token eq "linkfilebasedir"               ||
            $token eq "filefix"                       ||
            $token eq "filefixfsc87subset")
        {
            $index[$j++] = $i;
            next;
        } ## end if($token eq "email" ||...)
        last;
    } ## end for(my $i = $index[0] +...)

    if($backup)
    {
        # Copy "$file" to "$file.bak"
        my $bak = "$file.bak";
        cp($file, $bak);
    }

    if($delete)
    {
        # Delete the lines of the $link definition
        for(my $i = @index - 1; $i >= 0; $i--)
        {
            splice(@lines, $index[$i], 1);
        }
        put($all, "Link $link $sysop was deleted");
    }
    else
    {
        # Comment out the $link definition
        for(my $i = 0; $i < @index; $i++)
        {
            $lines[$index[$i]] = "$commentChar $lines[$index[$i]]";
        }
        put($all, "Link $link $sysop was commented out");
    }

    # Write the changed configuration file back
    writeConfig($file, @lines) if(!$dryrun);
} ## end sub rmLinkDefinition

=head2 publishReport($subject, $fromname, $rheader, $rfooter)

The subroutine publishes a report of all actions done after initialization using
init(). The report is posted to an echo or netmail area and depends on C<$report>
package variable. If C<$report> is not defined, the subroutine does nothing. If
it is defined but it is an empty string, the area name is taken from C<reportTo>
fidoconfig statement. If the latter is not defined, no report is sent. If the
area name is defined by C<reportTo>, the report is sent to that area. If the
area name is defined by C<$report>, the report is sent to that area regardless
of C<reportTo>.

The subroutine has 4 arguments:

    $subject  - the subject of the report message;

    $fromname - the message sender name;

    $rheader  - a reference to an array of lines that will be placed before
                the report;

    $rfooter  - a reference to an array of lines that will be placed after
                the report;

If the variable C<$listreport> is true, the list of deleted files is included
in the report.

=cut

sub publishReport
{
    return if(!$report);
    if(!$hpt)
    {
        put($all, "hpt is not accessible, so publishing a report is skipped");
        return;
    }

    my ($subject, $fromname, $rheader, $rfooter) = @_;
    lastError("Report subject is not defined, no report is published")
      if(!$subject);
    unshift(@reportLines, @$rheader) if(@$rheader);
    push(@reportLines, @$rfooter) if(@$rfooter);
    my $dir = tempdir(CLEANUP => 1);
    my ($fh, $reportfile) = tempfile(DIR => $dir);
    map {print $fh "$_\n";} @reportLines;
    $fh->flush();
    @reportLines = ();

    my $cmd = "$hpt post ";
    my $msg;
    $cmd .= "-nf \"$fromname\" " if($fromname);
    if($reportToEcho)
    {
        $cmd .= "-e \"$report\" -af \"$address\" -nt \"All\"";
        $cmd .= " -s \"$subject\" -z \"Husky::Rmfiles\"";
        $cmd .= " -f loc -x \"$reportfile\"";
        $msg = "A report was sent to $report echo";
    }
    else
    {
        my ($path, $sysop);
        $commentChar = '#';
        ($path, $sysop) = findTokenValue($fidoconfig, "sysop");
        $cmd .= "-af \"$address\" -nt \"$sysop\" -at \"$address\"";
        $cmd .= " -s \"$subject\" -z \"Husky::Rmfiles\"";
        $cmd .= " -f loc \"$reportfile\"";
        $msg = "A report was sent to netmail";
    }

    $ENV{FIDOCONFIG} = normalize($fidoconfig);
    if(getOS() eq 'UNIX')
    {
        my $exitcode = system("$cmd");
        lastError("system(\"$cmd\") failed: $!") if(($exitcode >> 8) != 0);
        put(6, $msg);
    }
    else
    {
        my $postdir = tempdir(CLEANUP => 1);
        my ($ph, $postcmd) = tempfile("postXXXXXX", DIR => $postdir, SUFFIX => ".bat");
        print $ph "\@$cmd\n";
        $ph->flush();
        my $exitcode = system("$postcmd");
        lastError("system(\"$postcmd\") failed: $!") if(($exitcode >> 8) != 0);
        put(6, $msg);
    }
} ## end sub publishReport

1;

__END__

=head1 VARIABLES

=head2 $fidoconfig

It must be the full path to fidoconfig. The value is required.

=head2 $link

It is a 3D or 4D FTN address of your link. The value is required only when
you want to delete files of a specific link.

=head2 $huskyBinDir

It is the directory where hpt and htick binaries reside. You MUST use the
variable if hpt and htick are not in your PATH.

=head2 $report

The echomail or netmail area name to post report to. If it is an empty string,
the area name will be taken from C<ReportTo> fidoconfig statement. If C<$report>
is undefined, no report will be issued.

=head2 $log

A filename (without directory part) of the file to which information about
the actions will be logged. The directory is configured by C<LogFileDir>
fidoconfig statement. If C<$log> is undefined, there will be no log file.

=head2 $quiet

A boolean value. If it is true, the information about actions will not be
printed to terminal.

=head2 $netmail

A boolean value. If it is true, netmail will not be deleted.

=head2 $echomail

A boolean value. If it is true, echomail will not be deleted.

=head2 $fileecho

A boolean value. If it is true, fileechomail will not be deleted.

=head2 $otherfile

A boolean value. If it is true, the files in the link's filebox that cannot be
attributed to netmail, echomail or fileechos will not be deleted.

=head2 $filebox

A boolean value. If it is true, the link's filebox directory is not deleted
even if the directory is empty.

=head2 $listterm

A boolean value. If it is true, the list of deleted files is printed to terminal.

=head2 $listlog

A boolean value. If it is true, the list of deleted files is printed to the log file.

=head2 $listreport

A boolean value. If it is true, the list of deleted files is printed to report.

=head2 $delete

A boolean value. If it is true, the link definition is deleted, otherwise it is
commented out.

=head2 $backup

A boolean value. If it is true, a backup file with ".bak" file extension is
created before changing the configuration file with the link definition.

=head2 $dryrun

A boolean value. If it is true, no deletions and no changes are made but the
information on the actions that would be done is printed.

=head1 RESTRICTIONS

5D FTN addresses and SeparateBundles fidoconfig keyword are not supported.

=head1 AUTHOR

Michael Dukelsky 2:5020/1042.

=cut
