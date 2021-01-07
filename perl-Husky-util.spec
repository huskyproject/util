%global ver_major 1
%global ver_minor 8
%global relnum 1

%global module Husky-util
%global debug_package %nil

# for generic build; will override for some distributions
%global vendor_prefix %nil
%global vendor_suffix %nil
%global pkg_group Applications/Communications

# for CentOS, Fedora and RHEL
%if %_vendor == "redhat"
    %global vendor_suffix %dist
%endif

# for ALT Linux
%if %_vendor == "alt"
    %global vendor_prefix %_vendor
    %global pkg_group Networking/FTN
%endif

Name: perl-%module
Version: %ver_major.%ver_minor
Release: %{vendor_prefix}%relnum%{vendor_suffix}
%if %_vendor != "redhat"
Group: %pkg_group
%endif
Summary: Perl scripts for Husky Fidonet project
URL: https://github.com/huskyproject/util/archive/v%ver_major.%ver_minor.tar.gz
License: perl
Source: %module-%ver_major.%ver_minor.tar.gz
BuildArch: noarch
%if %_vendor == "redhat"
BuildRequires: perl(:VERSION) >= 5.8.8
Requires: perl(:VERSION) >= 5.8.8
%else
BuildRequires: perl >= 5.8.8
Requires: perl >= 5.8.8
%endif
%if %_vendor == "alt"
Requires: perl(Config.pm)
Requires: perl(Cwd.pm)
Requires: perl(Fcntl.pm)
Requires: perl(Fidoconfig/Token.pm) >= 2.5
Requires: perl(File/Basename.pm)
Requires: perl(File/Find.pm)
Requires: perl(File/Spec/Functions.pm)
Requires: perl(Getopt/Long.pm)
Requires: perl(Husky/Rmfiles.pm) >= 1.10
Requires: perl(Pod/Usage.pm)
%else
Requires: perl(Config)
Requires: perl(Cwd)
Requires: perl(Fcntl)
Requires: perl(Fidoconfig::Token) >= 2.5
Requires: perl(File::Basename)
Requires: perl(File::Find)
Requires: perl(File::Spec::Functions)
Requires: perl(Getopt::Long)
Requires: perl(Husky::Rmfiles) >= 1.10
Requires: perl(Pod::Usage)
Requires: perl(strict)
Requires: perl(warnings)
%endif

%description
Four Perl utilities using functions from Fidoconfig::Token and Husky::Rmfiles
packages: showold.pl, rmLinkMail.pl, rmLink.pl, fixOutbound.pl.
showold.pl     - prints out to STDOUT how much netmail, echomail and files
                 are stored for every link in the outbound and fileboxes and
                 for how long they are stored;
rmLinkMail.pl  - remove netmail, echomail and files of a link;
rmLink.pl      - remove a link;
fixOutbound.pl - remove from outbound the echomail bundles not referred
                 by any flow file.

%prep
%setup -q -n util

%build
perl ./Build.PL \
 --install_path script=%_bindir \
 --install_path bindoc=%_mandir/man1
./Build

%install
umask 022
./Build install --destdir %buildroot
chmod -R a+rX,u+w,go-w %buildroot

%check
./Build test

%files
%defattr(-,root,root)
%doc README.md
%_bindir/*.pl
%_mandir/man1/*
