include $(PRO_DIR)/config.mk
PRO_NAME_UPPER=$(shell echo $(PRO_NAME) | tr '[a-z]' '[A-Z]')
#specifiy GCC or G++ version
CVER ?=
ifeq ($(CVER),)
G4=$(shell echo `ls /usr/bin/g++-4.* 2>/dev/null | sort -n` | grep 4 | sed 's/\ .*//g' | sed 's/.*g++-4.*/g4/g')
ifeq ($(G4),g4)
CVER := $(shell echo `ls /usr/bin/g++-4.* | sort -n` | sed 's/\ .*//g' | sed 's/\/usr\/bin\/g++-//g')
else
CVER := 
endif
else
endif
ifneq ($(CVER),)
CCVER=-$(CVER)
endif
ifneq ($(TARGET),)
CCVER=
endif

ifeq ($(INSTALL_USER),)
INSTALL_USER=root
endif

ifeq ($(CPU),)
CPUNUM=4
else
CPUNUM=$(CPU)
endif

ifneq ($(STRIP),yes)
STRIP        = no
endif

ifneq ($(USE_C11), no)
STD_CFLAG=-std=c11
endif
ifeq ($(USE_C++14), yes)
STD_CPPFLAG=-std=c++14
NVSTD_CPPFLAG=-std=c++11
else
ifneq ($(USE_C++11), no)
STD_CPPFLAG=-std=c++11
NVSTD_CPPFLAG=-std=c++11
endif
endif
# Tools on build host
ifneq ($(USE_SUDO),no)
SUDO        = sudo -u $(INSTALL_USER)
endif

RM          = rm -f
RMDIR       = rm -rf
MKDIR       = mkdir -p
CP          = cp -f
MV          = mv -f
INSTALL     = install
LN          = ln -s
TOUCH       = touch
XARGS       = xargs -r
CTAR        = tar zcf
XTAR        = tar zxf
DPKG-DEB    = dpkg-deb
MD5SUM        = md5sum

# Cross compile tools
ifneq ($(TARGET),)
TARGETP=$(TARGET)-
endif

TARGET_CC       = $(TARGETP)gcc$(CCVER)
TARGET_CXX      = $(TARGETP)g++$(CCVER)
TARGET_LD       = $(TARGETP)ld
TARGET_AR       = $(TARGETP)ar
TARGET_RANLIB   = $(TARGETP)ranlib
TARGET_STRIP    = $(TARGETP)strip
TARGET_OBJCOPY  = $(TARGETP)objcopy
TARGET_OBJDUMP  = $(TARGETP)objdump
TARGET_NM       = $(TARGETP)nm
TARGET_SIZE     = $(TARGETP)size
LLCC            = $(TARGETP)gcc$(CCVER)
LLCXX           = $(TARGETP)g++$(CCVER)
LLASM             = $(TARGETP)yasm
LLAR            = $(TARGETP)ar
LLLD            = $(TARGETP)ld
LLSTRIP            = $(TARGETP)strip
LLNVCC            = nvcc
CIPHERBIN		?= $(shell if [ -e "/usr/local/bin/buciphersigner" -a -e "/usr/local/lib/libbu_cryptolock.so" ]; then echo "/usr/local/bin/buciphersigner"; else echo "echo \"cipher program not found. args: \""; fi)

COMPILER_VERSION=$(shell $(LLCC) --version | grep gcc | awk '{print $$4}')

SHELL_USER=$(shell whoami)
ifeq ($(BUILD_SVNREV),)
ifneq ($(IS_SVNROOT),no)
BUILD_TMP_SVNREV=$(shell cd $(PRO_DIR) && svn info 2>/dev/null | grep -E "Last Changed Rev|最后修改的版本" | sed "s/.*:\ //g")
BUILD_TMP_HASCHANGE=$(shell cd $(PRO_DIR) && svn diff | grep Index:)
BUILD_SVNREV=$(shell if [ "x$(BUILD_TMP_HASCHANGE)" != "x" ]; then expr $(BUILD_TMP_SVNREV) + 1; else echo $(BUILD_TMP_SVNREV); fi)
endif
ifeq ($(BUILD_SVNREV),)
BUILD_SVNREV=1
FIX_SVNREV=1
endif
endif
BUILD_USER=$(SHELL_USER)
#$(shell cd $(PRO_DIR) && svn info | grep -E "最后修改的作者:|Last Changed Author" | sed "s/.*:\ //g")
BUILD_DATE=$(shell date +%Y%m%d%H%M%S)
BUILD_OS=$(shell cat /etc/os-release  | grep PRETTY_NAME | sed 's/.*="//g' | sed 's/"//g')
BUILD_CPU=$(shell cat /proc/cpuinfo | grep -m1 "model name" | sed 's/.*:\ //g')
BUILD_PLATFORM=$(shell if [ -e /usr/bin/dpkg ]; then dpkg --print-architecture; else  uname -i; fi)
BUILD_KERNEL=$(shell uname -sr)

VER_SVN=$(BUILD_SVNREV)
VER_FIX=$(shell if [ $(BUILD_SVNREV) -ge $(FIX_SVNREV) ]; then echo $(shell expr $(BUILD_SVNREV) - $(FIX_SVNREV)); else echo 0; fi)

ifneq ($(BUILD_TYPE),debug)
BUILD_TYPE=release
endif

ifeq ($(VER_MAJOR),)
VER_MAJOR=0
endif
ifeq ($(VER_MINOR),)
VER_MINOR=0
endif
ifeq ($(VER_BUILD),)
ifeq ($(BUILD_TYPE),debug)
FINAL_VER_BUILD=dbg
else
FINAL_VER_BUILD=0
endif
else
ifeq ($(BUILD_TYPE),debug)
FINAL_VER_BUILD=$(VER_BUILD)-dbg
else
FINAL_VER_BUILD=$(VER_BUILD)
endif
endif


FULLVER=$(VER_MAJOR).$(VER_MINOR).$(VER_FIX)-$(FINAL_VER_BUILD)
MAINVER=$(VER_MAJOR).$(VER_MINOR).$(VER_FIX)

#define cryptolocker output file
ifeq ($(CRYPTO_KEY_IN),)
CRYPTO_KEY_IN=$(PRO_DIR)/CryptoLockerKey.main.in
ifneq ($(WORKSPACE),)
CRYPTO_KEY_IN=$(WORKSPACE)/CryptoLockerKey.main.in
endif
endif

#determine compile type
ifneq ($(BUILD_TYPE),debug)
DEBUG_CFLAGS=-O3
else
DEBUG_CFLAGS=-DDEBUG -g -O0
ifeq ($(STRIP),yes)
DEBUG_CFLAGS=-O3
endif
ifeq ($(FORCESTRIP),yes)
DEBUG_CFLAGS=-O3
endif
endif

MAKEFLAGS=-s PRO_DIR=$(PRO_DIR) MKTEMPLATE_DIR=$(MKTEMPLATE_DIR) BUILD_SVNREV=$(BUILD_SVNREV)

WARN_CFLAGS          += -Wall
WARN_CFLAGS          += -Wno-unused-result
WARN_CFLAGS          += -Wno-strict-aliasing
WARN_CFLAGS     += -Wno-unused-function
WARN_CFLAGS     += -Wno-write-strings
WARN_CFLAGS        += -Wno-unused-variable
WARN_CFLAGS        += -Wno-sign-compare
WARN_CFLAGS        += -Wno-unused-but-set-variable
WARN_CFLAGS        += -Wno-unknown-pragmas 
WARN_CFLAGS        += -Wfatal-errors

WARN_CPPFLAGS    += $(WARN_CFLAGS)
WARN_CPPFLAGS    += -Wno-delete-non-virtual-dtor

#DEFINE_CFLAGS     += -DRLRL_DEBUG

# Target install directories
ifeq ($(prefix),)
#USER_INST_DIR=$(PRO_DIR)/install
prefix=$(rootdir)/usr/local/iac
#else
endif
USER_INST_DIR		 = $(prefix)
USER_INST_LIB_DIR    = $(USER_INST_DIR)/lib
USER_INST_INC_DIR    = $(USER_INST_DIR)/include
USER_INST_RES_DIR    = $(USER_INST_DIR)/share
USER_INST_SCRIPT_DIR = $(USER_INST_DIR)/scripts
USER_INST_BIN_DIR    = $(USER_INST_DIR)/bin


# Target Package directories
ifeq ($(USER_PACK_DIR),)
USER_PACK_DIR        = $(PRO_DIR)/build
endif
USER_PACK_LIB_DIR    = $(USER_PACK_DIR)$(prefix)/lib
USER_PACK_INC_DIR    = $(USER_PACK_DIR)$(prefix)/include
USER_PACK_RES_DIR    = $(USER_PACK_DIR)$(prefix)/share
USER_PACK_SCRIPT_DIR = $(USER_PACK_DIR)$(prefix)/scripts
USER_PACK_BIN_DIR    = $(USER_PACK_DIR)$(prefix)/bin
TARGET_PACK_LIB_DIR = $(prefix)/lib
TARGET_PACK_INC_DIR = $(prefix)/include
TARGET_PACK_RES_DIR = $(prefix)/share
TARGET_PACK_SCRIPT_DIR = $(prefix)/scripts
TARGET_PACK_BIN_DIR = $(prefix)/bin


USER_PUBLIC_INC = $(PRO_DIR)/include
#INSTALL_DIR     = $(USER_PACK_LIB_DIR)
ifeq ($(OUTPUT_DIR),)
USER_RELEASE_DIR      = $(PRO_DIR)/release
else
USER_RELEASE_DIR      = $(OUTPUT_DIR)
endif

# Source code object directories
USER_OBJS_DIR   = $(PRO_DIR)/.objs/objs-$(BOARD_ARCH)
USER_TMP_DIR   = $(PRO_DIR)/.libs/libs-$(BOARD_ARCH)

ifeq ($(USER_NVARCH),)
USER_NVARCH = -gencode arch=compute_30,code=[sm_30,compute_30] \
              -gencode arch=compute_32,code=[sm_32,compute_32] \
              -gencode arch=compute_35,code=[sm_35,compute_35] \
              -gencode arch=compute_37,code=[sm_37,compute_37] \
              -gencode arch=compute_50,code=[sm_50,compute_50] \
              -gencode arch=compute_52,code=[sm_52,compute_52] \
              -gencode arch=compute_53,code=[sm_53,compute_53] \
              -gencode arch=compute_60,code=[sm_60,compute_60] \
              -gencode arch=compute_61,code=[sm_61,compute_61] \
              -gencode arch=compute_62,code=[sm_62,compute_62]
endif

ifeq ($(USE_SIMD),yes)
SIMD_CFLAGS = -msse -msse2 -mssse3 -msse4.1 -msse4.2 -mavx -mavx2
endif

ifeq ($(BOARD_ARCH),x64)
USER_ASMFLAGS += -f elf64
ifeq ($(TARGET),)
SIMD_CFLAGS += -m64
endif
else
USER_ASMFLAGS += -f elf
ifeq ($(TARGET),)
SIMD_CFLAGS += -m32
endif
endif
USER_ASMFLAGS += -g stabs

# User level program compile options
# basic library api extern
USER_INCS       += -I. -I$(USER_PUBLIC_INC) -I$(USER_INST_INC_DIR) -I$(PRO_DIR)
ifneq ($(WORKSPACE),)
USER_INCS         += -I$(WORKSPACE)/build/include
endif

DEFAULT_DEFINE_CFLAGS     += -D_GNU_SOURCE
DEFAULT_DEFINE_CFLAGS     += -D_prefix=\"$(prefix)\" -DPROJECT_NAME=\"$(PRO_NAME)\"

USER_CFLAGS     += $(DEBUG_CFLAGS) $(SIMD_CFLAGS) $(WARN_CFLAGS) $(DEFAULT_DEFINE_CFLAGS) $(DEFINE_CFLAGS) 
USER_CFLAGS     += $(USER_INCS)

USER_CPPFLAGS     += $(DEBUG_CFLAGS) $(SIMD_CFLAGS) $(WARN_CPPFLAGS) $(DEFAULT_DEFINE_CFLAGS) $(DEFINE_CFLAGS) 
USER_CPPFLAGS   += $(USER_INCS)

USER_NVFLAGS     += $(USER_NVARCH) --compiler-options "$(USER_CFLAGS)"

DEPLIBS    += -L$(USER_INST_LIB_DIR) -L$(USER_INST_LIB_DIR)/plugins -L$(USER_TMP_DIR)
ifneq ($(WORKSPACE),)
DEPLIBS     += -L$(WORKSPACE)/build/lib
endif

ifneq ($(TARGET),)
BASE_DEPLIBS     += -ldl -lm -lrt -pthread
else
BASE_DEPLIBS     += -ldl -lz -lm -lrt -pthread
endif
USER_SHLIBFLAGS = -shared
USER_STLIBFLAGS = rcs

DEB_FINAL_CONFIGFILES = $(addprefix $(prefix)/,$(DEB_CONFIGFILES))
DEB_FINAL_WRITEABLE_DIRS = $(DEB_USERWRITEABLE_DIRS)
ifeq ($(DEB_DESCRIPTION),)
DEB_DESCRIPTION=IACenter
endif

# Micros

#Color: 0black, 1red, 2green, 3yellow, 4blue, 5purple, 6cyan, 7white, default/
#$(call ECHO,<Operation>,<fColorO[:bColor0]>,<Message1>[,<fColorM1[:bColorM1]>[,<Message2>[,<fColorM2[:bColorM2]>]]])
define ECHO
    function ColorN() { \
        if [ "x$$1" == "xblack" ]; then \
            echo -n 0; \
        elif [ "x$$1" == "xred" ]; then \
            echo -n 1; \
        elif [ "x$$1" == "xgreen" ]; then \
            echo -n 2; \
        elif [ "x$$1" == "xyellow" ]; then \
            echo -n 3; \
        elif [ "x$$1" == "xblue" ]; then \
            echo -n 4; \
        elif [ "x$$1" == "xpurple" ]; then \
            echo -n 5; \
        elif [ "x$$1" == "xcyan" ]; then \
            echo -n 6; \
        elif [ "x$$1" == "xwhite" ]; then \
            echo -n 7; \
        else \
            echo -n 8; \
        fi; \
    }; \
    function ColorStr(){ \
        declare n; \
        if [ "x$$(echo $$1 | grep :)" == "x" ]; then \
            n=$$(ColorN $$1); \
            if [ $$n -ne 8 ]; then \
                echo -n "\033[1;3$${n}m"; \
            fi \
        else \
            n=$$(ColorN $${1/:*/}); \
            if [ $$n -ne 8 ]; then \
                echo -n "\033[1;3$${n}m"; \
            fi; \
            n=$$(ColorN $${1/*:/}); \
            if [ $$n -ne 8 ]; then \
                echo -n "\033[1;4$${n}m"; \
            fi; \
        fi; \
    }; \
    declare m1; \
    declare cs1; \
    declare m2; \
    declare cs2; \
    declare m3; \
    declare cs3; \
    declare cse; \
    m1=$(1); \
    cs1=$$(ColorStr $(2)); \
    m2=$(3); \
    cs2=$$(ColorStr $(4)); \
    m3=$(5); \
    cs3=$$(ColorStr $(6)); \
    cse="\033[0m"; \
    if [ "x$$c1" == "x0" ]; then \
        printf "[%12s]" $$m1; \
    else \
        printf "[$$cs1%12s$$cse]" $$m1; \
    fi; \
    if [ "x$$m2" != "x" ]; then \
        if [ "x$$c2" == "x0" ]; then \
            printf " %s" $$m2; \
        else \
            printf " $$cs2%s$$cse" $$m2; \
        fi; \
    fi; \
    if [ "x$$m3" != "x" ]; then \
        if [ "x$$c3" == "x0" ]; then \
            printf " %s" $$m3; \
        else \
            printf " $$cs3%s$$cse" $$m3; \
        fi; \
    fi; \
    printf "\n"
endef

define ECHOTEST
    echo $(1) $(3)
endef

define CleanObjs
    @$(call ECHO,Remove,green,"$(OBJS)"); \
    for obj in $(OBJS); do \
        if [ ! "x$$(dirname $$obj)" = "x" ]; then \
            $(SUDO) $(RM) $$(dirname $$obj)/*.o $$(dirname $$obj)/*.d; \
        fi; \
    done ; \
    for obj in $(LIBOBJS); do \
        if [ ! "x$$(dirname $$obj)" = "x" ]; then \
            $(SUDO) $(RM) $$(dirname $$obj)/*.o $$(dirname $$obj)/*.d; \
        fi; \
    done
endef

define InstallHeaders
    @if [ ! -d $(1) ]; then \
        $(SUDO) $(MKDIR) $(1) || exit 3; \
    fi; \
    for head in $(HEADERS); do \
        if [ "x$(2)" == "xyes" ]; then \
            $(call ECHO,CopyTo,green,"$(1)/$$head"); \
            $(SUDO) $(INSTALL) -D -m644 $$head $(1)/$$head || exit 4; \
        elif [ "x$(2)" == "xno" ]; then \
            $(call ECHO,CopyTo,green,"$(1)/$${head/*\//}"); \
            $(SUDO) $(INSTALL) -D -m644 $$head $(1)/$${head/*\//} || exit 5; \
        fi ; \
    done
endef

define UninstallHeaders
    @for head in $(HEADERS); do \
        if [ "x$(2)" == "xyes" ]; then \
            $(call ECHO,Remove,green,"$(1)/$$head"); \
            $(SUDO) $(RM) $(1)/$$head || exit 6; \
        else \
            $(call ECHO,Remove,green,"$(1)/$${head/*\//}"); \
            $(SUDO) $(RM) $(1)/$${head/*\//} || exit 7; \
        fi; \
    done
endef

define InstallSharedLib
    @if [ ! -d $(1) ]; then \
        $(SUDO) $(MKDIR) $(1) || exit 8; \
    fi; \
    $(SUDO) $(RM) $(1)/lib$(SHARED_LIB).so.$(MAINVER) || exit 9; \
    $(SUDO) $(RM) $(1)/lib$(SHARED_LIB).so.$(VER_MAJOR).$(VER_MINOR) || exit 10; \
    $(SUDO) $(RM) $(1)/lib$(SHARED_LIB).so.$(VER_MAJOR) || exit 11; \
    $(SUDO) $(RM) $(1)/lib$(SHARED_LIB).so || exit 12; \
    $(SUDO) $(INSTALL) -d -m755 $(1) || exit 13; \
    cd $(1) || exit 14; \
    if [ "x$(2)" == "xinstall" ]; then \
        $(SUDO) $(INSTALL) -m755 $(USER_TMP_DIR)/lib$(SHARED_LIB).so.$(MAINVER) $(1)/lib$(SHARED_LIB).so.$(MAINVER) || exit 15; \
        $(SUDO) $(LN) lib$(SHARED_LIB).so.$(MAINVER) lib$(SHARED_LIB).so.$(VER_MAJOR).$(VER_MINOR) || exit 16; \
        $(SUDO) $(LN) lib$(SHARED_LIB).so.$(VER_MAJOR).$(VER_MINOR) lib$(SHARED_LIB).so.$(VER_MAJOR) || exit 17; \
        $(SUDO) $(LN) lib$(SHARED_LIB).so.$(VER_MAJOR) lib$(SHARED_LIB).so || exit 18; \
		if [ "x$(CIPHER_LIB)" == "xyes" -a "x$(DEVINSTALL)" != "xyes" ]; then \
			$(SUDO) $(CIPHERBIN) -r -k $(CRYPTO_KEY_IN) -s $(USER_INST_RES_DIR)/CryptoLockerFiles -t $(FINAL_INST_LIB_DIR)/lib$(SHARED_LIB).so.$(MAINVER) 2>/dev/null 1>/dev/null; \
			$(SUDO) $(CIPHERBIN) -a -k $(CRYPTO_KEY_IN) -s $(USER_INST_RES_DIR)/CryptoLockerFiles -i $(USER_TMP_DIR)/lib$(SHARED_LIB).so.$(MAINVER) -t $(FINAL_INST_LIB_DIR)/lib$(SHARED_LIB).so.$(MAINVER) 2>/dev/null 1>/dev/null; \
			$(SUDO) $(RM) lib$(SHARED_LIB).so.$(MAINVER); \
    		$(call ECHO,AddCipherRec,green,"$(FINAL_INST_LIB_DIR)/lib$(SHARED_LIB).so.$(MAINVER)"); \
		else \
    		$(call ECHO,InstallTo,green,"$(1)/lib$(SHARED_LIB).so.$(MAINVER)"); \
		fi; \
    elif [ "x$(2)" == "xpack" ]; then \
    	$(call ECHO,InstallTo,green,"$(1)/lib$(SHARED_LIB).so.$(MAINVER)"); \
        $(SUDO) $(LN) lib$(SHARED_LIB).so.$(MAINVER) lib$(SHARED_LIB).so.$(VER_MAJOR).$(VER_MINOR) || exit 16; \
        $(SUDO) $(LN) lib$(SHARED_LIB).so.$(VER_MAJOR).$(VER_MINOR) lib$(SHARED_LIB).so.$(VER_MAJOR) || exit 17; \
        $(SUDO) $(LN) lib$(SHARED_LIB).so.$(VER_MAJOR) lib$(SHARED_LIB).so || exit 18; \
		if [ "x$(CIPHER_LIB)" == "xyes" -a "x$(DEVINSTALL)" != "xyes" ]; then \
			$(SUDO) $(CIPHERBIN) -r -k $(CRYPTO_KEY_IN) -s $(USER_PACK_RES_DIR)/CryptoLockerFiles -t $(TARGET_PACK_LIB_DIR)/lib$(SHARED_LIB).so.$(MAINVER) 2>/dev/null 1>/dev/null; \
			$(SUDO) $(CIPHERBIN) -a -k $(CRYPTO_KEY_IN) -s $(USER_PACK_RES_DIR)/CryptoLockerFiles -i $(USER_TMP_DIR)/lib$(SHARED_LIB).so.$(MAINVER) -t $(TARGET_PACK_LIB_DIR)/lib$(SHARED_LIB).so.$(MAINVER) 2>/dev/null 1>/dev/null; \
			$(SUDO) $(RM) lib$(SHARED_LIB).so.$(MAINVER); \
    		$(call ECHO,AddCipherRec,green,"$(TARGET_PACK_LIB_DIR)/lib$(SHARED_LIB).so.$(MAINVER)"); \
		else \
        	$(SUDO) $(INSTALL) -m755 $(USER_TMP_DIR)/lib$(SHARED_LIB).so.$(MAINVER) $(1)/lib$(SHARED_LIB).so.$(MAINVER) || exit 19; \
		fi; \
    fi
endef

define UninstallSharedLib
    @$(SUDO) $(RM) $(1)/lib$(SHARED_LIB).so.$(MAINVER) || exit 21; \
    $(SUDO) $(RM) $(1)/lib$(SHARED_LIB).so.$(VER_MAJOR).$(VER_MINOR) || exit 22; \
    $(SUDO) $(RM) $(1)/lib$(SHARED_LIB).so.$(VER_MAJOR) || exit 23; \
    $(SUDO) $(RM) $(1)/lib$(SHARED_LIB).so || exit 24; \
	if [ "x$(CIPHER_LIB)" == "xyes" ]; then \
		$(SUDO) $(CIPHERBIN) -r -k $(CRYPTO_KEY_IN) -s $(USER_PACK_RES_DIR)/CryptoLockerFiles -t $(TARGET_PACK_LIB_DIR)/lib$(SHARED_LIB).so.$(MAINVER) 2>/dev/null 1>/dev/null; \
		$(SUDO) $(CIPHERBIN) -r -k $(CRYPTO_KEY_IN) -s $(USER_INST_RES_DIR)/CryptoLockerFiles -t $(FINAL_INST_LIB_DIR)/lib$(SHARED_LIB).so.$(MAINVER) 2>/dev/null 1>/dev/null; \
		$(call ECHO,DelCipherRec,green,"$(TARGET_PACK_LIB_DIR)/lib$(SHARED_LIB).so.$(MAINVER)"); \
		$(call ECHO,DelCipherRec,green,"$(FINAL_INST_LIB_DIR)/lib$(SHARED_LIB).so.$(MAINVER)"); \
	else \
		$(call ECHO,Remove,green,"$(1)/lib$(SHARED_LIB).so.$(MAINVER)"); \
	fi
endef

define InstallStaticLib
    @if [ ! -d $(1) ]; then \
        $(SUDO) $(MKDIR) $(1) || exit 25; \
    fi; \
    $(SUDO) $(INSTALL) -d -m755 $(1) || exit 26; \
	if [ "x$(CIPHER_LIB)" == "xyes" -a "x$(DEVINSTALL)" != "xyes" ]; then \
    	if [ "x$(2)" == "xinstall" ]; then \
    		$(call ECHO,AddCipherRec,green,"$(FINAL_INST_LIB_DIR)/lib$(SHARED_LIB).a"); \
			$(SUDO) $(CIPHERBIN) -r -k $(CRYPTO_KEY_IN) -s $(USER_INST_RES_DIR)/CryptoLockerFiles -t $(FINAL_INST_LIB_DIR)/lib$(STATIC_LIB).a 2>/dev/null 1>/dev/null; \
			$(SUDO) $(CIPHERBIN) -a -k $(CRYPTO_KEY_IN) -s $(USER_INST_RES_DIR)/CryptoLockerFiles -i $(USER_TMP_DIR)/lib$(STATIC_LIB).a -t $(FINAL_INST_LIB_DIR)/lib$(STATIC_LIB).a 2>/dev/null 1>/dev/null; \
    	elif [ "x$(2)" == "xpack" ]; then \
    		$(call ECHO,AddCipherRec,green,"$(TARGET_PACK_LIB_DIR)/lib$(SHARED_LIB).a"); \
			$(SUDO) $(CIPHERBIN) -r -k $(CRYPTO_KEY_IN) -s $(USER_PACK_RES_DIR)/CryptoLockerFiles -t $(TARGET_PACK_LIB_DIR)/lib$(STATIC_LIB).a 2>/dev/null 1>/dev/null; \
			$(SUDO) $(CIPHERBIN) -a -k $(CRYPTO_KEY_IN) -s $(USER_PACK_RES_DIR)/CryptoLockerFiles -i $(USER_TMP_DIR)/lib$(STATIC_LIB).a -t $(TARGET_PACK_LIB_DIR)/lib$(STATIC_LIB).a 2>/dev/null 1>/dev/null; \
		fi; \
		$(SUDO) $(RM) $(1)/lib$(STATIC_LIB).a; \
	else \
    	$(SUDO) $(INSTALL) -m755 $(USER_TMP_DIR)/lib$(STATIC_LIB).a $(1)/lib$(STATIC_LIB).a || exit 27; \
    	$(call ECHO,InstallTo,green,"$(1)/lib$(SHARED_LIB).a"); \
	fi
endef

define UninstallStaticLib
	@if [ "x$(CIPHER_LIB)" == "xyes" ]; then \
    	$(call ECHO,DelCipherRec,green,"$(TARGET_PACK_LIB_DIR)/lib$(SHARED_LIB).a"); \
		$(SUDO) $(CIPHERBIN) -r -k $(CRYPTO_KEY_IN) -s $(USER_PACK_RES_DIR)/CryptoLockerFiles -t $(TARGET_PACK_LIB_DIR)/lib$(STATIC_LIB).a 2>/dev/null 1>/dev/null; \
    	$(call ECHO,DelCipherRec,green,"$(FINAL_INST_LIB_DIR)/lib$(SHARED_LIB).a"); \
		$(SUDO) $(CIPHERBIN) -r -k $(CRYPTO_KEY_IN) -s $(USER_INST_RES_DIR)/CryptoLockerFiles -t $(FINAL_INST_LIB_DIR)/lib$(STATIC_LIB).a 2>/dev/null 1>/dev/null; \
	else \
    	$(call ECHO,Remove,green,"$(1)/lib$(SHARED_LIB).a"); \
    	$(SUDO) $(RM) $(1)/lib$(STATIC_LIB).a || exit 28; \
	fi
endef

define InstallBin
    @$(call ECHO,InstallTo,green,"$(1)/$(EXEC)"); \
    $(SUDO) $(INSTALL) -D -m755 $(USER_TMP_DIR)/$(EXEC) $(1)/$(EXEC)
endef

define UninstallBin
    @$(call ECHO,Remove,green,"$(1)/$(EXEC)"); \
    if [ -f $(1)/$(EXEC) ]; then \
        $(SUDO) $(RM) $(1)/$(EXEC) || exit 32; \
    fi
endef

define InstallScripts
    @if [ ! -d $(1) ]; then \
        $(SUDO) $(MKDIR) $(1) || exit 33; \
    fi; \
    for scr in $(SCRIPTS); do \
        if [ "x$(2)" == "xyes" ]; then \
            $(call ECHO,InstallTo,green,"$(1)/$$scr"); \
            $(SUDO) $(INSTALL) -D -m755 $$scr $(1)/$$scr || exit 34; \
        elif [ "x$(2)" == "xno" ]; then \
            $(call ECHO,InstallTo,green,"$(1)/$${scr/*\//}"); \
            $(SUDO) $(INSTALL) -D -m755 $$scr $(1)/$${scr/*\//} || exit 34; \
        fi; \
    done
endef

define UninstallScripts
    @for scr in $(SCRIPTS); do \
        if [ "x$(2)" == "xyes" ]; then \
            $(call ECHO,Remove,green,"$(1)/$$scr"); \
            $(SUDO) $(RM) $(1)/$$scr || exit 35; \
        elif [ "x$(2)" == "xno" ]; then \
            $(call ECHO,Remove,green,"$(1)/$${scr/*\//}"); \
            $(SUDO) $(RM) $(1)/$${scr/*\//} || exit 35; \
        fi; \
    done
endef

define InstallResources
	@if [ "x$(1)" == "xinstall" ]; then \
    	if [ ! -d $(FINAL_INST_RES_DIR) ]; then \
        	$(SUDO) $(MKDIR) $(FINAL_INST_RES_DIR) || exit 36; \
    	fi; \
		$(SUDO) $(MKDIR) $(prefix); \
	elif [ "x$(1)" == "xpack" ]; then \
    	if [ ! -d $(FINAL_PACK_RES_DIR) ]; then \
        	$(SUDO) $(MKDIR) $(FINAL_PACK_RES_DIR) || exit 36; \
    	fi; \
		$(SUDO) $(MKDIR) $(USER_PACK_DIR)/$(prefix); \
	fi; \
	function adddefine(){ \
		deffile=$$1; \
		defname=$$2; \
		defval=$$3; \
		sed -i '$$d' $$deffile; \
		sed -i "/#define $$defname .*/d" $$deffile; \
		echo "#define $$defname \"$$defval\"" >> $$deffile; \
		echo "#endif" >> $$deffile; \
	}; \
    for res in $(RESOURCES); do \
		declare TARGET_RES_PATH; \
		declare TMP_RES_PATH;\
		declare RELATIVE_RES_PATH; \
		if [ "x$(1)" == "xinstall" ]; then \
			if [ "x$(2)" == "xyes" ]; then \
				TARGET_RES_PATH=$(FINAL_INST_RES_DIR)/$$res || exit 37; \
				TMP_RES_PATH=$(FINAL_INST_RES_DIR)/$$res || exit 38; \
			elif [ "x$(2)" == "xno" ]; then \
				TARGET_RES_PATH=$(FINAL_INST_RES_DIR)/$${res/*\//} || exit 38; \
				TMP_RES_PATH=$(FINAL_INST_RES_DIR)/$${res/*\//} || exit 38; \
			fi; \
			RELATIVE_RES_PATH=$$(realpath -m $$TARGET_RES_PATH --relative-to=$(prefix)); \
		elif [ "x$(1)" == "xpack" ]; then \
			if [ "x$(2)" == "xyes" ]; then \
				TARGET_RES_PATH=$(TARGET_PACK_RES_DIR)/$$res || exit 37; \
				TMP_RES_PATH=$(FINAL_PACK_RES_DIR)/$$res || exit 38; \
				RELATIVE_RES_PATH=$$(realpath -m $(FINAL_PACK_RES_DIR)/$$res --relative-to=$(USER_PACK_DIR)/$(prefix)); \
			elif [ "x$(2)" == "xno" ]; then \
				TARGET_RES_PATH=$(TARGET_PACK_RES_DIR)/$${res/*\//} || exit 38; \
				TMP_RES_PATH=$(FINAL_PACK_RES_DIR)/$${res/*\//} || exit 38; \
				RELATIVE_RES_PATH=$$(realpath -m $(FINAL_PACK_RES_DIR)/$${res/*\//} --relative-to=$(USER_PACK_DIR)/$(prefix)); \
			fi; \
		fi; \
        $(call ECHO,CopyTo,green,"$$TMP_RES_PATH"); \
        $(SUDO) $(INSTALL) -D -m644 $$res $$TMP_RES_PATH || exit 37; \
		TMP_RESOURCE_ID=$${RELATIVE_RES_PATH//\//_}; \
		typeset -u RESOURCE_ID; \
		RESOURCE_ID="$(PRO_NAME)_RES_$${TMP_RESOURCE_ID//./_}"; \
		adddefine $(VERSION_FILE) $$RESOURCE_ID $$TARGET_RES_PATH ;\
    done; \
    for res in $(CIPHER_RESOURCES); do \
		declare TARGET_RES_PATH; \
		declare CIPHER_STORE_PATH;\
		declare RELATIVE_RES_PATH; \
		if [ "x$(1)" == "xinstall" ]; then \
			CIPHER_STORE_PATH=$(USER_INST_RES_DIR)/CryptoLockerFiles || exit 38; \
			if [ "x$(2)" == "xyes" ]; then \
				TARGET_RES_PATH=$(FINAL_INST_RES_DIR)/$$res || exit 37; \
			elif [ "x$(2)" == "xno" ]; then \
				TARGET_RES_PATH=$(FINAL_INST_RES_DIR)/$${res/*\//} || exit 38; \
			fi; \
			RELATIVE_RES_PATH=$$(realpath -m $$TARGET_RES_PATH --relative-to=$(prefix)); \
		elif [ "x$(1)" == "xpack" ]; then \
			CIPHER_STORE_PATH=$(USER_PACK_RES_DIR)/CryptoLockerFiles || exit 38; \
			if [ "x$(2)" == "xyes" ]; then \
				TARGET_RES_PATH=$(TARGET_PACK_RES_DIR)/$$res || exit 37; \
				RELATIVE_RES_PATH=$$(realpath -m $(FINAL_PACK_RES_DIR)/$$res --relative-to=$(USER_PACK_DIR)/$(prefix)); \
			elif [ "x$(2)" == "xno" ]; then \
				TARGET_RES_PATH=$(TARGET_PACK_RES_DIR)/$${res/*\//} || exit 38; \
				RELATIVE_RES_PATH=$$(realpath -m $(FINAL_PACK_RES_DIR)/$${res/*\//} --relative-to=$(USER_PACK_DIR)/$(prefix)); \
			fi; \
		fi; \
        $(call ECHO,AddCipherRec,green,"$$TARGET_RES_PATH"); \
		$(SUDO) $(MKDIR) $$CIPHER_STORE_PATH; \
		$(SUDO) $(CIPHERBIN) -r -k $(CRYPTO_KEY_IN) -s $$CIPHER_STORE_PATH -t $$TARGET_RES_PATH 2>/dev/null 1>/dev/null; \
		$(SUDO) $(CIPHERBIN) -a -k $(CRYPTO_KEY_IN) -s $$CIPHER_STORE_PATH -i $$res -t $$TARGET_RES_PATH 2>/dev/null 1>/dev/null; \
		TMP_RESOURCE_ID=$${RELATIVE_RES_PATH//\//_}; \
		typeset -u RESOURCE_ID; \
		RESOURCE_ID="$(PRO_NAME)_RES_CIPHER_$${TMP_RESOURCE_ID//./_}"; \
		adddefine $(VERSION_FILE) $$RESOURCE_ID $$TARGET_RES_PATH ;\
    done
endef

define InstallDepLibFiles
    @if [ ! -d $(1) ]; then \
        $(SUDO) $(MKDIR) $(1) || exit 36; \
    fi; \
    for res in $(DEPLIBFILES); do \
        $(call ECHO,CopyTo,green,"$(1)/$${res/*\//}"); \
        $(SUDO) $(INSTALL) -D -m755 $$res $(1)/$${res/*\//} || exit 37; \
    done
endef

define UninstallResources
    @for res in $(RESOURCES); do \
		declare TARGET_RES_PATH; \
		declare TMP_RES_PATH;\
		if [ "x$(1)" == "xuninstall" ]; then \
			if [ "x$(2)" == "xyes" ]; then \
				TARGET_RES_PATH=$(FINAL_INST_RES_DIR)/$$res || exit 37; \
				TMP_RES_PATH=$(FINAL_INST_RES_DIR)/$$res || exit 38; \
			elif [ "x$(2)" == "xno" ]; then \
				TARGET_RES_PATH=$(FINAL_INST_RES_DIR)/$${res/*\//} || exit 38; \
				TMP_RES_PATH=$(FINAL_INST_RES_DIR)/$${res/*\//} || exit 38; \
			fi; \
		elif [ "x$(1)" == "xpack" ]; then \
			if [ "x$(2)" == "xyes" ]; then \
				TARGET_RES_PATH=$(TARGET_PACK_RES_DIR)/$$res || exit 37; \
				TMP_RES_PATH=$(FINAL_PACK_RES_DIR)/$$res || exit 38; \
			elif [ "x$(2)" == "xno" ]; then \
				TARGET_RES_PATH=$(TARGET_PACK_RES_DIR)/$${res/*\//} || exit 38; \
				TMP_RES_PATH=$(FINAL_PACK_RES_DIR)/$${res/*\//} || exit 38; \
			fi; \
		fi; \
        $(call ECHO,Remove,green,"$$TMP_RES_PATH"); \
        $(SUDO) $(RM) $$TMP_RES_PATH || exit 38; \
    done; \
    for res in $(CIPHER_RESOURCES); do \
		declare TARGET_RES_PATH; \
		declare TMP_RES_PATH;\
		if [ "x$(1)" == "xuninstall" ]; then \
			CIPHER_STORE_PATH=$(USER_INST_RES_DIR)/CryptoLockerFiles || exit 38; \
			if [ "x$(2)" == "xyes" ]; then \
				TARGET_RES_PATH=$(FINAL_INST_RES_DIR)/$$res || exit 37; \
				TMP_RES_PATH=$(FINAL_INST_RES_DIR)/$$res || exit 38; \
			elif [ "x$(2)" == "xno" ]; then \
				TARGET_RES_PATH=$(FINAL_INST_RES_DIR)/$${res/*\//} || exit 38; \
				TMP_RES_PATH=$(FINAL_INST_RES_DIR)/$${res/*\//} || exit 38; \
			fi; \
		elif [ "x$(1)" == "xpack" ]; then \
			CIPHER_STORE_PATH=$(USER_PACK_RES_DIR)/CryptoLockerFiles || exit 38; \
			if [ "x$(2)" == "xyes" ]; then \
				TARGET_RES_PATH=$(TARGET_PACK_RES_DIR)/$$res || exit 37; \
				TMP_RES_PATH=$(FINAL_PACK_RES_DIR)/$$res || exit 38; \
			elif [ "x$(2)" == "xno" ]; then \
				TARGET_RES_PATH=$(TARGET_PACK_RES_DIR)/$${res/*\//} || exit 38; \
				TMP_RES_PATH=$(FINAL_PACK_RES_DIR)/$${res/*\//} || exit 38; \
			fi; \
		fi; \
		$(call ECHO,DelCipherRec,green,"$$TARGET_RES_PATH"); \
		$(SUDO) $(CIPHERBIN) -r -k $(CRYPTO_KEY_IN) -s $$CIPHER_STORE_PATH -t $$TARGET_RES_PATH 2>/dev/null 1>/dev/null; \
    done
endef

define UninstallDepLibFiles
    @for res in $(DEPLIBFILES); do \
        $(call ECHO,Remove,green,"$(1)/$${res/*\//}"); \
        $(SUDO) $(RM) $(1)/$${res/*\//} || exit 38; \
    done
endef

#INFILE=$(shell realpath -m --relative-to=. $(2)); 
#OUTFILE=$(shell realpath -m --relative-to=. $(1)); 
define MakeObject
    INFILE=$(patsubst $(PRO_DIR)/%,%,$(2)); \
    OUTFILE=$(patsubst $(PRO_DIR)/%,%,$(1)); \
    CUR_DIR=$(shell pwd); \
    cd $(PRO_DIR); \
    $(MKDIR) $(dir $(1)); \
    if [ "$(patsubst $(basename $(2)).%,%,$(2))" == "c" ]; then \
        $(call ECHO,Compile,green,"$(LLCC)",cyan,"$(SHARED_FLAGS) $(STD_CFLAG) $(DEFINE_CFLAGS) $$INFILE -o $$OUTFILE"); \
        if [ "$(SILENTMAKE)" == "no" ]; then \
            echo "$(LLCC) $(STD_CFLAG) $(USER_CFLAGS) -I$${CUR_DIR} -c -o $$OUTFILE $$INFILE"; \
        fi; \
        $(LLCC) $(STD_CFLAG) $(USER_CFLAGS) -I$${CUR_DIR} -c -o $$OUTFILE $$INFILE; \
    elif [ "$(patsubst $(basename $(2)).%,%,$(2))" == "cc" -o "$(patsubst $(basename $(2)).%,%,$(2))" == "cpp" ]; then \
        $(call ECHO,Compile,green,"$(LLCXX)",cyan,"$(SHARED_FLAGS) $(STD_CPPFLAG) $(DEFINE_CFLAGS) $$INFILE -o $$OUTFILE"); \
        if [ "$(SILENTMAKE)" == "no" ]; then \
            echo "$(LLCXX) $(STD_CPPFLAG) $(USER_CPPFLAGS) -I$${CUR_DIR} -c -o $$OUTFILE $$INFILE"; \
        fi; \
        $(LLCXX) $(STD_CPPFLAG) $(USER_CPPFLAGS) -I$${CUR_DIR} -c -o $$OUTFILE $$INFILE; \
    elif [ "$(patsubst $(basename $(2)).%,%,$(2))" == "asm" -o "$(patsubst $(basename $(2)).%,%,$(2))" == "nasm" -o "$(patsubst $(basename $(2)).%,%,$(2))" == "yasm" ]; then \
        $(call ECHO,Compile,green,"$(LLASM)",cyan,"$(USER_ASMFLAGS) $$INFILE -o $$OUTFILE"); \
        if [ "$(SILENTMAKE)" == "no" ]; then \
            echo "$(LLASM) $(USER_ASMFLAGS) -o $$OUTFILE $$INFILE"; \
        fi; \
        $(LLASM) $(USER_ASMFLAGS) -o $$OUTFILE $$INFILE; \
    elif [ "$(patsubst $(basename $(2)).%,%,$(2))" == "cu" ]; then \
        $(call ECHO,Compile,green,"$(LLNVCC)",cyan,"$(SHARED_FLAGS) $(NVSTD_CPPFLAG) $(DEFINE_CFLAGS) $$INFILE -o $$OUTFILE"); \
        if [ "$(SILENTMAKE)" == "no" ]; then \
            echo "$(LLNVCC) $(NVSTD_CPPFLAG) $(USER_NVFLAGS) -I$${CUR_DIR} -c $$INFILE -o $$OUTFILE"; \
        fi; \
        $(LLNVCC) $(NVSTD_CPPFLAG) $(USER_NVFLAGS) -I$${CUR_DIR} -c $$INFILE -o $$OUTFILE; \
    fi; \
    cd $${CUR_DIR}
endef

define Promot
    @declare _target; \
    if [ "$(2)" == "" ]; then \
        _target=$(patsubst $(PRO_DIR)%,%,$(shell pwd)); \
    else \
        _target=$(patsubst $(PRO_DIR)%,%,$(2)); \
    fi; \
    if [ -z "$$_target" ]; then \
        _target=. ; \
    elif [ "$${_target:0:1}" == "/" ]; then \
        _target=$${_target:1}; \
    fi; \
    if [ "x$(2)" == "x" ]; then \
        $(call ECHO,$(1),red,"subdir",,"$$_target",cyan); \
    else \
    $(call ECHO,$(1),purple,"target",,"$$_target",cyan); \
    fi
endef

define StripFile
    if [ "$(STRIP)" == "yes" -o "$(FORCESTRIP)" == "yes" ]; then \
		$(call ECHO,"Strip",red,"$$(basename $(1))",yellow:blue); \
        $(LLSTRIP) $(1); \
    fi
endef

define MakeDeb
    $(SUDO) $(MKDIR) $(USER_PACK_DIR)/DEBIAN; \
	$(SUDO) chown -R $(shell whoami):$(shell whoami) $(USER_PACK_DIR); \
    echo "Package: $(PRO_NAME)"             > $(USER_PACK_DIR)/DEBIAN/control; \
    echo "Source: $(PRO_NAME)-source"         >> $(USER_PACK_DIR)/DEBIAN/control; \
    echo "Version: $(FULLVER)-gcc$(COMPILER_VERSION)"     >> $(USER_PACK_DIR)/DEBIAN/control; \
    echo "Architecture: $(ARCH)"         >> $(USER_PACK_DIR)/DEBIAN/control; \
    echo "Maintainer: $(SHELL_USER) <$(DEB_EMAIL)>"             >> $(USER_PACK_DIR)/DEBIAN/control; \
    if [ ! -z "$(DEB_PREDEPENDS)" ]; then \
        echo "PreDepends: $(DEB_PREDEPENDS)"             >> $(USER_PACK_DIR)/DEBIAN/control; \
    fi; \
    if [ ! -z "$(DEB_DEPENDS)" ]; then \
        echo "Depends: $(DEB_DEPENDS)"             >> $(USER_PACK_DIR)/DEBIAN/control; \
    fi; \
    echo "Section: lijingfeng"             >> $(USER_PACK_DIR)/DEBIAN/control; \
    echo "Priority: optional"             >> $(USER_PACK_DIR)/DEBIAN/control; \
    echo -en "Description: $(DEB_DESCRIPTION)\n"             >> $(USER_PACK_DIR)/DEBIAN/control; \
    $(MKDIR) $(USER_PACK_DIR)/etc/ld.so.conf.d; \
    echo $(TARGET_PACK_LIB_DIR) > $(USER_PACK_DIR)/etc/ld.so.conf.d/$(PRO_NAME).conf; \
    echo "/etc/ld.so.conf.d/$(PRO_NAME).conf" > $(USER_PACK_DIR)/DEBIAN/conffiles; \
    for cf in $(DEB_FINAL_CONFIGFILES); do \
        if [ "$(DEB_CONFIG_CREATE_DEFAULT)" == "yes" ]; then \
            echo "$${cf}.default" >> $(USER_PACK_DIR)/DEBIAN/conffiles; \
        else \
            echo "$${cf}" >> $(USER_PACK_DIR)/DEBIAN/conffiles; \
        fi; \
    done; \
    echo "#!/bin/bash" > $(USER_PACK_DIR)/DEBIAN/preinst; \
    echo "set -e" >> $(USER_PACK_DIR)/DEBIAN/preinst; \
    echo "mkdir -p $(TARGET_PACK_RES_DIR)/CryptoLockerFiles" >> $(USER_PACK_DIR)/DEBIAN/preinst; \
    echo "mkdir -p $(TARGET_PACK_RES_DIR)/$(PRO_NAME)" >> $(USER_PACK_DIR)/DEBIAN/preinst; \
    echo "chmod -R 0775 $(TARGET_PACK_RES_DIR)/$(PRO_NAME)" >> $(USER_PACK_DIR)/DEBIAN/preinst; \
	echo "chown -R root:root $(TARGET_PACK_RES_DIR)/$(PRO_NAME)" >> $(USER_PACK_DIR)/DEBIAN/preinst; \
    echo "mkdir -p /var/run/$(PRO_NAME)" >> $(USER_PACK_DIR)/DEBIAN/preinst; \
    echo "chmod -R 0775 /var/run/$(PRO_NAME)" >> $(USER_PACK_DIR)/DEBIAN/preinst; \
	echo "chown -R root:root /var/run/$(PRO_NAME)" >> $(USER_PACK_DIR)/DEBIAN/preinst; \
	echo "chown -R root:root $(prefix)" >> $(USER_PACK_DIR)/DEBIAN/preinst; \
    echo "#!/bin/bash" > $(USER_PACK_DIR)/DEBIAN/postinst; \
    echo "set -e" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
    echo -n "if [ \"$$" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
    echo "1\" = \"configure\" ]; then" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
    echo "    ldconfig" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
    for cf in $(DEB_FINAL_CONFIGFILES); do \
        if [ "$(DEB_CONFIG_CREATE_DEFAULT)" == "yes" ]; then \
            if [ -e "$(USER_PACK_DIR)$$cf" ]; then \
                $(SUDO) mv $(USER_PACK_DIR)$$cf $(USER_PACK_DIR)$${cf}.default; \
            fi; \
            if [ "$(DEB_CONFIG_OVERRIDE)" != "no" ]; then \
                echo "    cp $${cf}.default $${cf}" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
            else \
				echo "    if [ ! -f $${cf} ]; then" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
				echo "        cp $${cf}.default $${cf} " >> $(USER_PACK_DIR)/DEBIAN/postinst; \
				echo "    else" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
                echo "        touch $${cf}" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
				echo "    fi" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
            fi; \
        fi; \
        echo "    chmod 0777 $${cf}" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
    done; \
    for cf in $(DEB_FINAL_WRITEABLE_DIRS); do \
        echo "  mkdir -p $$cf" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
        echo "    chmod -R 0777 $$cf" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
    done; \
    echo "fi" >> $(USER_PACK_DIR)/DEBIAN/postinst; \
    echo "#!/bin/bash" > $(USER_PACK_DIR)/DEBIAN/postrm; \
    echo "set -e" >> $(USER_PACK_DIR)/DEBIAN/postrm; \
    echo -n "if [ \"$$" >> $(USER_PACK_DIR)/DEBIAN/postrm; \
    echo "1\" = \"remove\" ]; then" >> $(USER_PACK_DIR)/DEBIAN/postrm; \
    echo "    ldconfig" >> $(USER_PACK_DIR)/DEBIAN/postrm; \
    echo "    rm -rf $(TARGET_PACK_RES_DIR)/$(PRO_NAME)" >> $(USER_PACK_DIR)/DEBIAN/postrm; \
    echo "fi" >> $(USER_PACK_DIR)/DEBIAN/postrm; \
	echo -n "if [ \"$$" >> $(USER_PACK_DIR)/DEBIAN/postrm; \
	echo "1\" = \"purge\" ]; then" >> $(USER_PACK_DIR)/DEBIAN/postrm; \
	echo "	 rm -rf $(DEB_FINAL_CONFIGFILES)" >> $(USER_PACK_DIR)/DEBIAN/postrm; \
	echo "fi" >> $(USER_PACK_DIR)/DEBIAN/postrm; \
    chmod 0775 $(USER_PACK_DIR)/DEBIAN/postrm; \
    chmod 0775 $(USER_PACK_DIR)/DEBIAN/postinst; \
    chmod 0775 $(USER_PACK_DIR)/DEBIAN/preinst; \
	$(SUDO) chown -R root:root $(USER_PACK_DIR); \
    $(SUDO) $(DPKG-DEB) -Znone -Snone -b $(USER_PACK_DIR) $(DEBBALL) >/dev/null
endef
