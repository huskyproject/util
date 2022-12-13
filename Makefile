# Generic Makefile for util
# util/Makefile
#
# This file is part of util, part of the Husky fidonet software project
# Use with GNU make v.3.82 or later
# Requires: husky environment
#

ifdef RPM_BUILD_ROOT
    DESTDIR=$(RPM_BUILD_ROOT)
endif

utils=fixOutbound.pl rmLink.pl rmLinkMail.pl showold.pl
utils_BLD=$(addprefix $(util_ROOTDIR)bin$(DIRSEP),$(utils))
utils_DST=$(addprefix $(BINDIR_DST),$(utils))

installsitelib=$(PREFIX)$(DIRSEP)share$(DIRSEP)perl5

fixOutbound_BLD=$(util_ROOTDIR)blib$(DIRSEP)script$(DIRSEP)fixOutbound.pl
token_DIR_BLD=$(util_token)lib$(DIRSEP)Fidoconfig
token_BLD=$(util_token)blib$(DIRSEP)lib$(DIRSEP)Fidoconfig$(DIRSEP)Token.pm
token_DIR_DST=$(DESTDIR)$(installsitelib)$(DIRSEP)Fidoconfig
token_DST=$(token_DIR_DST)$(DIRSEP)Token.pm
rmfiles_DIR_BLD=$(util_rmfiles)lib$(DIRSEP)Husky
rmfiles_BLD=$(util_rmfiles)blib$(DIRSEP)lib$(DIRSEP)Husky$(DIRSEP)Rmfiles.pm
rmfiles_DIR_DST=$(DESTDIR)$(installsitelib)$(DIRSEP)Husky
rmfiles_DST=$(rmfiles_DIR_DST)$(DIRSEP)Rmfiles.pm
rmLink_DST=$(BINDIR_DST)rmLink.pl

PERL5LIB1=../Fidoconfig-Token/blib/lib
PERL5LIB2=Fidoconfig-Token/blib/lib:Husky/Rmfiles/blib/lib

.PHONY: util_build rmfiles_test rmfiles_build token_test token_build \
        util_install util_install_man1 util_install_man3 util_clean \
        rmfiles_clean token_clean substitute_colons \
        util_distclean rmfiles_distclean token_distclean \
        util_uninstall rmfiles_uninstall util_man_uninstall token_uninstall

# Build
util_build: $(fixOutbound_BLD) ;

$(fixOutbound_BLD): $(util_ROOTDIR)Build
	cd $(util_ROOTDIR); \
	export PERL5LIB=$(PERL5LIB2); \
	.$(DIRSEP)Build

$(util_ROOTDIR)Build: $(rmfiles_BLD)
	cd $(util_ROOTDIR); perl Build.PL \
	--install_path script=$(BINDIR_DST) \
	--install_path bindoc=$(DESTDIR)$(MAN1DIR)


$(rmfiles_BLD): $(util_rmfiles)Build
	cd $(util_rmfiles); export PERL5LIB=$(PERL5LIB1); .$(DIRSEP)Build

$(util_rmfiles)Build: $(token_BLD)
	cd $(util_rmfiles); perl Build.PL \
	--install_path lib=$(DESTDIR)$(installsitelib) \
	--install_path libdoc=$(DESTDIR)$(MAN3DIR)


$(token_BLD): $(util_token)Build
	cd $(util_token); .$(DIRSEP)Build

$(util_token)Build:
	cd $(util_token); perl Build.PL \
	--install_path lib=$(DESTDIR)$(installsitelib) \
	--install_path libdoc=$(DESTDIR)$(MAN3DIR)


# Test
util_test: rmfiles_test
	cd $(util_ROOTDIR); \
	export PERL5LIB=$(PERL5LIB2); \
	.$(DIRSEP)Build test

rmfiles_test: token_test $(rmfiles_BLD) $(hpt_TARGET_BLD) $(htick_TARGET_BLD)
	cd $(util_rmfiles); \
	export PERL5LIB=$(PERL5LIB1); \
	$(LN) $(LNOPT) ..$(DIRSEP)..$(DIRSEP)$(hpt_BUILDDIR)hpt$(_EXE) .$(DIRSEP); \
	$(LN) $(LNOPT) ..$(DIRSEP)..$(DIRSEP)$(htick_TARGET_BLD) .$(DIRSEP); \
	.$(DIRSEP)Build test $${dir}; \
	$(RM) $(RMOPT) hpt$(_EXE) htick$(_EXE)

token_test: $(token_BLD)
	cd $(util_token); .$(DIRSEP)Build test



# Install
util_install: $(rmLink_DST) util_install_man1 util_install_man3 ;

    $(rmLink_DST): $(rmfiles_DST) $(utils_BLD)
		install $(utils_BLD) $(BINDIR_DST); \
		$(TOUCH) $(utils_DST)

    $(rmfiles_DST): $(token_DST) $(rmfiles_BLD) | $(rmfiles_DIR_DST)
		install $(rmfiles_BLD) $(rmfiles_DIR_DST)
		$(TOUCH) $@

    $(rmfiles_DIR_DST):
		[ -d $@ ] || $(MKDIR) $(MKDIROPT) $@

    $(token_DST): $(token_BLD) | $(token_DIR_DST)
		install $< $(token_DIR_DST)
		$(TOUCH) $@

    $(token_DIR_DST):
		[ -d $@ ] || $(MKDIR) $(MKDIROPT) $@

ifndef MAN1DIR
    util_install_man1: ;
else
    utils_with_man := $(filter-out showold.pl,$(utils))
    utils_man_DST  := $(addprefix $(DESTDIR)$(MAN1DIR)/,\
                        $(addsuffix .1.gz,$(utils_with_man)))

    util_install_man1: $(utils_man_DST) ;

    $(utils_man_DST): $(DESTDIR)$(MAN1DIR)/%.1.gz: | $(DESTDIR)$(MAN1DIR)
		cd util/bin; \
		pod2man -d $(util_cvsdate) $* | gzip > $@
endif

ifndef MAN3DIR
    util_install_man3: ;
else
    # A filename in a target or a prerequisite of a rule cannot contain ':'
    # that is why we first create files with '-' in their filenames
    # instead of '::' and then rename them. Unfortunately, as a consequence,
    # the rules are always run.

    token_gz := $(DESTDIR)$(MAN3DIR)/Fidoconfig-Token.3pm.gz
    rmfiles_gz := $(DESTDIR)$(MAN3DIR)/Husky-Rmfiles.3pm.gz

    util_install_man3: $(token_gz) $(rmfiles_gz)
		-@cd $(DESTDIR)$(MAN3DIR); \
		$(MV) Fidoconfig-Token.3pm.gz Fidoconfig::Token.3pm.gz; \
		$(MV) Husky-Rmfiles.3pm.gz Husky::Rmfiles.3pm.gz ||:

    $(token_gz): $(token_DIR_BLD)/Token.pm | $(DESTDIR)$(MAN3DIR)
		@cd $(util_token)lib; \
		pod2man -d $(util_cvsdate) Fidoconfig/Token.pm | gzip > $@

    $(rmfiles_gz): $(rmfiles_DIR_BLD)/Rmfiles.pm | $(DESTDIR)$(MAN3DIR)
		@cd $(util_rmfiles)lib; \
		pod2man -d $(util_cvsdate) Husky/Rmfiles.pm | gzip > $@
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
	[ -f .$(DIRSEP)Build ] && .$(DIRSEP)Build realclean ||:

rmfiles_distclean: token_distclean
	-cd $(util_rmfiles); \
	[ -f .$(DIRSEP)Build ] && .$(DIRSEP)Build realclean ||:

token_distclean:
	-cd $(util_token); \
	[ -f .$(DIRSEP)Build ] && .$(DIRSEP)Build realclean ||:


# Uninstall
util_uninstall: rmfiles_uninstall token_uninstall util_man1_uninstall \
                util_man3_uninstall
	-$(RM) $(RMOPT) $(BINDIR_DST)fixOutbound.pl
	-$(RM) $(RMOPT) $(BINDIR_DST)rmLink.pl
	-$(RM) $(RMOPT) $(BINDIR_DST)rmLinkMail.pl
	-$(RM) $(RMOPT) $(BINDIR_DST)showold.pl

ifdef MAN1DIR
    util_man1_uninstall:
		-$(RM) $(RMOPT) $(DESTDIR)$(MAN1DIR)$(DIRSEP)fixOutbound.pl.1*
		-$(RM) $(RMOPT) $(DESTDIR)$(MAN1DIR)$(DIRSEP)rmLink.pl.1*
		-$(RM) $(RMOPT) $(DESTDIR)$(MAN1DIR)$(DIRSEP)rmLinkMail.pl.1*
else
    util_man1_uninstall: ;
endif

ifdef MAN3DIR
    util_man3_uninstall:
		-$(RM) $(RMOPT) $(DESTDIR)$(MAN3DIR)$(DIRSEP)Fidoconfig::Token.3pm.gz
		-$(RM) $(RMOPT) $(DESTDIR)$(MAN3DIR)$(DIRSEP)Husky::Rmfiles.3pm.gz
		-$(RM) $(RMOPT) $(DESTDIR)$(MAN3DIR)$(DIRSEP)Fidoconfig-Token.3pm.gz
		-$(RM) $(RMOPT) $(DESTDIR)$(MAN3DIR)$(DIRSEP)Husky-Rmfiles.3pm.gz
else
    util_man3_uninstall: ;
endif

rmfiles_uninstall:
	-[ -f $(rmfiles_DST) ] && $(RM) $(RMOPT) $(rmfiles_DST) && \
	$(RMDIR) $(rmfiles_DIR_DST) && $(RMDIR) $(DESTDIR)$(installsitelib) ||:

token_uninstall:
	-[ -f $(token_DST) ] && $(RM) $(RMOPT) $(token_DST) && \
	$(RMDIR) $(token_DIR_DST) && $(RMDIR) $(DESTDIR)$(installsitelib) ||:
