#ifndef WINBUILD_H
#define WINBUILD_H

#if defined(_MSC_VER)

#include <stdint.h>
#include <ctype.h>
#include <stdio.h>
#include <windows.h>
#include <stdbool.h>
#include <mmsystem.h>
#include <io.h>
#include <unistd.h>
#include <process.h>
#include <math.h>
#include <time.h>
#include <WinSock2.h>

typedef intptr_t ssize_t;

#define snprintf _snprintf
#define strdup _strdup
#define execv _execv
#define access _access
#define fdopen _fdopen

#define inline __inline

struct timezone2 
{
	__int32  tz_minuteswest; /* minutes W of Greenwich */
	__int32  tz_dsttime;     /* type of dst correction */
};


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

#define __func__ __FUNCTION__
#define __attribute__(x)

#endif /* _MSC_VER */
#endif /* WINBUILD_H */
