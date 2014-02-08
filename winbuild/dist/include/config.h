#ifndef __CONFIG_H__
#define __CONFIG_H__

#define HAVE_STDINT_H

#define ALEXKARNEW_KERNNAME "alexkarnew"
#define ALEXKAROLD_KERNNAME "alexkarold"
#define CKOLIVAS_KERNNAME "ckolivas"
#define ZUIKKIS_KERNNAME "zuikkis"
#define PSW_KERNNAME "psw"

#if defined(_MSC_VER)


#define WIN32 1
#define STDC_HEADERS 1
#define EXECV_2ND_ARG_TYPE char* const*
#define GNULIB_TEST_MEMCHR 1
#define GNULIB_TEST_MEMMEM 1
#define GNULIB_TEST_SIGACTION 1
#define GNULIB_TEST_SIGPROCMASK 1

#define HAVE_LIBCURL 1
#define CURL_HAS_KEEPALIVE 1
#define HAVE_CURSES 1

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

#define _CRT_SECURE_NO_WARNINGS
#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#include <windows.h>
#include <stdbool.h>

#include <mmsystem.h>
#pragma comment(lib, "winmm.lib")

#define WANT_X8664_SSE4

#define USE_SCRYPT
#define HAVE_OPENCL
#define HAVE_ADL

#define PRIi64 "I64d"
#define PRIi32 "I32d"
#define PRIu32 "I32u"
#define PRIu64 "I64u"

#define PATH_MAX MAX_PATH

#define R_OK 0

#define snprintf _snprintf
#define strdup _strdup

#include <io.h>
#include <process.h>

#define va_copy(a, b) memcpy(&(a), &(b), sizeof(va_list))

//#define USE_AVX2 1

#define inline __inline

#include <stdint.h>
#include <ctype.h>
#include <stdio.h>

typedef intptr_t ssize_t;


struct timezone2 
{
	__int32  tz_minuteswest; /* minutes W of Greenwich */
	__int32  tz_dsttime;     /* type of dst correction */
};


#include <time.h>
#include <WinSock2.h>

const __int64 DELTA_EPOCH_IN_MICROSECS= 11644473600000000;

/* IN UNIX the use of the timezone struct is obsolete;
I don't know why you use it. See http://linux.about.com/od/commands/l/blcmdl2_gettime.htm
But if you want to use this structure to know about GMT(UTC) diffrence from your local time
it will be next: tz_minuteswest is the real diffrence in minutes from GMT(UTC) and a tz_dsttime is a flag
indicates whether daylight is now in use
*/

inline int gettimeofday(struct timeval *tv/*in*/, struct timezone2 *tz/*in*/)
{
	FILETIME ft;
	__int64 tmpres = 0;
	TIME_ZONE_INFORMATION tz_winapi;
	int rez=0;

	ZeroMemory(&ft,sizeof(ft));
	ZeroMemory(&tz_winapi,sizeof(tz_winapi));

	GetSystemTimeAsFileTime(&ft);

	tmpres = ft.dwHighDateTime;
	tmpres <<= 32;
	tmpres |= ft.dwLowDateTime;

	/*converting file time to unix epoch*/
	tmpres /= 10;  /*convert into microseconds*/
	tmpres -= DELTA_EPOCH_IN_MICROSECS; 
	tv->tv_sec = (__int32)(tmpres*0.000001);
	tv->tv_usec =(tmpres%1000000);

	if( tz )
	{
		//_tzset(),don't work properly, so we use GetTimeZoneInformation
		rez=GetTimeZoneInformation(&tz_winapi);
		tz->tz_dsttime=(rez==2)?true:false;
		tz->tz_minuteswest = tz_winapi.Bias + ((rez==2)?tz_winapi.DaylightBias:0);
	}

	return 0;
}

inline int strcasecmp(const char *s1, const char *s2)
{
	unsigned char c1,c2;
	do {
		c1 = *s1++;
		c2 = *s2++;
		c1 = (unsigned char) tolower( (unsigned char) c1);
		c2 = (unsigned char) tolower( (unsigned char) c2);
	}
	while((c1 == c2) && (c1 != '\0'));
	return (int) c1-c2;
}

inline int strncasecmp(const char *s1,	const char *s2, size_t n)
{
	if (n == 0)
		return 0;

	while (n-- != 0 && tolower(*s1) == tolower(*s2))
	{
		if (n == 0 || *s1 == '\0' || *s2 == '\0')
			break;
		s1++;
		s2++;
	}

	return tolower(*(unsigned char *) s1) - tolower(*(unsigned char *) s2);
}

#include <math.h>
inline long double roundl(long double r)
{
	return (r>0.0) ? floor(r+0.5f) : ceil(r-0.5);
}

#if (_MSC_VER < 1800)
#define round (int)roundl
inline long long int lround(double r) 
{
	return (r>0.0) ? floor(r+0.5f) : ceil(r-0.5);
}
#endif

inline void* memmem (void* buf, size_t buflen, void* pat, size_t patlen) 
{ 
	void* end = (char *) buf+buflen-patlen; 
	while (buf=memchr (buf, ((char *) pat) [0], buflen)) 
	{ 
		if (buf> end) 
			return 0; 
		if (memcmp (buf, pat, patlen) == 0) 
			return buf; 
		buf = (char *) buf+1; 
	}
	return 0; 
}

#define usleep(x) Sleep((x)/1000)
#define sleep(x) Sleep((x)*1000)

#endif

#define VERSION "v4.1.0"

#define PACKAGE_NAME "sgminer"
#define PACKAGE_TARNAME "sgminer"
#define PACKAGE_VERSION "4.1.0"
#define PACKAGE_STRING "sgminer 4.1.0"
#define PACKAGE "sgminer"
#define SGMINER_PREFIX ""


#if defined (WIN32)
#define __func__ __FUNCTION__
#define __attribute__(x)
#endif

// Libraries to include
#pragma comment(lib, "wsock32.lib")
#pragma comment(lib, "pthreadVC2.lib")
#pragma comment(lib, "OpenCL.lib")

#ifdef HAVE_LIBCURL
#define CURL_STATICLIB 1
#pragma comment(lib, "libcurl_a.lib")
#endif

#ifdef HAVE_CURSES
#pragma comment(lib, "pdcurses.lib")
#endif

#endif