#!/usr/bin/perl
#
# Display outbound summary for every link
# for which there is anything in the outbound
# Created by Pavel Gulchouck 2:463/68@fidonet
# Fixed by Stas Degteff 2:5080/102@fidonet
# Modified by Michael Dukelsky 2:5020/1042@fidonet
#

##### There is nothing to change below this line #####
use File::Spec::Functions;
use File::Find;
use Config;
use Fidoconfig::Token;
use strict;
use warnings;

our $VERSION = "2.2";

my ($fidoconfig, $module, $defZone, 
    $defOutbound, @dirs, @boxesDirs, @asoFiles,
    %minmtime, %netmail, %echomail, %files);
my $commentChar = '#';
my $Mb = 1024 * 1024;
my $Gb = $Mb * 1024;

sub usage
{
    print <<USAGE;

    The script showold.pl prints out to STDOUT how much netmail, echomail 
    and files are stored for every link in the outbound and fileboxes and 
    for how long they are stored.

    If FIDOCONFIG environment variable is defined, you may use the script
    without arguments, otherwise you have to supply the path to fidoconfig
    as an argument.

    Usage:
        perl showold.pl
        perl showold.pl <path to fidoconfig>

    Example:
        perl showold.pl M:\\mail\\Husky\\config\\config
USAGE
    exit 1;
}

sub nodesort
{   my ($az, $an, $af, $ap, $bz, $bn, $bf, $bp);
    if ($a =~ /(\d+):(\d+)\/(\d+)(?:\.(\d+))?$/)
    {
        ($az, $an, $af, $ap) = ($1, $2, $3, $4);
    }
    if ($b =~ /(\d+):(\d+)\/(\d+)(?:\.(\d+))?$/)
    {
        ($bz, $bn, $bf, $bp) = ($1, $2, $3, $4);
    }
    return ($az<=>$bz) || ($an<=>$bn) || ($af<=>$bf) || ($ap<=>$bp);
}

sub unbso
{
    my ($file, $dir) = @_;
    my $zone;
    if($dir =~ /\.([0-9a-f])([0-9a-f])([0-9a-f])$/i)
    {
        $zone = hex("$1")*256 + hex($2)*16 + hex($3);
    }
    else
    {
        $zone = $defZone;
    }
    if ($file =~ /([0-9a-f]{4})([0-9a-f]{4})\.pnt\/([0-9a-f]{8})/i)
    {
        return sprintf "%u:%u/%d.%d", $zone, hex("$1"), hex("$2"), hex("$3");
    } 
    elsif ($file =~ /([0-9a-f]{4})([0-9a-f]{4})/i)
    {
        return sprintf "%u:%u/%d", $zone, hex("$1"), hex("$2");
    }
    else
    {
        return "";
    }
}

sub unaso
{
    my ($file) = @_;
    if($file =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/)
    {
        if($4 == 0)
        {
            return "$1:$2\/$3";
        }
        else
        {
            return "$1:$2\/$3\.$4";
        }
    }
    else
    {
        return "";
    }
}

sub unbox
{
    my ($dir) = @_;
    if($dir =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)(?:\.h)?$/i)
    {
        return $4 == 0 ? "$1:$2\/$3" : "$1:$2\/$3\.$4";
    }
    else
    {
        return "";
    }
}

sub niceNumber
{
    my ($num) = @_;
    return ($num < $Mb ? $num : ($num >= $Mb && $num < $Gb ? $num/$Mb : $num/$Gb));
}

sub niceNumberFormat
{
    my ($num) = @_;
    return "%9u " if ($num < $Mb);

    my $len = length(sprintf "%4.4f", niceNumber($num));
    return ($len < 9 ? " " x (9 - $len) . "%4.4f" : "%4.4f") . 
           ($num < $Gb ? "M" : "G");
}

sub selectOutbound
{
    if (-d $File::Find::name && $File::Find::name =~ /\.[0-9a-f]{3}$/i)
    {
        push(@dirs, normalize($File::Find::name));
    }
}

sub listOutbounds
{
    my ($dir) = @_;
    my ($volume, $directories, $file) = File::Spec->splitpath(normalize($dir));
    if($file eq "")
    {
        my @dirs = File::Spec->splitdir($directories);
        $file = pop @dirs;
        $directories = File::Spec->catdir(@dirs);
    }
    my $updir=File::Spec->catpath($volume, $directories, "");
    @dirs=($dir);

    find(\&selectOutbound, $updir);
    return @dirs;
}

sub selectFileInASO
{
    if (-f $File::Find::name && -s $File::Find::name &&
        ($File::Find::name =~ /\d+\.\d+\.\d+\.\d+\.[icdoh]ut$/i ||
         $File::Find::name =~ /\d+\.\d+\.\d+\.\d+\.(su|mo|tu|we|th|fr|sa)[0-9a-z]$/i))
    {
        push(@asoFiles, normalize($File::Find::name));
    }
}

sub listFilesInASO
{
    @asoFiles = ();
    find(\&selectFileInASO, $defOutbound);
    return @asoFiles;
}

sub selectFileBoxes
{
    if (-d $File::Find::name && $File::Find::name =~ /\d+\.\d+\.\d+\.\d+(?:\.h)?$/i)
    {
        push(@boxesDirs, normalize($File::Find::name));
    }
}

sub listFileBoxes
{
    my ($dir) = @_;
    find(\&selectFileBoxes, $dir);
    return @boxesDirs;
}

sub allFilesInBSO
{
    my ($dir) = @_;
    chdir($dir);
    my @files = <*.[IiCcDdFfHh][Ll][Oo]>;
    push @files, <*.[IiCcDdOoHh][Uu][Tt]>;
    push @files, <*.[Pp][Nn][Tt]/*.[IiCcDdFfHh][Ll][Oo]>;
    push @files, <*.[Pp][Nn][Tt]/*.[IiCcDdOoHh][Uu][Tt]>;
    return if(@files == 0);

    foreach my $file (@files)
    {
        my $node=unbso($file, $dir);
        next if($node eq "");
        my ($size, $mtime) = (stat($file))[7, 9];
        next if($size == 0);
        if (!defined($minmtime{$node}) || $mtime < $minmtime{$node})
        {
            $minmtime{$node} = $mtime if $mtime;
        }
        if ($file =~ /ut$/i)
        {
            $netmail{$node} += $size;
            next;
        }
        # unix, read only -> ignore *.bsy
        next unless open(F, "<$file");
        while (<F>)
        {
            s/\r?\n$//s;
            s/^[#~^]//;
            next unless(($size, $mtime) = (stat($_))[7, 9]);
            next if($size == 0);
            if (/[0-9a-f]{8}\.(su|mo|tu|we|th|fr|sa)[0-9a-z]$/i)
            {
                if (!defined($minmtime{$node}) || $mtime < $minmtime{$node})
                {
                    $minmtime{$node} = $mtime;
                }
                $echomail{$node} += $size;
            }
            elsif (/\.tic$/i)
            {
                if (!defined($minmtime{$node}) || $mtime < $minmtime{$node})
                {
                    $minmtime{$node} = $mtime;
                }
                $files{$node} += $size;
            }
            else
            {
                $files{$node} += $size;
            }
        }
        close(F);
    }
}

sub allFilesInASO
{
    chdir($defOutbound);
    my @files = listFilesInASO();
    return if(@files == 0);

    foreach my $file (@files)
    {
        my $node=unaso($file);
        next if($node eq "");
        my ($size, $mtime) = (stat($file))[7, 9];
        next if($size == 0);
        if (!defined($minmtime{$node}) || $mtime < $minmtime{$node})
        {
            $minmtime{$node} = $mtime if $mtime;
        }
        if ($file =~ /ut$/i)
        {
            $netmail{$node} += $size;
        }
        else
        {
            $echomail{$node} += $size;
        }
    }
}

sub allFilesInFileBoxes
{
    my ($dir) = @_;
    my $node = unbox($dir);
    next if($node eq "");
    chdir($dir);
    my @files = <*.[IiCcDdOoHh][Uu][Tt]>;
    push @files, <*.[Ss][Uu][0-9a-zA-Z]>;
    push @files, <*.[Mm][Oo][0-9a-zA-Z]>;
    push @files, <*.[Tt][Uu][0-9a-zA-Z]>;
    push @files, <*.[Ww][Ee][0-9a-zA-Z]>;
    push @files, <*.[Tt][Hh][0-9a-zA-Z]>;
    push @files, <*.[Ff][Rr][0-9a-zA-Z]>;
    push @files, <*.[Ss][Aa][0-9a-zA-Z]>;
    return if(@files == 0);

    foreach my $file (@files)
    {
        my ($size, $mtime) = (stat($file))[7, 9];
        next if($size == 0);
        if (!defined($minmtime{$node}) || $mtime < $minmtime{$node})
        {
            $minmtime{$node} = $mtime if $mtime;
        }

        if ($file =~ /ut$/i)
        {
            $netmail{$node} += $size;
            next;
        }
        elsif ($file =~ /\.(su|mo|tu|we|th|fr|sa)[0-9a-z]$/i)
        {
            # Both BSO and ASO style echomail bundles are handled here
            if (!defined($minmtime{$node}) || $mtime < $minmtime{$node})
            {
                $minmtime{$node} = $mtime;
            }
            $echomail{$node} += $size;
        }
        else
        {
            $files{$node} += $size;
        }
    }
}


###################### The main program starts here ##########################

# Just check that the current OS is supported
getOS();

$fidoconfig = $ENV{FIDOCONFIG} if defined $ENV{FIDOCONFIG};

if ((@ARGV == 1 && $ARGV[0] =~ /^(-|--|\/)(h|help|\?)$/i) || (!defined($fidoconfig) && @ARGV != 1))
{
    usage();
}

$fidoconfig = $ARGV[0] if(!defined($fidoconfig));
if (!(-f $fidoconfig && -s $fidoconfig))
{
    print "\n\'$fidoconfig\' is not a fidoconfig\n";
    usage();
}

#### Read fidoconfig ####
my ($address, $path, $fileBoxesDir);
$fidoconfig = normalize($fidoconfig);

$Fidoconfig::Token::module = "hpt";
$Fidoconfig::Token::commentChar = '#';
my $separateBundles;
($path, $separateBundles) = findTokenValue($fidoconfig, "SeparateBundles");
die "\nSeparateBundles mode is not supported\n" if(isOn($separateBundles));

($path, $address) = findTokenValue($fidoconfig, "address");
$defZone = $1 if($address ne "" && $address =~ /^(\d+):\d+\/\d+(?:\.\d+)?(?:@\w+)?$/);
defined($defZone) or die "\nYour FTN address is not defined or has a syntax error\n";

($path, $fileBoxesDir) = findTokenValue($fidoconfig, "FileBoxesDir");
if($fileBoxesDir ne "")
{
    -d $fileBoxesDir or die "\nfileBoxesDir \'$fileBoxesDir\' is not a directory\n";
    $fileBoxesDir = normalize($fileBoxesDir);
}

($path, $defOutbound) = findTokenValue($fidoconfig, "Outbound");
$defOutbound ne "" or die "\nOutbound is not defined\n";
-d $defOutbound or die "\nOutbound \'$defOutbound\' is not a directory\n";
$defOutbound = normalize($defOutbound);

@dirs = listOutbounds($defOutbound);
@boxesDirs = listFileBoxes($fileBoxesDir) if($fileBoxesDir ne "");

allFilesInASO();

foreach my $dir (@dirs)
{
    allFilesInBSO($dir);
}

foreach my $dir (@boxesDirs)
{
    allFilesInFileBoxes($dir);
}

print <<EOF;
+------------------+--------+-----------+-----------+-----------+
|       Node       |  Days  |  NetMail  |  EchoMail |   Files   |
+------------------+--------+-----------+-----------+-----------+
EOF
foreach my $node (sort nodesort keys %minmtime)
{
    $netmail{$node}  = 0 if(!defined $netmail{$node});
    $echomail{$node} = 0 if(!defined $echomail{$node});
    $files{$node}    = 0 if(!defined $files{$node});
    my $format = "| %-16s |%7u |" .
                 niceNumberFormat($netmail{$node}) . " |" .
                 niceNumberFormat($echomail{$node}) . " |" .
                 niceNumberFormat($files{$node}) . " |\n";
    printf $format,
           $node, (time()-$minmtime{$node})/(24*60*60),
           niceNumber($netmail{$node}),
           niceNumber($echomail{$node}),
           niceNumber($files{$node});
}
print "+------------------+--------+-----------+-----------+-----------+\n";
exit(0);
