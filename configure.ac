##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
m4_define([v_maj], [5])
m4_define([v_min], [1])
m4_define([v_mic], [1])
##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
m4_define([v_ver], [v_maj.v_min.v_mic])
m4_define([lt_rev], m4_eval(v_maj + v_min))
m4_define([lt_cur], v_mic)
m4_define([lt_age], v_min)
##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##

AC_INIT([sgminer], [v_ver], [veox@wemakethings.net], [sgminer], [https://github.com/sgminer-dev/sgminer])

AC_PREREQ(2.59)
AC_CANONICAL_SYSTEM
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_SRCDIR([sgminer.c])
AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([foreign subdir-objects])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])
AC_USE_SYSTEM_EXTENSIONS

##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
m4_ifdef([v_rev], , [m4_define([v_rev], [0])])
m4_ifdef([v_rel], , [m4_define([v_rel], [])])
AC_DEFINE_UNQUOTED(SGMINER_MAJOR_VERSION, [v_maj], [Major version])
AC_DEFINE_UNQUOTED(SGMINER_MINOR_VERSION, [v_min], [Minor version])
AC_DEFINE_UNQUOTED(SGMINER_MINOR_SUBVERSION, [v_mic], [Micro version])
version_info="lt_rev:lt_cur:lt_age"
release_info="v_rel"
AC_SUBST(version_info)
AC_SUBST(release_info)
##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
VMAJ=v_maj
AC_SUBST(VMAJ)

AC_CANONICAL_BUILD
AC_CANONICAL_HOST

dnl Make sure anyone changing configure.ac/Makefile.am has a clue
AM_MAINTAINER_MODE

dnl Checks for programs
AC_PROG_CC
gl_EARLY
AC_PROG_GCC_TRADITIONAL
AM_PROG_CC_C_O
LT_INIT([disable-shared])

gl_INIT

dnl Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS(syslog.h)

AC_FUNC_ALLOCA

have_win32=false
PTHREAD_FLAGS="-lpthread"
DLOPEN_FLAGS="-ldl"
OPENCL_LIBS="-lOpenCL"
WS2_LIBS=""
MM_LIBS=""
MATH_LIBS="-lm"
RT_LIBS="-lrt"

case $target in
  amd64-*)
    have_x86_64=true
    ;;
  x86_64-*)
    have_x86_64=true
    ;;
  *)
    have_x86_64=false
    ;;
esac

case $target in
  *-*-linux-gnu*)
    have_linux=true
    ;;
  *-*-mingw*)
    have_win32=true
    PTHREAD_FLAGS=""
    DLOPEN_FLAGS=""
    WS2_LIBS="-lws2_32"
    MM_LIBS="-lwinmm"
    RT_LIBS=""
    AC_DEFINE([_WIN32_WINNT], [0x0501], "WinNT version for XP+ support")
    ;;
  powerpc-*-darwin*)
    have_darwin=true
    CFLAGS="$CFLAGS -faltivec"
    OPENCL_LIBS=""
    PTHREAD_FLAGS=""
    RT_LIBS=""
    ;;
  *-*-darwin*)
    have_darwin=true
    OPENCL_LIBS="-framework OpenCL"
    PTHREAD_FLAGS=""
    RT_LIBS=""
	;;
esac


if test "x$have_win32" != xtrue; then
	if test "x$have_x86_64" = xtrue; then
		ARCH_DIR=x86_64
	else
		ARCH_DIR=x86
	fi

	if test "x$ATISTREAMSDKROOT" != x; then
		OPENCL_FLAGS="-I$ATISTREAMSDKROOT/include $OPENCL_FLAGS"
		OPENCL_LIBS="-L$ATISTREAMSDKROOT/lib/$ARCH_DIR $OPENCL_LIBS"
	fi

	if test "x$AMDAPPSDKROOT" != x; then
		OPENCL_FLAGS="-I$AMDAPPSDKROOT/include $OPENCL_FLAGS"
		OPENCL_LIBS="-L$AMDAPPSDKROOT/lib/$ARCH_DIR $OPENCL_LIBS"
	fi
fi

have_sgminer_sdk=false
if test -n "$SGMINER_SDK"; then
	have_sgminer_sdk=true
	CPPFLAGS="-I$SGMINER_SDK/include $CPPFLAGS"
	LDFLAGS="-L$SGMINER_SDK/lib/$target $LDFLAGS"
fi

# Check for OpenCL (the long way needed on mingw32 due to calling conventions)
AC_MSG_CHECKING([for OpenCL])
SAVED_LIBS=$LIBS
SAVED_CFLAGS=$CFLAGS
LIBS="$LIBS $OPENCL_LIBS"
CFLAGS="$CFLAGS $OPENCL_FLAGS"
AC_LINK_IFELSE(
	[AC_LANG_PROGRAM([[
		#ifdef __APPLE_CC__
		#include <OpenCL/opencl.h>
		#else
		#include <CL/cl.h>
		#endif
	]],
	[[return clSetKernelArg(0, 0, 0, 0); ]])],
	[AC_MSG_RESULT(yes)
		found_opencl=1],
	[AC_MSG_RESULT(no)
		OPENCL_FLAGS=
		OPENCL_LIBS=
		found_opencl=0])
LIBS=$SAVED_LIBS
CFLAGS=$SAVED_CFLAGS

has_winpthread=false
if test "x$have_win32" = xtrue; then
        has_winpthread=true
        AC_CHECK_LIB(winpthread, nanosleep, , has_winpthread=false)
        PTHREAD_LIBS=-lwinpthread
fi

if test "x$has_winpthread" != xtrue; then
        AC_CHECK_LIB(pthread, pthread_create, ,
                AC_MSG_ERROR([Could not find pthread library - please install libpthread]))
        PTHREAD_LIBS=-lpthread
fi

AC_ARG_ENABLE([adl],
	[AC_HELP_STRING([--disable-adl],[Override detection and disable building with ADL])],
	[adl=$enableval]
	)

AC_ARG_ENABLE([adl_checks],
	[AC_HELP_STRING([--disable-adl-checks],[Override detection and assume ADL is available])],
	[adl_checks=$enableval]
	)

if test "$found_opencl" = 1; then
	if test "x$adl" != xno; then
		dnl FIXME: force ADL usage if disable-checks specified
		if test "x$adl_checks" = xno; then
			have_adl=true
			ADL_CPPFLAGS=-I$srcdir
		fi

		dnl Check if include files are in $srcdir/ADL_SDK
		if test "x$have_adl" != xtrue; then
			ADL_CPPFLAGS=
			AC_CHECK_FILE([$srcdir/ADL_SDK/adl_sdk.h], [have_adl=true; ADL_CPPFLAGS=-I$srcdir], have_adl=false,)
		fi

		dnl FIXME: Check if SGMINER_SDK present
		if test x$have_adl+$have_sgminer_sdk = xfalse+true; then
			AC_CHECK_FILE([$SGMINER_SDK/include/ADL_SDK/adl_sdk.h], [have_adl=true; ADL_CPPFLAGS=-I$SGMINER_SDK/include], have_adl=false,)
		fi

		if test "x$have_adl" = xtrue
		then
			AC_DEFINE([HAVE_ADL], [1], [Defined if ADL headers were found])
		else
			DLOPEN_FLAGS=""
		fi
	fi
else
	DLOPEN_FLAGS=""
fi

AC_ARG_ENABLE([git-version],
	AS_HELP_STRING([--disable-git-version],
		[Disable use of git version in version string even if available]),
		[wantgitver=$enableval], [wantgitver=yes])

curses="auto"

AC_ARG_WITH([curses],
	[AC_HELP_STRING([--without-curses],[Compile support for curses TUI (default enabled)])],
	[curses=$withval]
	)
if test "x$curses" = "xno"; then
	cursesmsg='User specified --without-curses. TUI support DISABLED'
else
	AC_SEARCH_LIBS(addstr, ncurses pdcurses, [
		curses=yes
		cursesmsg="FOUND: ${ac_cv_search_addstr}"
		AC_DEFINE([HAVE_CURSES], [1], [Defined to 1 if curses TUI support is wanted])
	], [
		if test "x$curses" = "xyes"; then
			AC_MSG_ERROR([Could not find curses library - please install libncurses-dev or pdcurses-dev (or configure --without-curses)])
		else
			AC_MSG_WARN([Could not find curses library - if you want a TUI, install libncurses-dev or pdcurses-dev])
			curses=no
			cursesmsg='NOT FOUND. TUI support DISABLED'
		fi
	])
fi

AM_CONDITIONAL([HAVE_CURSES], [test x$curses = xyes])
AM_CONDITIONAL([HAVE_WINDOWS], [test x$have_win32 = xtrue])
AM_CONDITIONAL([HAVE_x86_64], [test x$have_x86_64 = xtrue])

AC_CONFIG_SUBDIRS([submodules/jansson])
JANSSON_LIBS="submodules/jansson/src/.libs/libjansson.a"

PKG_PROG_PKG_CONFIG()

if test "x$have_sgminer_sdk" = "xtrue"; then
	if test "x$have_x86_64" = xtrue; then
		ARCH_DIR=x86_64
	else
		ARCH_DIR=x86
	fi
	PKG_CONFIG="${PKG_CONFIG:-pkg-config} --define-variable=arch=$ARCH_DIR --define-variable=target=$target --define-variable=sgminersdkdir=$SGMINER_SDK"
	PKG_CONFIG_PATH="$SGMINER_SDK/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
fi

AC_ARG_ENABLE([libcurl],
	[AC_HELP_STRING([--disable-libcurl],[Disable building with libcurl for getwork and GBT support])],
	[libcurl=$enableval]
	)

if test "x$libcurl" != xno; then
	if test "x$have_win32" != xtrue; then
		PKG_CHECK_MODULES([LIBCURL], [libcurl >= 7.25.0], [AC_DEFINE([CURL_HAS_KEEPALIVE], [1], [Defined if version of curl supports keepalive.])],
			[PKG_CHECK_MODULES([LIBCURL], [libcurl >= 7.18.2], ,[AC_MSG_ERROR([Missing required libcurl dev >= 7.18.2])])])
	else
		PKG_CHECK_MODULES([LIBCURL], [libcurl >= 7.25.0], ,[AC_MSG_ERROR([Missing required libcurl dev >= 7.25.0])])
		AC_DEFINE([CURL_HAS_KEEPALIVE], [1])
	fi
	AC_DEFINE([HAVE_LIBCURL], [1], [Defined to 1 if libcurl support built in])
else
	LIBCURL_LIBS=""
fi
AC_SUBST(LIBCURL_LIBS)

# Enable or disable use of git version in version string
AC_MSG_CHECKING(whether to use git version if available)
if test "x$wantgitver" = "xyes" ; then
	AC_CHECK_PROGS([GIT], [git])
	AC_CHECK_FILE([.git/], hasgitdir=yes)
	usegitver=$ac_cv_file__git_
	if test $GIT -a "x$hasgitdir" = "xyes"; then
		AC_DEFINE([USE_GIT_VERSION], [1], [Use GIT version in version string])
	fi
else
	AC_MSG_RESULT([no, disabled by configure])
	usegitver=no
fi
AM_CONDITIONAL(USE_GIT_VERSION, [test x$usegitver = xyes])

#check execv signature
if test "x$have_linux" == xtrue; then
    AC_COMPILE_IFELSE([AC_LANG_SOURCE([
           #include <unistd.h>
           int execv(const char*, char *const*);
           ])],
           AC_DEFINE([EXECV_2ND_ARG_TYPE], [char* const*], [int execv(const char*, char*const*);]),
           AC_DEFINE([EXECV_2ND_ARG_TYPE], [const char* const*], [int execv(const char*, const char*const*);]))
else
    AC_COMPILE_IFELSE([AC_LANG_SOURCE([
           #include <process.h>
           int execv(const char*, char *const*);
           ])],
           AC_DEFINE([EXECV_2ND_ARG_TYPE], [char* const*], [int execv(const char*, char*const*);]),
           AC_DEFINE([EXECV_2ND_ARG_TYPE], [const char* const*], [int execv(const char*, const char*const*);]))
fi

dnl CCAN wants to know a lot of vars.
# All the configuration checks.  Regrettably, the __attribute__ checks will
# give false positives on old GCCs, since they just cause warnings.  But that's
# fairly harmless.
AC_COMPILE_IFELSE([AC_LANG_SOURCE([static void __attribute__((cold)) cleanup(void) { }])],
			  AC_DEFINE([HAVE_ATTRIBUTE_COLD], [1],
                                    [Define if __attribute__((cold))]))
AC_COMPILE_IFELSE([AC_LANG_SOURCE([static void __attribute__((const)) cleanup(void) { }])],
			  AC_DEFINE([HAVE_ATTRIBUTE_CONST], [1],
                                    [Define if __attribute__((const))]))
AC_COMPILE_IFELSE([AC_LANG_SOURCE([static void __attribute__((noreturn)) cleanup(void) { exit(1); }])],
			  AC_DEFINE([HAVE_ATTRIBUTE_NORETURN], [1],
                                    [Define if __attribute__((noreturn))]))
AC_COMPILE_IFELSE([AC_LANG_SOURCE([static void __attribute__((format(__printf__, 1, 2))) cleanup(const char *fmt, ...) { }])],
			  AC_DEFINE([HAVE_ATTRIBUTE_PRINTF], [1],
                                    [Define if __attribute__((format(__printf__)))]))
AC_COMPILE_IFELSE([AC_LANG_SOURCE([static void __attribute__((unused)) cleanup(void) { }])],
			  AC_DEFINE([HAVE_ATTRIBUTE_UNUSED], [1],
                                    [Define if __attribute__((unused))]))
AC_COMPILE_IFELSE([AC_LANG_SOURCE([static void __attribute__((used)) cleanup(void) { }])],
			  AC_DEFINE([HAVE_ATTRIBUTE_USED], [1],
                                    [Define if __attribute__((used))]))
AC_LINK_IFELSE([AC_LANG_SOURCE([int main(void) { return __builtin_constant_p(1) ? 0 : 1; }])],
			  AC_DEFINE([HAVE_BUILTIN_CONSTANT_P], [1],
                                    [Define if have __builtin_constant_p]))
AC_LINK_IFELSE([AC_LANG_SOURCE([int main(void) { return __builtin_types_compatible_p(char *, int) ? 1 : 0; }])],
			  AC_DEFINE([HAVE_BUILTIN_TYPES_COMPATIBLE_P], [1],
                                    [Define if have __builtin_types_compatible_p]))
AC_COMPILE_IFELSE([AC_LANG_SOURCE([static int __attribute__((warn_unused_result)) func(int x) { return x; }])],
			  AC_DEFINE([HAVE_WARN_UNUSED_RESULT], [1],
                                    [Define if __attribute__((warn_unused_result))]))

if test "x$prefix" = xNONE; then
	prefix=/usr/local
fi

AC_DEFINE_UNQUOTED([SGMINER_PREFIX], ["$prefix/bin"], [Path to sgminer install])

AC_SUBST(OPENCL_LIBS)
AC_SUBST(OPENCL_FLAGS)
AC_SUBST(JANSSON_LIBS)
AC_SUBST(PTHREAD_FLAGS)
AC_SUBST(DLOPEN_FLAGS)
AC_SUBST(PTHREAD_LIBS)
AC_SUBST(NCURSES_LIBS)
AC_SUBST(PDCURSES_LIBS)
AC_SUBST(WS2_LIBS)
AC_SUBST(MM_LIBS)
AC_SUBST(MATH_LIBS)
AC_SUBST(RT_LIBS)
AC_SUBST(ADL_CPPFLAGS)

AC_CONFIG_FILES([
	Makefile
	submodules/Makefile
	ccan/Makefile
	lib/Makefile
	sph/Makefile
	])
AC_OUTPUT


echo
echo
echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE $VERSION"
echo "------------------------------------------------------------------------"
echo
echo
echo "Configuration Options Summary:"
echo

echo "  Use git version......: $usegitver"

if test "x$libcurl" != xno; then
	echo "  libcurl(GBT+getwork).: Enabled: $LIBCURL_LIBS"
else
	echo "  libcurl(GBT+getwork).: Disabled"
fi

echo "  curses.TUI...........: $cursesmsg"

if test $found_opencl = 1; then
	echo "  OpenCL...............: FOUND. GPU mining support enabled"
else
	echo "  OpenCL...............: NOT FOUND. GPU mining support DISABLED"
	AC_MSG_ERROR([OpenCL not found])
fi

if test "x$adl" != xno; then
	if test x$have_adl = xtrue; then
		if test "x$adl_checks" = xno; then
			echo "  ADL..................: SDK use FORCED"
		else
			echo "  ADL..................: SDK found, GPU monitoring support enabled"
		fi
	else
		echo "  ADL..................: SDK NOT found, GPU monitoring support DISABLED"
	fi
else
	echo "  ADL..................: Detection overrided. GPU monitoring support DISABLED"
fi

echo
echo "Compilation............: make (or gmake)"
echo "  CPPFLAGS.............: $CPPFLAGS"
echo "  CFLAGS...............: $CFLAGS"
echo "  LDFLAGS..............: $LDFLAGS $PTHREAD_FLAGS"
echo "  LDADD................: $DLOPEN_FLAGS $LIBCURL_LIBS $JANSSON_LIBS $PTHREAD_LIBS $OPENCL_LIBS $NCURSES_LIBS $PDCURSES_LIBS $WS2_LIBS $MATH_LIBS $RT_LIBS"
echo
echo "Installation...........: make install (as root if needed, with 'su' or 'sudo')"
echo "  prefix...............: $prefix"
echo
