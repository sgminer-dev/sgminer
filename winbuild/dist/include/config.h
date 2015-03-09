#ifndef __CONFIG_H__
#define __CONFIG_H__

#define HAVE_STDINT_H

#if defined(_MSC_VER)

#define HAVE_LIBCURL 1
#define CURL_HAS_KEEPALIVE 1
#define HAVE_CURSES 1
#define HAVE_ADL 1

#define STDC_HEADERS 1
#define EXECV_2ND_ARG_TYPE char* const*

#define HAVE_ALLOCA 1
#define HAVE_ATTRIBUTE_COLD 1
#define HAVE_ATTRIBUTE_CONST 1
#define HAVE_ATTRIBUTE_NORETURN 1
#define HAVE_ATTRIBUTE_PRINTF 1
#define HAVE_ATTRIBUTE_UNUSED 1
#define HAVE_ATTRIBUTE_USED 1
#define HAVE_BUILTIN_CONSTANT_P 1
#define HAVE_BUILTIN_TYPES_COMPATIBLE_P 1
#define HAVE_DECL_MEMMEM 0
#define HAVE_INTTYPES_H 1
#define HAVE_LONG_LONG_INT 1
#define HAVE_MEMORY_H 1
#define HAVE_MPROTECT 1
#define HAVE_RAW_DECL_MEMPCPY 1
#define HAVE_RAW_DECL_STRNCAT 1
#define HAVE_RAW_DECL_STRNLEN 1
#define HAVE_RAW_DECL_STRPBRK 1
#define HAVE_STDLIB_H 1
#define HAVE_STRINGS_H 1
#define HAVE_STRING_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_UNISTD_H 1
#define HAVE_UNSIGNED_LONG_LONG_INT 1
#define HAVE_WARN_UNUSED_RESULT 1
#define HAVE_WCHAR_H 1
#define HAVE_WCHAR_T 1

#define PRIi64 "I64d"
#define PRIi32 "I32d"
#define PRIu32 "I32u"
#define PRIu64 "I64u"

#define PATH_MAX MAX_PATH

// Libraries to include
#pragma comment(lib, "winmm.lib")
#pragma comment(lib, "wsock32.lib")
#pragma comment(lib, "pthreadVC2.lib")
#pragma comment(lib, "OpenCL.lib")
#pragma comment(lib, "jansson.lib")

#ifdef HAVE_LIBCURL
#define CURL_STATICLIB 1
#pragma comment(lib, "libcurl_a.lib")
#endif

#ifdef HAVE_CURSES
#pragma comment(lib, "pdcurses.lib")
#endif

#endif

#define VERSION "v5.1.1"
#define PACKAGE_NAME "sgminer"
#define PACKAGE_TARNAME "sgminer"
#define PACKAGE_VERSION "5.1.1"
#define PACKAGE_STRING "sgminer 5.1.1"
#define PACKAGE "sgminer"

#define SGMINER_PREFIX ""

#include "gitversion.h"
#include "winbuild.h"

#endif
