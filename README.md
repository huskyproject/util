Utilities
=========

Here you may find Perl utilities using functions from Fidoconfig::Token and
Husky::Rmfiles packages.

showold.pl - prints out to STDOUT how much netmail, echomail and files
             are stored for every link in the outbound and fileboxes and
             for how long they are stored.

rmLinkMail.pl - remove netmail, echomail and files of a link.

rmLink.pl - remove a link

fixOutbound.pl - remove from outbound the echomail bundles not referred
                 by any flow file

To see a short information for a <utility> run
    perl <utility> --help
and to read full documentation for all utilities except showold.pl run
    perldoc <utility>

Since in Windows perldoc uses more.com pager which cannot list pages backwards,
you may find it more comfortable to save the help it shows to a text file.

perldoc some-utility.pl > some-utility.txt

Before using the utilities you have to install Fidoconfig::Token and 
Husky::Rmfiles packages. Fidoconfig-Token and Husky-Rmfiles subdirectories
contain files necessary to install Fidoconfig::Token and Husky::Rmfiles
packages respectively.

Installation in a UNIX-like OS
==============================

Before installing Fidoconfig::Token and Husky::Rmfiles make sure version 0.28
or newer of Module::Build is installed. If the module is not installed, you may
install it either using your OS packaging system or from CPAN:

sudo cpanm Module::Build

To install Fidoconfig::Token and Husky::Rmfiles packages run the following:

pushd Fidoconfig-Token
perl Build.PL
./Build
sudo ./Build install
popd

pushd Husky-Rmfiles
perl Build.PL
./Build
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

To install Fidoconfig::Token and Husky::Rmfiles packages run the following
commands:

pushd Fidoconfig-Token
perl Build.PL
Build
Build install
popd

pushd Husky-Rmfiles
perl Build.PL
Build
Build install
popd

If it says that you don't have a C compiler, ignore it. Now the two packages
are installed and you may copy the utilities mentioned above (showold.pl and
others) to the directory you like.
