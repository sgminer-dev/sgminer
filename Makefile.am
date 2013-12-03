
ACLOCAL_AMFLAGS = -I m4

JANSSON_INCLUDES= -I$(top_builddir)/compat/jansson-2.5/src -I$(top_srcdir)/compat/jansson-2.5/src

EXTRA_DIST	= example.conf m4/gnulib-cache.m4 linux-usb-cgminer \
		  ADL_SDK/readme.txt api-example.php miner.php	\
		  API.class API.java api-example.c windows-build.txt \
		  API-README SCRYPT-README hexdump.c GPU-README

SUBDIRS		= lib compat ccan

INCLUDES	= $(PTHREAD_FLAGS) -fno-strict-aliasing $(JANSSON_INCLUDES)

bin_PROGRAMS	= cgminer

cgminer_LDFLAGS	= $(PTHREAD_FLAGS)
cgminer_LDADD	= $(DLOPEN_FLAGS) @LIBCURL_LIBS@ @JANSSON_LIBS@ @PTHREAD_LIBS@ \
		  @OPENCL_LIBS@ @NCURSES_LIBS@ @PDCURSES_LIBS@ @WS2_LIBS@ \
		  @MM_LIBS@ @RT_LIBS@ @MATH_LIBS@ lib/libgnu.a ccan/libccan.a

if HAVE_WINDOWS
cgminer_CPPFLAGS = -I$(top_builddir)/lib -I$(top_srcdir)/lib @OPENCL_FLAGS@
else
cgminer_CPPFLAGS = -I$(top_builddir)/lib -I$(top_srcdir)/lib @OPENCL_FLAGS@ @LIBCURL_CFLAGS@
endif

cgminer_CPPFLAGS += $(ADL_CPPFLAGS)

cgminer_SOURCES := cgminer.c
cgminer_SOURCES	+= api.c
cgminer_SOURCES	+= elist.h miner.h compat.h bench_block.h
cgminer_SOURCES	+= util.c util.h uthash.h
cgminer_SOURCES	+= sha2.c sha2.h
cgminer_SOURCES	+= logging.c logging.h
cgminer_SOURCES += driver-opencl.c driver-opencl.h
cgminer_SOURCES += ocl.c ocl.h
cgminer_SOURCES += findnonce.c findnonce.h
cgminer_SOURCES += adl.c adl.h adl_functions.h
cgminer_SOURCES += scrypt.c scrypt.h
cgminer_SOURCES += *.cl

bin_SCRIPTS	= $(top_srcdir)/*.cl

