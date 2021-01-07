%global ver_major 2
%global ver_minor 5
%global relnum 1

%global module Fidoconfig-Token
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
Summary: Perl functions for accessing single fidoconfig settings
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
BuildRequires: perl(Module/Build.pm)
BuildRequires: perl(Test/More.pm)
Requires: hpt >= 1.9.0
Requires: perl(Carp.pm)
Requires: perl(Config.pm)
Requires: perl(File/Spec.pm)
%else
BuildRequires: perl(Cwd)
BuildRequires: perl(Module::Build)
BuildRequires: perl(strict)
BuildRequires: perl(Test::More)
BuildRequires: perl(warnings)
Requires: hpt >= 1.9.0
Requires: perl(Carp)
Requires: perl(Config)
Requires: perl(File::Spec)
Requires: perl(strict)
Requires: perl(warnings)
%endif

%description
Fidoconfig::Token contains Perl functions for accessing single fidoconfig
settings. Fidoconfig, in turn, is a common configuration of Husky Fidonet
software. Every line of a Husky configuration starts with some token. The
rest of the line that follows the token after at least one space or tab is
the token value.

%prep
%setup -q -n %module

%build
perl ./Build.PL
./Build

%install
umask 022
./Build install --destdir %buildroot \
 --install_path lib=%_datadir/perl5 \
 --install_path arch=%_libdir/perl5 \
 --install_path libdoc=%_mandir/man3
chmod -R a+rX,u+w,go-w %buildroot

%check
./Build test

%files
%defattr(-,root,root)
%_datadir/perl5/*
%_mandir/man3/*
%exclude %_libdir/perl5/*
