#
# Perl functions for accessing values of single fidoconfig tokens.
# Fidoconfig is common configuration of Husky Fidonet software.
#
# It is free software and license is the same as for Perl,
# see http://dev.perl.org/licenses/
#
package Fidoconfig::Token;
our (@ISA, @EXPORT, $VERSION, $commentChar, $module);

# The package version
$VERSION = "2.2";

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(findTokenValue findAllTokenValues getOS normalize stripSpaces
             stripQuotes stripComment expandVars isOn $commentChar $module);
@EXPORT_OK = qw(cmpPattern boolExpr parseIf searchTokenValue);
use Config;
use File::Spec::Functions;
use Carp;
use strict;
use warnings;

=head1 NAME

Fidoconfig::Token - access single fidoconfig tokens.

=head1 SYNOPSYS

    use Fidoconfig::Token;
    $module = "hpt";
    $commentChar = '#';
    my ($file, $value) = findTokenValue("myconfig.cfg", "ProtInbound");

This finds C<ProtInbound> token in C<myconfig.cfg> file or in an included file.
The token value is now in the C<$value> variable and the file where it was found is
in C<$file>.

    $commentChar = '#';
    my ($file, $value, $linenumber, @lines) =
        findTokenValue("links.cfg", "AKA", "eq", "1:23/456");

This finds the file which has "aka 1:23/456" line, the value (it is "1:23/456"),
the zero-based number of the found line and the array of all lines of the file.
The search starts in "links.cfg" file.

    $commentChar = '#';
    my ($file, $value, $linenumber, @lines) =
        findTokenValue("areas.cfg", "EchoArea", "=~", qr/^(ru\.anecdot)\s/i);

This finds the file which has "EchoArea ru.anecdot ..." line, the value (it is
"ru.anecdot"), the zero-based number of the found line and the array of all
lines of the file. The search starts in "areas.cfg" file.

    $commentChar = '#';
    my @values = findAllTokenValues("areas.cfg", "EchoArea", qr/^ru\.fidonet/i);

The @values array will contain area lines (the lines will start with areaname) of all
echoareas with areaname starting with "ru.fidonet".

=head1 DESCRIPTION

Fidoconfig::Token contains Perl functions for accessing single fidoconfig settings.
Fidoconfig, in turn, is a common configuration of Husky Fidonet software. Every
line of a Husky configuration starts with some token. The rest of the line that
follows the token after at least one space or tab is the token value.

Variables and subroutines you may import from Fidoconfig::Token are described below.

=head1 Variables

=over 4

=item *

C<module> - it is the program name to which some configuration chunk
            belongs. It can be either C<hpt> or C<htick>.

=item *

C<commentChar> - the character used to mark a comment. On default C<'#'> is used
                 in fidoconfig so if you start searching a token from the main 
                 file, which may be the value of C<FIDOCONFIG> environment
                 variable, then you must set C<$commentChar>
                 to C<'#'>.

=back

=head1 Subroutines

Fidoconfig::Token package has several subroutines you may use.

=head2 findTokenValue($tokenFile, $token, $mode, $desiredValue)

findTokenValue() may be used with four or with two string arguments. It depends
on what kind of token you look for.

There are tokens that cannot be repeated in fidoconfig and thus can have only
one value for a chosen module (hpt or htick). You may want to fetch the value
of such a token and findTokenValue() with two arguments is enough for such a task.

   my ($file, $value) = findTokenValue($tokenFile, $token);

C<$tokenFile> is the file from which we want to start searching for the token
and C<$token> is the token whose value we want to find. If all you want to know
is the token value, the subroutine returns for you a list of two strings: the
first is the file where the token was found and the second is the value of the
found token.
The resulting file may not coincide with the source file if the
source file contains an C<include> directive. In fact findTokenValue() returns
not two but four strings. 

   my ($file, $value, $linenumber, @lines) = findTokenValue($tokenFile, $token);

The two additional strings are the zero-based line
number where the token is found and the array of lines of the whole file where
the token is found. These two additional results may be useful if you want to
know the token position in the file.

There are also tokens with multiple entries in fidoconfig, for example 'AKA'.
Every link definition must have this token. For such type of token you may want
to find the token with some specific value. This task is addressed by
findTokenValue() with four arguments.

   my ($file, $value, $linenumber, @lines) = 
       findTokenValue($tokenFile, $token, $mode, $desiredValue);

The first two arguments are the same as in the previous case. The last argument
is the specific value you want to find and the third argument is a comparison
mode of how you want to compare the value the token has in yet another line and
your desired value.

There are two comparison modes, both of them are case insensitive. The first is
'eq' for testing for equality and the second is '=~' used when you want to see
whether the actual token value contains the desired value. In case of '=~'
comparison mode the last argument is a Perl regular expression. So you should
use qr/.../i to define your regular expression. The /i modifier is required
here. The four returned values were described above.

If you use unnamed capturing parentheses in the regular expression in the last
argument, the value captured by the first parentheses pair is issued
as the second of the four return values (it is indicated as $value in the example
above). Only the first capturing parentheses pair is used.

If the token given by the second argument was not found, the second return value
(it is indicated as $value in the example above) is an empty string and the third
and the fourth return values are undefined. If the token was found but with
empty value, then a string C<on> is returned as the second return value.

You have to assign values to two package variables before calling this subroutine.
They are C<$module> and C<$commentChar>. The first one is never changed inside
your configuration. The second one may be changed in your fidoconfig.

=cut

my (@condition, $ifLevel);

sub findTokenValue
{
    my ($tokenFile, $token, $mode, $desiredValue, @bad) = @_;
    getOS();
    croak("findTokenValue(): extra arguments") if(@bad);
    croak("findTokenValue(): the fourth argument is not defined") if(defined($mode) && !defined($desiredValue));
    if(defined($desiredValue) && $mode eq '=~')
    {
        eval {$desiredValue} or
            croak("findTokenValue(): the fourth argument is incorrect");
    }
    $ifLevel = 0;
    @condition = ();
    my ($file, $value, $linenum, @lines) = searchTokenValue($tokenFile, $token, $mode, $desiredValue);
    return ($file, $value, $linenum, @lines);
}


=head2 findAllTokenValues($tokenFile, $token, $desiredValue)

findAllTokenValues finds all values the token has in all files starting with the
file in the first argument. It is always used with three arguments.

    my @values = findAllTokenValues($tokenFile, $token, $desiredValue);

Unlike findTokenValue() there is no mode argument since "=~" comparison mode is
always used here. The last argument is a Perl regular expression qr/.../i with
required /i modifier.

=cut

sub findAllTokenValues
{
    my ($tokenFile, $token, $desiredValue, @bad) = @_;
    getOS();
    croak("findAllTokenValues(): extra arguments\n") if(@bad);
    croak("findAllTokenValues(): the third argument is not defined\n") unless(defined($desiredValue));
    eval {$desiredValue} or 
        croak("findAllTokenValues(): the third argument is incorrect\n");
    $ifLevel = 0;
    @condition = ();
    my ($file, @values) = searchAllTokenValues($tokenFile, $token, $desiredValue);
    return @values;
}

=head2 getOS()

getOS() has no arguments. It checks that the current operating system is
supported by the Fidoconfig::Token package and croaks if it is not. If
the operating system is supported, it returns one of the following strings:

=over 4

=item *

C<WIN> - for Windows family of operating systems;

=item *

C<DOS> - for DOS;

=item *

C<OS/2> - for OS/2;

=item *

C<UNIX> - for UNIX-like operating systems (Linux, OS X, *BSD and others).

=back

=cut

sub getOS
{
    my $OS;
    unless ($OS = $^O)
    {
        $OS = $Config::Config{'osname'};
    }

    if($OS =~ /^MSWin/i)
    {
        $OS = 'WIN';
    }
    elsif($OS =~ /^dos/i)
    {
        $OS = 'DOS';
    }
    elsif($OS =~ /^os2/i)
    {
        $OS = 'OS/2';
    }
    elsif($OS =~ /^VMS/i or $OS =~ /^MacOS/i or $OS =~ /^epoc/i or $OS =~ /NetWare/i)
    {
        croak("$OS is not supported");
    }
    else
    {
        $OS = 'UNIX';
    }
    $ENV{OS} = $OS;
    return $OS;
}

=head2 normalize($path)

The argument is some path which under non-UNIX OS may contain both C<\> and C</>.
The subroutine returns the path containing only C<\>. The subroutine returns its
argument without changes under a UNIX-like OS.

=cut

sub normalize
{
    my ($path, @bad) = @_;
    croak("normalize(): extra arguments") if(@bad);
    return $path if(getOS() eq 'UNIX');
    return canonpath($path);
}

=head2 stripSpaces(@lines)

stripSpaces(@lines) returns the array, every element of which
is stripped of heading and trailing white spaces.

=cut

sub stripSpaces
{
    my @arr = @_;
    foreach (@arr)
    {
        next unless $_;
        s/^\s+//;
        s/\s+$//;
    }
    return @arr;
}

=head2 stripQuotes(@lines)

stripQuotes(@lines) returns the array, every element of which
is stripped of a pair of heading and trailing double quote character.

=cut

sub stripQuotes
{
    my @arr = @_;
    foreach (@arr)
    {
        next unless $_;
        s/^\"(.+)\"$/$1/;
    }
    return @arr;
}

=head2 stripComment(@lines)

stripComment(@lines) returns an array of lines with stripped comment in every line.

=cut

sub stripComment
{
    my @arr = @_;
    foreach (@arr)
    {
        next unless $_;
        next if(s/^\s*$commentChar.*$//);
        s/\s$commentChar\s.*$//;
    }
    return @arr;
}

=head2 expandVars($expression)

expandVars($expression) executes commands in backticks found in the
C<$expression> (only under UNIX or OS/2), substitutes environment
variables by their values and returns the resulting string.

=cut

sub expandVars
{
    my ($expr, @bad) = @_;
    croak("expandVars(): extra arguments") if(@bad);
    return undef if(!defined($expr));
    my ($result, $left, $cmd, $var, $remainder);

    ($expr) = stripSpaces($expr);
    return "" if($expr eq "");

    # check whether number of backticks (\x60) is even
    my $number = $expr =~ tr/\x60//;
    my $OS = getOS();
    if(($OS eq 'UNIX' or $OS eq 'OS/2') && 
        $number != 0 &&
        int($number / 2) * 2 == $number)
    {
        # execute command in backticks
        $cmd = 1;
        $result = "";
        while ($cmd)
        {
            ($left, $cmd, $remainder) = split /\x60/, $expr, 3;
            $left = "" if(!defined($left));
            $cmd = "" if(!defined($cmd));
            $remainder = "" if(!defined($remainder));
            if($cmd)
            {
                $result .= $left . eval('`' . $cmd . '`');
                $result =~ s/[\r\n]+$//;
                last unless $remainder;
                $expr = $remainder;
            }
            else
            {
                $result .= $expr;
            }
        }
        $expr = $result;
    }

    # substitute environment variables by their values
    $var = 1;
    $result = "";
    while ($var)
    {
        ($left, $var, $remainder) = $expr =~ /^(.*)\[([a-z_][a-z0-9_]*)\](.*)$/i;
        $left = "" if(!defined($left));
        $var = "" if(!defined($var));
        $remainder = "" if(!defined($remainder));
        if($var)
        {
            $result =
                (
                 lc($var) eq "module"
                 ? "module"
                 : ($ENV{$var} ? $ENV{$var} : "")
                ) . $remainder . $result;
            last unless $left;
            $expr = $left;
        }
        else
        {
            $result = $expr . $result;
        }
    }
    return $result;
}

# cmpPattern($string, $pattern) compares $string with $pattern
# and returns boolean result of the comparison. The pattern
# may contain wildcard characters '?' and '*'.

sub cmpPattern
{
    my ($string, $pattern, @bad) = @_;
    croak("cmpPattern(): extra arguments") if(@bad);
    croak("cmpPattern(): string not defined") if(!defined($string));
    croak("cmpPattern(): pattern not defined") if(!defined($pattern));
    $pattern =~ s/\?/./g;
    $pattern =~ s/\*/.*/g;
    return $string =~ /^$pattern$/;
}

# boolExpr($expression) computes the boolean expression and returns boolean result.

sub boolExpr
{
    my ($expr, @bad) = @_;
    croak("boolExpr(): extra arguments") if(@bad);
    my ($result, $not, $left, $right);
    $result = $not = "";

    ($expr) = stripSpaces($expr);
    if($expr =~ /^not\s+(.+)$/i)
    {
        $not = 1;
        $expr = $1;
    }

    if($expr =~ /^(.+)==(.+)$/)
    {
        ($left, $right) = stripSpaces($1, $2);
        if(lc($left) eq "module")
        {
            $result = lc($right) eq $module;
        }
        elsif(lc($right) eq "module")
        {
            $result = lc($left) eq $module;
        }
        else
        {
            $result = $left eq $right;
        }
    }
    elsif($expr =~ /^(.+)!=(.+)$/)
    {
        ($left, $right) = stripSpaces($1, $2);
        $result = $left ne $right;
    }
    elsif($expr =~ /^(.+)=~(.+)$/)
    {
        $result = cmpPattern(stripSpaces($1, $2));
    }
    elsif($expr =~ /^(.+)!~(.+)$/)
    {
        $result = not cmpPattern(stripSpaces($1, $2));
    }

    return $not ? not $result : $result;
}

# parseIf($line) parses $line for conditional operators
# and returns 1 if the line should be skipped else 0.
sub parseIf
{
    my ($line, @bad) = @_;
    croak("parseIf(): extra arguments") if(@bad);

    return 1 if($line eq "");

    if($line =~ /^if\s+(.+)$/i)
    {
        $ifLevel++;
        return 1 if(@condition and not $condition[-1]);
        push @condition, boolExpr(expandVars($1));
        return 1;
    }
    elsif($line =~ /^ifdef\s+(.+)$/i)
    {
        $ifLevel++;
        return 1 if(@condition and not $condition[-1]);
        my $var = expandVars($1);
        push @condition, ($var ? 1 : 0);
        return 1;
    }
    elsif($line =~ /^ifndef\s+(.+)$/i)
    {
        $ifLevel++;
        return 1 if(@condition and not $condition[-1]);
        my $var = expandVars($1);
        push @condition, ($var ? 0 : 1);
        return 1;
    }
    elsif($line =~ /^elseif\s+(.+)$/i or $line =~ /^elif\s+(.+)$/i)
    {
        return 1 if(@condition != $ifLevel);
        pop @condition;
        push @condition, boolExpr(expandVars($1));
        return 1;
    }
    elsif($line =~ /^else$/i)
    {
        return 1 if(@condition != $ifLevel);
        push @condition, not pop(@condition);
        return 1;
    }
    elsif($line =~ /^endif$/i)
    {
        pop @condition if(@condition == $ifLevel--);
        return 1;
    }

    return 1 if($ifLevel and not $condition[-1]);
    return 0;
}

sub searchTokenValue
{
    my ($tokenFile, $token, $mode, $desiredValue, @bad) = @_;
#    croak("searchTokenValue(): extra arguments") if(@bad);
#    croak("searchTokenValue(): the fourth argument is not defined") if(defined($mode) && !defined($desiredValue));
    $desiredValue = "on" if(defined($desiredValue) && isOn($desiredValue));
    my $value = "";
    my $cmp;
    if(defined($mode))
    {
        ($desiredValue) = stripSpaces($desiredValue);
        if($mode eq 'eq')
        {
            $cmp = sub {$value eq $desiredValue};
        }
        else
        {
            $cmp = sub
            {
                my $res = $value =~ m/$desiredValue/;
                $value = $1 if($res && $1);
                return $res;
            };
        }
    }

    ($tokenFile) = stripQuotes(stripSpaces($tokenFile));
    open(FIN, "<", $tokenFile) or croak("$tokenFile: $!");
    my @lines = <FIN>;
    close FIN;

    my $i;
    for($i = 0; $i < @lines; $i++)
    {
        my $line = $lines[$i];
        ($line) = stripSpaces(stripComment($line));
        next if(parseIf($line));

        $line = expandVars($line);

        if($line =~ /^$token\s+(.+)$/i)
        {
            ($value) = stripSpaces($1);
            $value = "on" if(isOn($value));
            if(defined($mode))
            {
                if($cmp->())
                {
                    last;
                }
                else
                {
                    $value = "";
                    next;
                }
            }
            last;
        }
        elsif($line =~ /^$token$/i)
        {
            $value = "on";
            if(defined($mode))
            {
                if($cmp->())
                {
                    last;
                }
                else
                {
                    $value = "";
                    next;
                }
            }
            last;
        }
        elsif($line =~ /^include\s+(.+)$/i)
        {
            my ($newTokenFile, $index, @newlines);
            ($newTokenFile, $value, $index, @newlines) = searchTokenValue($1, $token, $mode, $desiredValue);
            if($value and $newTokenFile)
            {
                $tokenFile = $newTokenFile;
                $i = $index;
                @lines = @newlines;
                last;
            }
        }
        elsif($line =~ /^set\s+(.+)$/i)
        {
            my ($var, $val) = stripSpaces(split(/=/, $1));
            ($val) = stripQuotes($val);
            if($val)
            {
                $ENV{$var} = $val;
            }
            else
            {
                delete $ENV{$var};
            }
        }
        elsif($line =~ /^commentChar\s+(\S)$/i)
        {
            $commentChar = $1;
        }
    } ## end for
    if(!$value)
    {
        $i = undef;
        @lines = ();
    }
    return ($tokenFile, $value, $i, @lines);
} ## end sub searchTokenValue

sub searchAllTokenValues
{
    my ($tokenFile, $token, $desiredValue, @bad) = @_;
    croak("searchTokenValue(): extra arguments") if(@bad);
    croak("searchTokenValue(): the third argument is not defined") unless(defined($desiredValue));
    ($desiredValue) = stripSpaces($desiredValue);
    $desiredValue = lc($desiredValue);
    $desiredValue = "on" if(isOn($desiredValue));
    my $value = "";
    my $cmp = sub
    {
        my $res = $value =~ m/$desiredValue/;
        $value = $1 if($res && $1);
        return $res;
    };


    ($tokenFile) = stripQuotes(stripSpaces($tokenFile));
    open(FIN, "<", $tokenFile) or croak("$tokenFile: $!");
    my @lines = <FIN>;
    close FIN;

    my @values;
    for my $line (@lines)
    {
        ($line) = stripSpaces(stripComment($line));
        next if(parseIf($line));

        $line = expandVars($line);

        if($line =~ /^$token\s+(.+)$/i)
        {
            ($value) = stripSpaces($1);
            $value = lc($value);
            $value = "on" if(isOn($value));
            push(@values, $value) if($cmp->());
            $value = "";
            next;
        }
        elsif($line =~ /^$token$/i)
        {
            $value = "on";
            push(@values, $value) if($cmp->());
            $value = "";
            next;
        }
        elsif($line =~ /^include\s+(.+)$/i)
        {
            my @newValues = searchAllTokenValues($1, $token, $desiredValue);
            push(@values, @newValues) if(@newValues);
        }
        elsif($line =~ /^set\s+(.+)$/i)
        {
            my ($var, $val) = stripSpaces(split(/=/, $1));
            ($val) = stripQuotes($val);
            if($val)
            {
                $ENV{$var} = $val;
            }
            else
            {
                delete $ENV{$var};
            }
        }
        elsif($line =~ /^commentChar\s+(\S)$/i)
        {
            $commentChar = $1;
        }
    } ## end for my $line (@lines)
    return @values;
} ## end sub searchAllTokenValues

=head2 isOn($value)

isOn($value) returns 1 if the $value is the string representing C<true>
according to Husky fidoconfig rules, otherwise it returns 0.

=cut

sub isOn
{
    my ($val) = @_;
    return 1 if($val eq "1" or lc($val) eq "yes" or lc($val) eq "on");
    return 0;
}

1;

__END__


=head1 AUTHOR

Michael Dukelsky 2:5020/1042

=head1 LICENSE

It is free software and license is the same as for Perl,
see http://dev.perl.org/licenses/

=cut
