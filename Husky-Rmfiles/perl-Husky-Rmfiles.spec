%global ver_major 1
%global ver_minor 10
%global relnum 1

%global module Husky-Rmfiles
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
Summary: Delete files from ASO, BSO, fileboxes etc; delete links from fidoconfig
URL: https://github.com/huskyproject/%module/archive/v%ver_major.%ver_minor.tar.gz
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
BuildRequires: perl(Cwd.pm)
BuildRequires: perl(Fidoconfig/Token.pm)
BuildRequires: perl(File/Compare.pm)
BuildRequires: perl(File/Copy.pm)
BuildRequires: perl(File/Path.pm)
BuildRequires: perl(File/Spec/Functions.pm)
BuildRequires: perl(Module/Build.pm)
BuildRequires: perl(Test/More.pm)
Requires: hpt >= 1.9.0
Requires: perl(Carp.pm)
Requires: perl(Config.pm)
Requires: perl(Fcntl.pm)
Requires: perl(Fidoconfig/Token.pm)
Requires: perl(File/Basename.pm)
Requires: perl(File/Copy.pm)
Requires: perl(File/Find.pm)
Requires: perl(File/Spec/Functions.pm)
Requires: perl(File/Temp.pm)
Requires: perl(IO/Handle.pm)
Requires: perl(POSIX.pm)
%else
BuildRequires: perl(Cwd)
BuildRequires: perl(Fidoconfig::Token)
BuildRequires: perl(File::Compare)
BuildRequires: perl(File::Copy)
BuildRequires: perl(File::Path)
BuildRequires: perl(File::Spec::Functions)
BuildRequires: perl(Module::Build)
BuildRequires: perl(strict)
BuildRequires: perl(Test::More)
BuildRequires: perl(warnings)
Requires: hpt >= 1.9.0
Requires: perl(Carp)
Requires: perl(Config)
Requires: perl(Fcntl)
Requires: perl(Fidoconfig::Token)
Requires: perl(File::Basename)
Requires: perl(File::Copy)
Requires: perl(File::Find)
Requires: perl(File::Spec::Functions)
Requires: perl(File::Temp)
Requires: perl(IO::Handle)
Requires: perl(POSIX)
Requires: perl(strict)
Requires: perl(warnings)
%endif

%description
Husky::Rmfiles contains Perl functions for deleting files from Amiga Style
Outbound, BinkleyTerm Style Outbound, fileecho passthrough directory,
fileboxes, htick busy directory and also deleting links given fidoconfig as
configuration file(s). Fidoconfig is common configuration of Husky Fidonet
software. All necessary configuration information is taken from fidoconfig
using Fidoconfig::Token package.

%prep
%setup -q -n %module

%build
perl ./Build.PL \
 --install_path lib=%_datadir/perl5 \
 --install_path arch=%_libdir/perl5 \
 --install_path libdoc=%_mandir/man3
./Build

%install
umask 022
./Build install --destdir %buildroot
chmod -R a+rX,u+w,go-w %buildroot

%check
./Build test

%files
%defattr(-,root,root)
%_datadir/perl5/*
%_mandir/man3/*
%exclude %_libdir/perl5/*
