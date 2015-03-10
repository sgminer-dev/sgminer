
ACLOCAL_AMFLAGS = -I m4

JANSSON_CPPFLAGS= -I$(top_builddir)/submodules/jansson/src -I$(top_srcdir)/submodules/jansson/src

EXTRA_DIST	= example.conf m4/gnulib-cache.m4 \
		  ADL_SDK/readme.txt api-example.php miner.php	\
		  API.class API.java api-example.c hexdump.c \
		  doc/API doc/FAQ doc/GPU doc/SCRYPT doc/windows-build.txt

SUBDIRS		= lib submodules ccan sph

bin_PROGRAMS     = sgminer

sgminer_CPPFLAGS = $(PTHREAD_FLAGS) -fno-strict-aliasing $(JANSSON_CPPFLAGS)
sgminer_LDFLAGS  = $(PTHREAD_FLAGS)
sgminer_LDADD    = $(DLOPEN_FLAGS) @LIBCURL_LIBS@ @JANSSON_LIBS@ @PTHREAD_LIBS@ \
		  @OPENCL_LIBS@ @NCURSES_LIBS@ @PDCURSES_LIBS@ @WS2_LIBS@ \
		  @MM_LIBS@ @RT_LIBS@ @MATH_LIBS@ lib/libgnu.a ccan/libccan.a sph/libsph.a

sgminer_CPPFLAGS += -I$(top_builddir)/lib -I$(top_srcdir)/lib @OPENCL_FLAGS@

if !HAVE_WINDOWS
sgminer_CPPFLAGS += @LIBCURL_CFLAGS@
endif

sgminer_CPPFLAGS += $(ADL_CPPFLAGS)

if USE_GIT_VERSION
GIT_VERSION      := $(shell sh -c 'git describe --abbrev=4 --dirty')
sgminer_CPPFLAGS += -DGIT_VERSION=\"$(GIT_VERSION)\"
endif

sgminer_SOURCES := sgminer.c
sgminer_SOURCES	+= api.c api.h
sgminer_SOURCES	+= elist.h miner.h compat.h bench_block.h
sgminer_SOURCES	+= util.c util.h uthash.h
sgminer_SOURCES	+= logging.c logging.h
sgminer_SOURCES += driver-opencl.c driver-opencl.h
sgminer_SOURCES += ocl.c ocl.h
sgminer_SOURCES += findnonce.c findnonce.h
sgminer_SOURCES += adl.c adl.h adl_functions.h
sgminer_SOURCES += pool.c pool.h
sgminer_SOURCES += algorithm.c algorithm.h
sgminer_SOURCES += config_parser.c config_parser.h
sgminer_SOURCES += events.c events.h
sgminer_SOURCES += ocl/patch_kernel.c ocl/patch_kernel.h
sgminer_SOURCES += ocl/build_kernel.c ocl/build_kernel.h
sgminer_SOURCES += ocl/binary_kernel.c ocl/binary_kernel.h

sgminer_SOURCES += kernel/*.cl
sgminer_SOURCES += algorithm/scrypt.c algorithm/scrypt.h
sgminer_SOURCES += algorithm/darkcoin.c algorithm/darkcoin.h
sgminer_SOURCES += algorithm/qubitcoin.c algorithm/qubitcoin.h
sgminer_SOURCES += algorithm/quarkcoin.c algorithm/quarkcoin.h
sgminer_SOURCES += algorithm/myriadcoin-groestl.c algorithm/myriadcoin-groestl.h
sgminer_SOURCES += algorithm/fuguecoin.c algorithm/fuguecoin.h
sgminer_SOURCES += algorithm/inkcoin.c algorithm/inkcoin.h
sgminer_SOURCES += algorithm/animecoin.c algorithm/animecoin.h
sgminer_SOURCES += algorithm/groestlcoin.c algorithm/groestlcoin.h
sgminer_SOURCES += algorithm/sifcoin.c algorithm/sifcoin.h
sgminer_SOURCES += algorithm/twecoin.c algorithm/twecoin.h
sgminer_SOURCES += algorithm/marucoin.c algorithm/marucoin.h
sgminer_SOURCES += algorithm/maxcoin.c algorithm/maxcoin.h
sgminer_SOURCES += algorithm/talkcoin.c algorithm/talkcoin.h
sgminer_SOURCES += algorithm/bitblock.c algorithm/bitblock.h
sgminer_SOURCES += algorithm/x14.c algorithm/x14.h
sgminer_SOURCES += algorithm/fresh.c algorithm/fresh.h
sgminer_SOURCES += algorithm/whirlcoin.c algorithm/whirlcoin.h
sgminer_SOURCES += algorithm/neoscrypt.c algorithm/neoscrypt.h
sgminer_SOURCES += algorithm/whirlpoolx.c algorithm/whirlpoolx.h
sgminer_SOURCES += algorithm/lyra2re.c algorithm/lyra2re.h algorithm/lyra2.c algorithm/lyra2.h algorithm/sponge.c algorithm/sponge.h
sgminer_SOURCES += algorithm/pluck.c algorithm/pluck.h

bin_SCRIPTS	= $(top_srcdir)/kernel/*.cl

