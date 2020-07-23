PWD=$(shell pwd)
PRO_NAME_UPPER=$(shell echo $(PRO_NAME) | tr '[a-z]' '[A-Z]')
TARBALL_1=$(USER_RELEASE_DIR)/$(PRO_NAME)-$(BUILD_TYPE)-$(PLATFORM)-$(BOARD_ARCH)-$(FULLVER)-$(BUILD_USER)-$(BUILD_DATE)
ifeq ($(USE_SIMD),yes)
TARBALL_2=$(TARBALL_1)_simd
else
TARBALL_2=$(TARBALL_1)
endif
ifneq ($(PLATFORM),debian)
TARBALL=$(TARBALL_2).tgz
else
PLATFORM=debian
TARBALL=$(TARBALL_2).tgz
ifneq ($(PACK_DEB),no) 
DEBBALL=$(USER_RELEASE_DIR)/$(PRO_NAME)_$(FULLVER)-gcc$(COMPILER_VERSION)_$(BOARD_ARCH).deb
endif
endif


FINAL_DEPLIBS += $(USER_LDFLAGS) $(DEPLIBS) $(USER_DEPLIBS) $(BASE_DEPLIBS)

ifeq ($(DEFAULT_VERSION_FILE),)
DEFAULT_VERSION_FILE=$(PRO_DIR)/include/$(PRO_NAME)version.h
endif
ifeq ($(VERSION_FILE),)
VERSION_FILE=$(DEFAULT_VERSION_FILE)
endif

FINAL_PACK_DIR		  = $(USER_PACK_DIR)
ifneq ($(PACK_SUB_DIR),)
FINAL_PACK_LIB_DIR    = $(USER_PACK_DIR)$(prefix)/$(PACK_SUB_DIR)
FINAL_PACK_INC_DIR    = $(USER_PACK_DIR)$(prefix)/$(PACK_SUB_DIR)
FINAL_PACK_RES_DIR    = $(USER_PACK_DIR)$(prefix)/$(PACK_SUB_DIR)
FINAL_PACK_SCRIPT_DIR = $(USER_PACK_DIR)$(prefix)/$(PACK_SUB_DIR)
FINAL_PACK_BIN_DIR    = $(USER_PACK_DIR)$(prefix)/$(PACK_SUB_DIR)
TARGET_PACK_LIB_DIR = $(prefix)/$(PACK_SUB_DIR)
TARGET_PACK_INC_DIR = $(prefix)/$(PACK_SUB_DIR)
TARGET_PACK_RES_DIR = $(prefix)/$(PACK_SUB_DIR)
TARGET_PACK_SCRIPT_DIR = $(prefix)/$(PACK_SUB_DIR)
TARGET_PACK_BIN_DIR = $(prefix)/$(PACK_SUB_DIR)
else
FINAL_PACK_LIB_DIR    = $(USER_PACK_LIB_DIR)
FINAL_PACK_INC_DIR    = $(USER_PACK_INC_DIR)
FINAL_PACK_RES_DIR    = $(USER_PACK_RES_DIR)
FINAL_PACK_SCRIPT_DIR = $(USER_PACK_SCRIPT_DIR)
FINAL_PACK_BIN_DIR    = $(USER_PACK_BIN_DIR)
TARGET_PACK_LIB_DIR = $(prefix)/lib
TARGET_PACK_INC_DIR = $(prefix)/include
TARGET_PACK_RES_DIR = $(prefix)/share
TARGET_PACK_SCRIPT_DIR = $(prefix)/scripts
TARGET_PACK_BIN_DIR = $(prefix)/bin
endif
FINAL_INST_DIR		  = $(USER_INST_DIR)
ifneq ($(INST_SUB_DIR),)
FINAL_INST_LIB_DIR    = $(USER_INST_DIR)/$(INST_SUB_DIR)
FINAL_INST_INC_DIR    = $(USER_INST_DIR)/$(INST_SUB_DIR)
FINAL_INST_RES_DIR    = $(USER_INST_DIR)/$(INST_SUB_DIR)
FINAL_INST_SCRIPT_DIR = $(USER_INST_DIR)/$(INST_SUB_DIR)
FINAL_INST_BIN_DIR    = $(USER_INST_DIR)/$(INST_SUB_DIR)
else
FINAL_INST_LIB_DIR    = $(USER_INST_LIB_DIR)
FINAL_INST_INC_DIR    = $(USER_INST_INC_DIR)
FINAL_INST_RES_DIR    = $(USER_INST_RES_DIR)
FINAL_INST_SCRIPT_DIR = $(USER_INST_SCRIPT_DIR)
FINAL_INST_BIN_DIR    = $(USER_INST_BIN_DIR)
endif
ifneq ($(PACK_FULLPATH),no)
PACK_FULLPATH=yes
else
PACK_FULLPATH=no
endif
ifneq ($(INST_FULLPATH),no)
INST_FULLPATH=yes
else
INST_FULLPATH=no
endif

ifneq ($(SHARED_LIB),)
TARGET_NAME=lib$(SHARED_LIB).so
else ifneq ($(STATIC_LIB),)
TARGET_NAME=lib$(STATIC_LIB).a
else ifneq ($(EXEC), )
TARGET_NAME=$(EXEC)
endif

ifeq ($(BUILD_CXX),)
ifneq ($(patsubst %.cpp,%,$(SRCS)),$(SRCS))    
BUILD_CXX=y
else
BUILD_CXX=n
endif
endif

ifeq ($(SRCS),)
TMPOBJS=$(addsuffix .o,$(wildcard *.c) $(wildcard *.cpp) $(wildcard *.cc) $(wildcard *.asm) $(wildcard *.nasm) $(wildcard *.yasm))
else
TMPOBJS = $(addsuffix .o,$(SRCS))
endif

#OBJS = $(addprefix $(USER_OBJS_DIR)/, $(notdir $(TMPOBJS)))
TOBJS = $(foreach oo,$(TMPOBJS),$(shell cd $(shell dirname $(oo)) && pwd)/$(notdir $(oo)))
OBJS = $(patsubst $(PRO_DIR)/%,$(USER_OBJS_DIR)/%,$(TOBJS))

# shared library CFLAG
ifneq ($(SHARED_LIB),)
SHARED_FLAGS = -fPIC
USER_CFLAGS += $(SHARED_FLAGS)
USER_CPPFLAGS += $(SHARED_FLAGS)
endif

BUILD_TARGET=lib

.PHONY: all $(BUILD_TARGET)

all: $(BUILD_TARGET)

$(OBJS): $(USER_OBJS_DIR)/%.o:$(PRO_DIR)/%
	@$(call MakeObject,$@,$<)

prepare:
	@if [ ! -d $(USER_OBJS_DIR) ] ; then \
	$(MKDIR) $(USER_OBJS_DIR) || exit 1; \
	fi;
	@if [ ! -d $(USER_TMP_DIR) ] ; then \
	$(MKDIR) $(USER_TMP_DIR) || exit 1; \
	fi;
	@$(InitAsInst)
	@if [ "x$(shell pwd)" == "x$(PRO_DIR)" ]; then \
		$(call ECHO,Generate,red,"version file ",,$(VERSION_FILE),cyan); \
		if [ ! -d "$$(dirname $(VERSION_FILE))" ]; then \
			mkdir -p "$$(dirname $(VERSION_FILE))" ; \
		fi; \
		echo "#ifndef __$(PRO_NAME_UPPER)_VERSION_H_" >$(VERSION_FILE); \
		echo "#define __$(PRO_NAME_UPPER)_VERSION_H_" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_VER_FULL \"$(FULLVER)\"" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_VER_MAJOR \"$(VER_MAJOR)\"" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_VER_MINOR \"$(VER_MINOR)\"" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_VER_BUILD \"$(FINAL_VER_BUILD)\"" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_VER_FIX \"$(VER_FIX)\"" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_VER_SVN \"$(VER_SVN)\"" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_BUILD_USER \"$(BUILD_USER)\"" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_BUILD_DATE \"$(BUILD_DATE)\"" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_BUILD_OS \"$(BUILD_OS)\"" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_BUILD_CPU \"$(BUILD_CPU)\"" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_BUILD_PLATFORM \"$(BUILD_PLATFORM)\"" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_BUILD_KERNEL \"$(BUILD_KERNEL)\"" >>$(VERSION_FILE); \
		echo "#define $(PRO_NAME_UPPER)_BUILD_PREFIX \"$(prefix)\"" >>$(VERSION_FILE); \
		for def in $(DEFINE_CFLAGS); do \
		    defk=$${def/-D/}; \
			defk=$${defk/=*/}; \
			defv=$${def/-D/}; \
			defvv=$${defv/*=/}; \
			if [ "$$defv" == "$$defvv" ]; then \
			    defv=;\
			fi; \
	    	echo "#ifndef $$defk" >>$(VERSION_FILE); \
	    	echo "#define $$defk $$defv" >>$(VERSION_FILE); \
			echo "#endif" >>$(VERSION_FILE); \
	    done; \
		echo "#endif" >>$(VERSION_FILE); \
	fi

testecho:
	@echo "D: $(DEFINE_CFLAGS)"; \
	for def in $(DEFINE_CFLAGS); do \
	    defk=$${def/-D/}; \
		defk=$${defk/=*/}; \
		defv=$${def/-D/}; \
		defvv=$${defv/*=/}; \
		if [ "$$defv" == "$$defvv" ]; then \
		    defv=;\
		fi; \
	done	

echodebpath:
	@echo $(DEBBALL)

echoproname:
	@echo $(PRO_NAME)

DIR_DEPHEADERS=$(addsuffix _header,$(DEPDIRS)) 
DIR_SUBHEADERS=$(addsuffix _header,$(SUBDIRS))
$(DIR_DEPHEADERS):
	@$(MAKE) -sC $(patsubst %_header,%,$@) header

$(DIR_SUBHEADERS): $(DIR_DEPHEADERS)
	@$(MAKE) -sC $(patsubst %_header,%,$@) header

ifeq ($(DIR_SUBHEADERS),)
DIR_SUBHEADERS=$(DIR_DEPHEADERS)
endif

header: $(BeforeEveryThing) prepare $(DIR_SUBHEADERS)
#ifneq ($(DEPDIRS),)
#	$(call MakeDepDirs,$@)
#endif

DIR_LINKDEPLIBS=$(addsuffix _linklib,$(DEPDIRS)) 
DIR_LINKSUBLIBS=$(addsuffix _linklib,$(SUBDIRS))
$(DIR_LINKDEPLIBS):
	@$(MAKE) -sC $(patsubst %_linklib,%,$@) linklib

$(DIR_LINKSUBLIBS): $(DIR_LINKDEPLIBS)
	@$(MAKE) -sC $(patsubst %_linklib,%,$@) linklib

ifeq ($(DIR_LINKSUBLIBS),)
DIR_LINKSUBLIBS=$(DIR_LINKDEPLIBS)
endif

linklib: targetpromot header $(DIR_LINKSUBLIBS) $(OBJS)
ifneq ($(SHARED_LIB),)
	@$(call ECHO,Linking,yellow,"lib$(SHARED_LIB).so.$(MAINVER)",purple)
ifeq ($(BUILD_CXX),y)
ifeq ($(SILENTMAKE),no)
	@echo "$(LLCXX) $(STD_CPPFLAG) $(DEBUG_CFLAGS) $(USER_SHLIBFLAGS) -o $(USER_TMP_DIR)/lib$(SHARED_LIB).so.$(MAINVER) $(OBJS) $(FINAL_DEPLIBS)"
endif
	@$(LLCXX) $(STD_CPPFLAG) $(DEBUG_CFLAGS) $(USER_SHLIBFLAGS) -Wl,-soname,lib$(SHARED_LIB).so.$(VER_MAJOR) -o $(USER_TMP_DIR)/lib$(SHARED_LIB).so.$(MAINVER) $(OBJS) $(FINAL_DEPLIBS)
	@$(call StripFile,$(USER_TMP_DIR)/lib$(SHARED_LIB).so.$(MAINVER))
else
ifeq ($(SILENTMAKE),no)
	@echo "$(LLCC) $(STD_CFLAG) $(DEBUG_CFLAGS) $(USER_SHLIBFLAGS) -o $(USER_TMP_DIR)/lib$(SHARED_LIB).so.$(MAINVER) $(OBJS) $(FINAL_DEPLIBS)"
endif
	@$(LLCC) $(STD_CFLAG) $(DEBUG_CFLAGS) $(USER_SHLIBFLAGS) -Wl,-soname,lib$(SHARED_LIB).so.$(VER_MAJOR) -o $(USER_TMP_DIR)/lib$(SHARED_LIB).so.$(MAINVER) $(OBJS) $(FINAL_DEPLIBS)
	@$(call StripFile,$(USER_TMP_DIR)/lib$(SHARED_LIB).so.$(MAINVER))
endif
	@cd $(USER_TMP_DIR) && $(RM) lib$(SHARED_LIB).so && $(LN) lib$(SHARED_LIB).so.$(MAINVER) lib$(SHARED_LIB).so
endif
ifneq ($(STATIC_LIB),)
	@$(call ECHO,PACK,yellow,"lib$(STATIC_LIB).a",blue:green)
ifeq ($(SILENTMAKE),no)
	@echo "$(LLAR) $(USER_STLIBFLAGS) $(USER_TMP_DIR)/lib$(STATIC_LIB).a $(OBJS)"
endif
	@$(LLAR) $(USER_STLIBFLAGS) $(USER_TMP_DIR)/lib$(STATIC_LIB).a $(OBJS)
	@$(call StripFile,$(USER_TMP_DIR)/lib$(STATIC_LIB).a)
endif
ifneq ($(DEPLIBFILES),)
ifneq ($(INST_DEPLIBFILES),no)
	$(call InstallDepLibFiles,$(USER_TMP_DIR))
endif
endif
#	$(call MakeSubDirs,$@)

DIR_LINKDEPBINS=$(addsuffix _linkbin,$(DEPDIRS)) 
DIR_LINKSUBBINS=$(addsuffix _linkbin,$(SUBDIRS))
$(DIR_LINKDEPBINS):
	@$(MAKE) -sC $(patsubst %_linkbin,%,$@) linkbin

$(DIR_LINKSUBBINS): $(DIR_LINKDEPBINS)
	@$(MAKE) -sC $(patsubst %_linkbin,%,$@) linkbin

ifeq ($(DIR_LINKSUBBINS),)
DIR_LINKSUBBINS=$(DIR_LINKDEPBINS)	
endif

linkbin: targetpromot $(DIR_LINKSUBBINS) $(OBJS)
ifneq ($(EXEC),)
	@$(call ECHO,LINK,yellow,"$(EXEC)",blue:green)
ifeq ($(BUILD_CXX),y)
ifeq ($(SILENTMAKE),no)
	@echo "$(LLCXX) $(STD_CPPFLAG) $(DEBUG_CFLAGS) $(USER_LDFLAGS) -o $(USER_TMP_DIR)/$(EXEC) $(OBJS) $(FINAL_DEPLIBS)"
endif
	@$(LLCXX) $(STD_CPPFLAG) $(DEBUG_CFLAGS) $(USER_LDFLAGS) -o $(USER_TMP_DIR)/$(EXEC) $(OBJS) $(FINAL_DEPLIBS)
	@$(call StripFile,$(USER_TMP_DIR)/$(EXEC))
else
ifeq ($(SILENTMAKE),no)
	@echo "$(LLCC) $(STD_CFLAG) $(DEBUG_CFLAGS) $(USER_LDFLAGS) -o $(USER_TMP_DIR)/$(EXEC) $(OBJS) $(FINAL_DEPLIBS)"
endif
	@$(LLCC) $(STD_CFLAG) $(DEBUG_CFLAGS) $(USER_LDFLAGS) -o $(USER_TMP_DIR)/$(EXEC) $(OBJS) $(FINAL_DEPLIBS)
	@$(call StripFile,$(USER_TMP_DIR)/$(EXEC))
endif
endif
ifneq ($(DEPLIBFILES),)
ifneq ($(INST_DEPLIBFILES),no)
	$(call InstallDepLibFiles,$(USER_TMP_DIR))
endif
endif
ifneq ($(AfterLink),)
	$(call AfterLink)
endif
#ifneq ($(SUBDIRS),)
#	$(call MakeSubDirs,$@)
#endif

targetpromot:
ifneq ($(TARGET_NAME),)
	$(call Promot,Building,$(TARGET_NAME))
endif

beforePack:
	@if [ ! -d $(USER_RELEASE_DIR) ] ; then \
		$(MKDIR) $(USER_RELEASE_DIR) || exit 1; \
	fi; \
	if [ ! -d $(USER_PACK_DIR) ] ; then \
		$(MKDIR) $(USER_PACK_DIR) || exit 1; \
	fi

DIR_PACKDEPLIBS=$(addsuffix _PackLib,$(DEPDIRS)) 
DIR_PACKSUBLIBS=$(addsuffix _PackLib,$(SUBDIRS))
$(DIR_PACKDEPLIBS):
	@$(MAKE) -sC $(patsubst %_PackLib,%,$@) PackLib

$(DIR_PACKSUBLIBS): $(DIR_PACKDEPLIBS)
	@$(MAKE) -sC $(patsubst %_PackLib,%,$@) PackLib

ifeq ($(DIR_PACKSUBLIBS),)
DIR_PACKSUBLIBS=$(DIR_PACKDEPLIBS)	
endif

PackLib: beforePack $(DIR_PACKSUBLIBS)
	$(call Promot,$@)
ifneq ($(HEADERS),)
ifneq ($(PACK_HEADERS),no)
#ifneq ($(BUILD_TYPE),release)
	$(call InstallHeaders,$(FINAL_PACK_INC_DIR),$(PACK_FULLPATH))
#endif
endif
endif
ifneq ($(SHARED_LIB),)
ifneq ($(PACK_LIB),no)
	$(call InstallSharedLib,$(FINAL_PACK_LIB_DIR),pack)
endif
endif
ifneq ($(STATIC_LIB),)
ifneq ($(PACK_LIB),no)
	$(call InstallStaticLib,$(FINAL_PACK_LIB_DIR))
endif
endif
ifneq ($(SCRIPTS),)
ifneq ($(PACK_SCRIPTS),no)
	$(call InstallScripts,$(FINAL_PACK_SCRIPT_DIR),$(PACK_FULLPATH))
endif
endif
ifneq ($(RESOURCES),)
ifneq ($(PACK_RESOURCES),no)
	$(call InstallResources,pack,$(PACK_FULLPATH))
endif
endif
ifneq ($(CIPHER_RESOURCES),)
ifneq ($(PACK_RESOURCES),no)
	$(call InstallResources,pack,$(PACK_FULLPATH))
endif
endif
ifneq ($(DEPLIBFILES),)
ifneq ($(PACK_DEPLIBFILES),no)
	$(call InstallDepLibFiles,$(FINAL_PACK_LIB_DIR))
endif
endif
#ifneq ($(SUBDIRS),)
#	$(call MakeSubDirs,$@)
#endif

DIR_PACKDEPEXECS=$(addsuffix _PackExec,$(DEPDIRS)) 
DIR_PACKSUBEXECS=$(addsuffix _PackExec,$(SUBDIRS))
$(DIR_PACKDEPEXECS):
	@$(MAKE) -sC $(patsubst %_PackExec,%,$@) PackExec

$(DIR_PACKSUBEXECS): $(DIR_PACKDEPEXECS)
	@$(MAKE) -sC $(patsubst %_PackExec,%,$@) PackExec

ifeq ($(DIR_PACKSUBEXECS),)
DIR_PACKSUBEXECS=$(DIR_PACKDEPEXECS)
endif

PackExec: beforePack $(DIR_PACKSUBEXECS)
	$(call Promot,$@)
ifneq ($(EXEC),)
ifneq ($(PACK_EXEC),no)
	$(call InstallBin,$(FINAL_PACK_BIN_DIR))
endif
endif
#ifneq ($(SUBDIRS),)
#	$(call MakeSubDirs,$@)
#endif

PackTar: PackLib PackExec
ifeq ($(shell pwd),$(PRO_DIR))
	@$(PrePackage)
ifeq ($(PACK_TGZ),yes)
	@$(call ECHO,PACKAGE,yellow,"$(patsubst $(PRO_DIR)/%,%,$(TARBALL))",blue:green)
	@cd $(USER_PACK_DIR) && $(CTAR) $(TARBALL) ./*
endif
ifneq ($(PACK_DEB),no)
	@$(call ECHO,PACKAGE,yellow,"$(patsubst $(PRO_DIR)/%,%,$(DEBBALL))",blue:green)
	@$(call MakeDeb)
endif
endif

CleanPack:
ifeq ($(shell pwd),$(PRO_DIR))
	@if [ -d $(USER_PACK_DIR) ]; then \
		$(SUDO) $(RMDIR) $(USER_PACK_DIR); \
	fi
endif

DIR_CLEANDEPS=$(addsuffix _Clean,$(DEPDIRS)) 
DIR_CLEANSUBS=$(addsuffix _Clean,$(SUBDIRS))
$(DIR_CLEANDEPS):
	@$(MAKE) -sC $(patsubst %_Clean,%,$@) Clean

$(DIR_CLEANSUBS): $(DIR_CLEANDEPS)
	@$(MAKE) -sC $(patsubst %_Clean,%,$@) Clean

ifeq ($(DIR_CLEANSUBS),)
DIR_CLEANSUBS=$(DIR_CLEANDEPS)
endif

Clean: CleanPack $(DIR_CLEANSUBS)
	$(call Promot,$@)
ifneq ($(OBJS),)
	@$(CleanObjs)
endif
	@if [ -f $(USER_TMP_DIR)/$(EXEC) ]; then $(RM) $(USER_TMP_DIR)/$(EXEC); fi
	@$(RM) $(USER_TMP_DIR)/lib$(SHARED_LIB).so $(USER_TMP_DIR)/lib$(SHARED_LIB).so.$(MAINVER) $(USER_TMP_DIR)/lib$(STATIC_LIB).a

#	@$(SUDO) $(RM) $(CRYPTO_KEY_IN)
#ifneq ($(SUBDIRS),)
#	$(call MakeSubDirs,$@)
#endif
#ifneq ($(DEPDIRS),)
#	$(call MakeDepDirs,$@)
#endif

CleanAll:
	$(call Promot,$@)
	@if [ "x$(shell pwd)" == "x$(PRO_DIR)" ]; then \
		$(call ECHO,Remove,green,"dir",,"$(patsubst $(PRO_DIR)/%,%,$(USER_PACK_DIR))",cyan); \
		$(SUDO) $(RMDIR) $(USER_PACK_DIR); \
		$(call ECHO,Remove,green,"dir",,"$(patsubst $(PRO_DIR)/%,%,$(USER_OBJS_DIR))",cyan); \
		$(SUDO) $(RMDIR) $(USER_OBJS_DIR); \
		$(call ECHO,Remove,green,"dir",,"$(patsubst $(PRO_DIR)/%,%,$(USER_TMP_DIR))",cyan); \
		$(SUDO) $(RMDIR) $(USER_TMP_DIR); \
		$(call ECHO,Remove,green,"dir",,"$(patsubst $(PRO_DIR)/%,%,$(USER_RELEASE_DIR))",cyan); \
		$(SUDO) $(RMDIR) $(USER_RELEASE_DIR); \
		$(call ECHO,Remove,green,"file",,"$(patsubst $(PRO_DIR)/%,%,$(VERSION_FILE))",cyan); \
		$(SUDO) $(RM) $(VERSION_FILE); \
	fi

#	@$(SUDO) $(RM) $(CRYPTO_KEY_IN)

DIR_INSTDEPNONEXECS=$(addsuffix _InstNonExec,$(DEPDIRS)) 
DIR_INSTSUBNONEXECS=$(addsuffix _InstNonExec,$(SUBDIRS))
$(DIR_INSTDEPNONEXECS):
	@$(MAKE) -sC $(patsubst %_InstNonExec,%,$@) InstNonExec

$(DIR_INSTSUBNONEXECS): $(DIR_INSTDEPNONEXECS)
	@$(MAKE) -sC $(patsubst %_InstNonExec,%,$@) InstNonExec

ifeq ($(DIR_INSTSUBNONEXECS),)
DIR_INSTSUBNONEXECS=$(DIR_INSTDEPNONEXECS)
endif

InstNonExec: $(DIR_INSTSUBNONEXECS)
	$(call Promot,$@)
ifneq ($(HEADERS),)
ifneq ($(INST_HEADERS),no)
	$(call InstallHeaders,$(FINAL_INST_INC_DIR),$(INST_FULLPATH))
endif
endif
ifneq ($(SHARED_LIB),)
ifneq ($(INST_LIB),no)
	$(call InstallSharedLib,$(FINAL_INST_LIB_DIR),install)
endif
endif
ifneq ($(STATIC_LIB),)
ifneq ($(INST_LIB),no)
	$(call InstallStaticLib,$(FINAL_INST_LIB_DIR))
endif
endif
ifneq ($(SCRIPTS),)
ifneq ($(INST_SCRIPTS),no)
	$(call InstallScripts,$(FINAL_INST_SCRIPT_DIR),$(INST_FULLPATH))
endif
endif
ifneq ($(DEPLIBFILES),)
ifneq ($(INST_DEPLIBFILES),no)
	$(call InstallDepLibFiles,$(FINAL_INST_LIB_DIR))
endif
endif
ifneq ($(DEVINSTALL),yes)
ifneq ($(RESOURCES),)
ifneq ($(INST_RESOURCES),no)
	$(call InstallResources,install,$(INST_FULLPATH))
endif
endif
ifneq ($(CIPHER_RESOURCES),)
ifneq ($(INST_RESOURCES),no)
	$(call InstallResources,install,$(INST_FULLPATH))
endif
endif
endif
#ifneq ($(SUBDIRS),)
#	$(call MakeSubDirs,$@)
#endif


DIR_INSTDEPEXECS=$(addsuffix _InstExec,$(DEPDIRS)) 
DIR_INSTSUBEXECS=$(addsuffix _InstExec,$(SUBDIRS)) 
$(DIR_INSTDEPEXECS):
	@$(MAKE) -sC $(patsubst %_InstExec,%,$@) InstallExec

$(DIR_INSTSUBEXECS): $(DIR_INSTDEPEXECS)
	@$(MAKE) -sC $(patsubst %_InstExec,%,$@) InstallExec

ifeq ($(DIR_INSTSUBEXECS),)
DIR_INSTSUBEXECS=$(DIR_INSTDEPEXECS)
endif

InstallExec: $(DIR_INSTSUBEXECS)
	$(call Promot,$@)
ifneq ($(EXEC),)
ifeq ($(INST_EXEC),yes)
	$(call InstallBin,$(FINAL_INST_BIN_DIR))
endif
endif
#ifneq ($(SUBDIRS),)
#	$(call MakeSubDirs,$@)
#endif

Install: InstNonExec InstallExec

DIR_UNINSTALLDEPS=$(addsuffix _Uninstall,$(DEPDIRS)) 
DIR_UNINSTALLSUBS=$(addsuffix _Uninstall,$(SUBDIRS))
$(DIR_UNINSTALLDEPS):
	@$(MAKE) -sC $(patsubst %_Uninstall,%,$@) Uninstall

$(DIR_UNINSTALLSUBS): $(DIR_UNINSTALLDEPS)
	@$(MAKE) -sC $(patsubst %_Uninstall,%,$@) Uninstall

ifeq ($(DIR_UNINSTALLSUBS),)
DIR_UNINSTALLSUBS=$(DIR_UNINSTALLDEPS)
endif

Uninstall: $(DIR_UNINSTALLSUBS)
	$(call Promot,$@)
ifneq ($(HEADERS),)
ifneq ($(INST_HEADERS),no)
	$(call UninstallHeaders,$(FINAL_INST_INC_DIR),$(INST_FULLPATH))
endif
endif
ifneq ($(SHARED_LIB),)
ifneq ($(INST_LIB),no)
	$(call UninstallSharedLib,$(FINAL_INST_LIB_DIR))
endif
endif
ifneq ($(STATIC_LIB),)
ifneq ($(INST_LIB),no)
	$(call UninstallStaticLib,$(FINAL_INST_LIB_DIR))
endif
endif
ifneq ($(SCRIPTS),)
ifneq ($(INST_SCRIPTS),no)
	$(call UninstallScripts,$(FINAL_INST_SCRIPT_DIR),$(INST_FULLPATH))
endif
endif
ifneq ($(RESOURCES),)
ifneq ($(INST_RESOURCES),no)
	$(call UninstallResources,uninstall,$(INST_FULLPATH))
endif
endif
ifneq ($(CIPHER_RESOURCES),)
ifneq ($(INST_RESOURCES),no)
	$(call UninstallResources,uninstall,$(INST_FULLPATH))
endif
endif
ifneq ($(DEPLIBFILES),)
ifneq ($(INST_DEPLIBFILES),no)
	$(call UninstallDepLibFiles,$(FINAL_INST_LIB_DIR))
endif
endif
ifneq ($(EXEC),)
ifeq ($(INST_EXEC),yes)
	$(call UninstallBin,$(FINAL_INST_BIN_DIR))
endif
endif
#ifneq ($(SUBDIRS),)
#	$(call MakeSubDirs,$@)
#endif

installlib: InstNonExec

installbin: InstallExec

lib: linklib
	
bin: linkbin

install: Install

uninstall: Uninstall

clean: Clean

cleanall: CleanAll

package: PackTar
