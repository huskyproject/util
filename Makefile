# Generic Makefile for util
# util/Makefile
#
# This file is part of util, part of the Husky fidonet software project
# Use with GNU make v.3.82 or later
# Requires: husky enviroment
#

utils=fixOutbound.pl rmLink.pl rmLinkMail.pl showold.pl
utils_DST=$(addprefix $(BINDIR_DST),$(utils))

installsitelib=$(shell perl -e 'use Config qw(config_vars); config_vars(qw(installsitelib));' | cut -d\' -f2)
installsiteman1dir=$(shell perl -e 'use Config qw(config_vars); config_vars(qw(installsiteman1dir));' | cut -d\' -f2)
installsiteman3dir=$(shell perl -e 'use Config qw(config_vars); config_vars(qw(installsiteman3dir));' | cut -d\' -f2)

fixOutbound_BLD=$(util_ROOTDIR)blib$(DIRSEP)script$(DIRSEP)fixOutbound.pl
token_BLD=$(util_token)blib$(DIRSEP)lib$(DIRSEP)Fidoconfig$(DIRSEP)Token.pm
token_DST=$(DESTDIR)$(installsitelib)$(DIRSEP)Fidoconfig$(DIRSEP)Token.pm
rmfiles_BLD=$(util_rmfiles)blib$(DIRSEP)lib$(DIRSEP)Husky$(DIRSEP)Rmfiles.pm
rmfiles_DST=$(DESTDIR)$(installsitelib)$(DIRSEP)Husky$(DIRSEP)Rmfiles.pm
rmLink_DST=$(BINDIR_DST)rmLink.pl

PERL5LIB1=../Fidoconfig-Token/blib/lib
PERL5LIB2=Fidoconfig-Token/blib/lib:Husky/Rmfiles/blib/lib

.PHONY: util_all util_build rmfiles_test rmfiles_build token_test token_build \
        util_install util_clean rmfiles_clean token_clean \
        util_distclean rmfiles_distclean token_distclean \
        util_uninstall rmfiles_uninstall util_man_uninstall token_uninstall

# Build
util_all: $(fixOutbound_BLD) ;

$(fixOutbound_BLD): $(util_ROOTDIR)Build
	cd $(util_ROOTDIR); \
	export PERL5LIB=$(PERL5LIB2); \
	.$(DIRSEP)Build

$(util_ROOTDIR)Build: $(rmfiles_BLD)
	cd $(util_ROOTDIR); perl Build.PL \
	--install_path script=$(BINDIR_DST) \
	--install_path bindoc=$(DESTDIR)$(installsiteman1dir)


$(rmfiles_BLD): $(util_rmfiles)Build
	cd $(util_rmfiles); export PERL5LIB=$(PERL5LIB1); .$(DIRSEP)Build

$(util_rmfiles)Build: $(token_BLD)
	cd $(util_rmfiles); perl Build.PL \
	--install_path lib=$(DESTDIR)$(installsitelib) \
	--install_path libdoc=$(DESTDIR)$(installsiteman3dir)


$(token_BLD): $(util_token)Build
	cd $(util_token); .$(DIRSEP)Build

$(util_token)Build:
	cd $(util_token); perl Build.PL \
	--install_path lib=$(DESTDIR)$(installsitelib) \
	--install_path libdoc=$(DESTDIR)$(installsiteman3dir)


# Test
util_test: rmfiles_test
	cd $(util_ROOTDIR); \
	export PERL5LIB=$(PERL5LIB2); \
	.$(DIRSEP)Build test

rmfiles_test: token_test $(rmfiles_BLD) $(hpt_TARGET_BLD) $(htick_TARGET_BLD)
	cd $(util_rmfiles); dir=`pwd`; \
	export PERL5LIB=$(PERL5LIB1); \
	$(LN) $(LNOPT) ..$(DIRSEP)..$(DIRSEP)$(hpt_BUILDDIR)hpt$(_EXE) .$(DIRSEP); \
	$(LN) $(LNOPT) ..$(DIRSEP)..$(DIRSEP)$(htick_TARGET_BLD) .$(DIRSEP); \
	.$(DIRSEP)Build test $${dir}; \
	$(RM) $(RMOPT) hpt$(_EXE) htick$(_EXE)

token_test: $(token_BLD)
	cd $(util_token); .$(DIRSEP)Build test



# Install
util_install: $(rmLink_DST) ;

ifdef RPM_BUILD_ROOT
    $(rmLink_DST): $(rmfiles_DST)
		cd $(util_ROOTDIR); .$(DIRSEP)Build install --destdir $(RPM_BUILD_ROOT) uninst=1; \
		$(TOUCH) $(utils_DST)

    $(rmfiles_DST): $(token_DST)
		cd $(util_rmfiles); .$(DIRSEP)Build install --destdir $(RPM_BUILD_ROOT) uninst=1

    $(token_DST):
	cd $(util_token); .$(DIRSEP)Build install --destdir $(RPM_BUILD_ROOT) uninst=1
else
    $(rmLink_DST): $(rmfiles_DST)
		cd $(util_ROOTDIR); .$(DIRSEP)Build install uninst=1; \
		$(TOUCH) $(utils_DST)

    $(rmfiles_DST): $(token_DST) | $(installsitelib)
		cd $(util_rmfiles); .$(DIRSEP)Build install uninst=1

    $(token_DST): | $(installsitelib)
		cd $(util_token); .$(DIRSEP)Build install uninst=1

    $(installsitelib):
		[ -d $@ ] || $(MKDIR) $(MKDIROPT) $@
endif

# Clean
util_clean: rmfiles_clean
	cd $(util_ROOTDIR); .$(DIRSEP)Build clean

rmfiles_clean: token_clean
	cd $(util_rmfiles); .$(DIRSEP)Build clean

token_clean:
	cd $(util_token); .$(DIRSEP)Build clean


# Distclean
util_distclean: rmfiles_distclean
	-cd $(util_ROOTDIR); \
	[ -f .$(DIRSEP)Build ] && .$(DIRSEP)Build distclean ||:
	-$(RM) $(RMOPT) $(util_ROOTDIR)cvsdate.h

rmfiles_distclean: token_distclean
	-cd $(util_rmfiles); \
	[ -f .$(DIRSEP)Build ] && .$(DIRSEP)Build distclean ||:

token_distclean:
	-cd $(util_token); \
	[ -f .$(DIRSEP)Build ] && .$(DIRSEP)Build distclean ||:


# Uninstall
util_uninstall: rmfiles_uninstall token_uninstall util_man_uninstall
	-$(RM) $(RMOPT) $(BINDIR_DST)fixOutbound.pl
	-$(RM) $(RMOPT) $(BINDIR_DST)rmLink.pl
	-$(RM) $(RMOPT) $(BINDIR_DST)rmLinkMail.pl
	-$(RM) $(RMOPT) $(BINDIR_DST)showold.pl

ifdef MAN1DIR
    util_man_uninstall:
		-$(RM) $(RMOPT) $(DESTDIR)$(MAN1DIR)$(DIRSEP)fixOutbound.pl.1*
		-$(RM) $(RMOPT) $(DESTDIR)$(MAN1DIR)$(DIRSEP)rmLink.pl.1*
		-$(RM) $(RMOPT) $(DESTDIR)$(MAN1DIR)$(DIRSEP)rmLinkMail.pl.1*
else
    util_man_uninstall: ;
endif

rmfiles_uninstall:
	-[ -f $(rmfiles_DST) ] && perl $(util_ROOTDIR)uninstall_perl_module.pl Husky::Rmfiles ||:

token_uninstall:
	-[ -f $(token_DST) ] && perl $(util_ROOTDIR)uninstall_perl_module.pl Fidoconfig::Token ||:
