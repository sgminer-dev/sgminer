#ifndef COMPAT_H
#define COMPAT_H

#ifdef WIN32
#include "config.h"
#include <errno.h>
#include <fcntl.h>
#include <time.h>
#include <pthread.h>
#include <sys/time.h>

#include "miner.h"  // for timersub
#include "util.h"

#include <windows.h>


#if !defined S_ISDIR && defined S_IFDIR
# define S_ISDIR(mode) (((mode) & S_IFMT) == S_IFDIR)
#endif
#if !S_IRUSR && S_IREAD
# define S_IRUSR S_IREAD
#endif
#if !S_IRUSR
# define S_IRUSR 00400
#endif
#if !S_IWUSR && S_IWRITE
# define S_IWUSR S_IWRITE
#endif
#if !S_IWUSR
# define S_IWUSR 00200
#endif
#if !S_IXUSR && S_IEXEC
# define S_IXUSR S_IEXEC
#endif
#if !S_IXUSR
# define S_IXUSR 00100
#endif

#ifndef HAVE_LIBWINPTHREAD
static inline int nanosleep(const struct timespec *req, struct timespec *rem)
{
	struct timeval tstart;
	DWORD msecs;

	cgtime(&tstart);
	msecs = (req->tv_sec * 1000) + ((999999 + req->tv_nsec) / 1000000);

	if (SleepEx(msecs, true) == WAIT_IO_COMPLETION) {
		if (rem) {
			struct timeval tdone, tnow, tleft;
			tdone.tv_sec = tstart.tv_sec + req->tv_sec;
			tdone.tv_usec = tstart.tv_usec + ((999 + req->tv_nsec) / 1000);
			if (tdone.tv_usec > 1000000) {
				tdone.tv_usec -= 1000000;
				++tdone.tv_sec;
			}

			cgtime(&tnow);
			if (timercmp(&tnow, &tdone, >))
				return 0;
			timersub(&tdone, &tnow, &tleft);

			rem->tv_sec = tleft.tv_sec;
			rem->tv_nsec = tleft.tv_usec * 1000;
		}
		errno = EINTR;
		return -1;
	}
	return 0;
}
#endif

#if defined(__MINGW32__) && !defined(__MINGW64_VERSION_MAJOR)
// Reported unneded in https://github.com/veox/sgminer/issues/37 */
static inline int sleep(unsigned int secs)
{
	struct timespec req, rem;
	req.tv_sec = secs;
	req.tv_nsec = 0;
	if (!nanosleep(&req, &rem))
		return 0;
	return rem.tv_sec + (rem.tv_nsec ? 1 : 0);
}
#endif

enum {
	PRIO_PROCESS		= 0,
};

static inline int setpriority(__maybe_unused int which, __maybe_unused int who, __maybe_unused int prio)
{
	/* FIXME - actually do something */
	return 0;
}

#ifndef HAVE_STRSEP
static inline char *strsep(char **stringp, const char *delim)
{
  char *res;

  if (!stringp || !*stringp || !**stringp) {
    return NULL;
  }

  res = *stringp;
  while(**stringp && !strchr(delim, **stringp)) {
    ++(*stringp);
  }

  if (**stringp) {
    **stringp = '\0';
    ++(*stringp);
  }

  return res;
}
#endif


typedef unsigned long int ulong;
typedef unsigned short int ushort;
typedef unsigned int uint;

#ifndef __SUSECONDS_T_TYPE
typedef long suseconds_t;
#endif

#ifdef HAVE_LIBWINPTHREAD
#define PTH(thr) ((thr)->pth)
#else
#define PTH(thr) ((thr)->pth.p)
#endif

#else
#define PTH(thr) ((thr)->pth)
#endif /* WIN32 */

#endif /* COMPAT_H */
