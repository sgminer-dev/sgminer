#ifndef LOGGING_H
#define LOGGING_H

#include "config.h"
#include <stdbool.h>
#include <stdarg.h>

#ifdef HAVE_SYSLOG_H
#include <syslog.h>
#else
enum {
  LOG_ERR,
  LOG_WARNING,
  LOG_NOTICE,
  LOG_INFO,
  LOG_DEBUG,
};
#endif

/* debug flags */
extern bool opt_debug;
extern bool opt_debug_console;
extern bool opt_verbose;
extern bool opt_realquiet;
extern bool want_per_device_stats;

/* global log_level, messages with lower or equal prio are logged */
extern int opt_log_level;

extern int opt_log_show_date;

#define LOGBUFSIZ 512

void applog(int prio, const char* fmt, ...);
void applogsiz(int prio, int size, const char* fmt, ...);
void vapplogsiz(int prio, int size, const char* fmt, va_list args);

extern void _applog(int prio, const char *str, bool force);

#define IN_FMT_FFL " in %s %s():%d"

#define forcelog(prio, fmt, ...) do { \
  if (opt_debug || prio != LOG_DEBUG) { \
    char tmp42[LOGBUFSIZ]; \
    snprintf(tmp42, sizeof(tmp42), fmt, ##__VA_ARGS__); \
    _applog(prio, tmp42, true); \
  } \
} while (0)

#define quit(status, fmt, ...) do { \
  if (fmt) { \
    char tmp42[LOGBUFSIZ]; \
    snprintf(tmp42, sizeof(tmp42), fmt, ##__VA_ARGS__); \
    _applog(LOG_ERR, tmp42, true); \
  } \
  _quit(status); \
} while (0)

#define quithere(status, fmt, ...) do { \
  if (fmt) { \
    char tmp42[LOGBUFSIZ]; \
    snprintf(tmp42, sizeof(tmp42), fmt IN_FMT_FFL, \
      ##__VA_ARGS__, __FILE__, __func__, __LINE__); \
    _applog(LOG_ERR, tmp42, true); \
  } \
  _quit(status); \
} while (0)

#define quitfrom(status, _file, _func, _line, fmt, ...) do { \
  if (fmt) { \
    char tmp42[LOGBUFSIZ]; \
    snprintf(tmp42, sizeof(tmp42), fmt IN_FMT_FFL, \
      ##__VA_ARGS__, _file, _func, _line); \
    _applog(LOG_ERR, tmp42, true); \
  } \
  _quit(status); \
} while (0)

#ifdef HAVE_CURSES

#define wlog(fmt, ...) do { \
  char tmp42[LOGBUFSIZ]; \
  snprintf(tmp42, sizeof(tmp42), fmt, ##__VA_ARGS__); \
  _wlog(tmp42); \
} while (0)

#define wlogprint(fmt, ...) do { \
  char tmp42[LOGBUFSIZ]; \
  snprintf(tmp42, sizeof(tmp42), fmt, ##__VA_ARGS__); \
  _wlogprint(tmp42); \
} while (0)

#endif

extern void __debug(const char *filename, const char *fmt, ...);


#endif /* LOGGING_H */
