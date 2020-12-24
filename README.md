Utilities
=========

Here you may find Perl utilities using functions from Fidoconfig::Token and
Husky::Rmfiles packages.

**showold.pl** - prints out to STDOUT how much netmail, echomail and files
             are stored for every link in the outbound and fileboxes and
             for how long they are stored.

**rmLinkMail.pl** - remove netmail, echomail and files of a link.

**rmLink.pl** - remove a link

**fixOutbound.pl** - remove from outbound the echomail bundles not referred
                 by any flow file

To see a short information for some-utility run

    perl some-utility --help

and to read full documentation for any utility except showold.pl run

    perldoc some-utility

Since in Windows perldoc uses more.com pager which cannot list pages backwards,
you may find it more comfortable to save the help it shows to a text file and
read it using your favorite editor.

    perldoc some-utility.pl > some-utility.txt

Before using the utilities you have to install Fidoconfig::Token and 
Husky::Rmfiles packages. Fidoconfig-Token and Husky-Rmfiles subdirectories
contain files necessary to install Fidoconfig::Token and Husky::Rmfiles
packages respectively.

Prerequisites
=============

It is supposed that hpt is installed. If your config contains FileArea lines,
then it is supposed that htick is also installed.

Installation in a UNIX-like OS
==============================

Before installing Fidoconfig::Token and Husky::Rmfiles make sure version 0.28
or newer of Module::Build is installed. If the module is not installed, you may
install it either using your OS packaging system or from CPAN:

    sudo cpanm Module::Build

To install Fidoconfig::Token package run the following:

    pushd Fidoconfig-Token
    perl Build.PL
    ./Build
    ./Build test
    sudo ./Build install
    popd

To install Husky::Rmfiles run the following:

    pushd Husky-Rmfiles
    perl Build.PL
    ./Build

The next command depends on whether hpt and htick binaries are in the PATH. If they are,
the next command is

    ./Build test

If not, you have to specify the directory where hpt and htick binaries reside.

    ./Build test directory_with_binaries

After that you may install the package.

    sudo ./Build install
    popd

Now the two packages are installed and you may copy the utilities mentioned
above (showold.pl and others) to the directory you like.


Installation in Windows
=======================

If you have Active Perl installed in Windows, Module::Build is typically already
installed. You may check it by running

    perldoc Module::Build

in the command line window. It should show the module manual. Press letter "q"
to leave the manual.

If Module::Build package is not installed, run

    ppm

in the command line window with Administrator rights to start Perl Package 
manager. After the Perl Package manager has started, select
View -> All Packages from its menu, find Module-Build package and install it.
You may now close Perl Package manager. After that you may return to the
directory with our utilities and this README file.

To install Fidoconfig::Token package run the following commands:

    pushd Fidoconfig-Token
    perl Build.PL
    Build
    Build test
    Build install
    popd

To install Husky::Rmfiles package run the following commands:

    pushd Husky-Rmfiles
    perl Build.PL
    Build

The next command depends on whether hpt and htick binaries are in the PATH. If they are,
the next command is

    Build test

If not, you have to specify the directory where hpt and htick binaries reside.

    Build test directory_with_binaries

After that you may install the package.

    Build install
    popd

If it says that you don't have a C compiler, ignore it. Now the two packages
are installed and you may copy the utilities mentioned above (showold.pl and
others) to the directory you like.
