/*
 * Copyright 2011-2012 Con Kolivas
 * Copyright 2013 Andrew Smith
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 3 of the License, or (at your option)
 * any later version.  See COPYING for more details.
 */

#include "config.h"

#include <unistd.h>

#include "logging.h"
#include "miner.h"

bool opt_debug = false;
bool opt_debug_console = false;
bool opt_verbose = false;
int last_date_output_day = 0;
int opt_log_show_date = false;

/* per default priorities higher than LOG_NOTICE are logged */
int opt_log_level = LOG_NOTICE;

static void _my_log_curses(int prio, const char *datetime, const char *str)
{
	if (opt_quiet && prio != LOG_ERR)
		return;

#ifdef HAVE_CURSES
	extern bool use_curses;
	if (use_curses && _log_curses_only(prio, datetime, str))
		;
	else
#endif
		printf("%s%s%s", datetime, str, "                    \n");
}

void applog(int prio, const char* fmt, ...)
{
  va_list args;

  va_start(args, fmt);
  vapplogsiz(prio, LOGBUFSIZ, fmt, args);
  va_end(args);
}

void applogsiz(int prio, int size, const char* fmt, ...)
{
  va_list args;

  va_start(args, fmt);
  vapplogsiz(prio, size, fmt, args);
  va_end(args);
}

/* high-level logging function, based on global opt_log_level */
void vapplogsiz(int prio, int size, const char* fmt, va_list args)
{
  if ((opt_debug || prio != LOG_DEBUG)) {
    char *tmp42 = (char *)calloc(size + 1, 1);
    vsnprintf(tmp42, size, fmt, args);
    _applog(prio, tmp42, false);
    free(tmp42);
  }
#ifdef DEV_DEBUG_MODE
  else if(prio == LOG_DEBUG) {
    char *tmp42 = (char *)calloc(size + 1, 1);
    vsnprintf(tmp42, size, fmt, args);
    __debug("", tmp42);
    free(tmp42);
  }
#endif
}

/*
 * log function
 */
void _applog(int prio, const char *str, bool force)
{
#ifdef HAVE_SYSLOG_H
  if (use_syslog) {
    syslog(prio, "%s", str);
  }
#else
  if (0) {}
#endif
  else {

#ifdef DEV_DEBUG_MODE
    if(prio == LOG_DEBUG) {
      __debug("", str);
    }
#endif

    bool write_console = opt_debug_console || (opt_verbose && prio != LOG_DEBUG) || prio <= opt_log_level;
    bool write_stderr = !isatty(fileno((FILE *)stderr));
    if (!(write_console || write_stderr))
      return;

    char datetime[64];
    struct timeval tv = {0, 0};
    struct tm *tm;

    cgtime(&tv);

    const time_t tmp_time = tv.tv_sec;
    tm = localtime(&tmp_time);

    /* Day changed. */
    if (opt_log_show_date && (last_date_output_day != tm->tm_mday)) {
      last_date_output_day = tm->tm_mday;
      char date_output_str[64];
      snprintf(date_output_str, sizeof(date_output_str), "Log date is now %d-%02d-%02d",
        tm->tm_year + 1900,
        tm->tm_mon + 1,
        tm->tm_mday);
      _applog(prio, date_output_str, force);
    }

    if (opt_log_show_date) {
      snprintf(datetime, sizeof(datetime), "[%d-%02d-%02d %02d:%02d:%02d] ",
        tm->tm_year + 1900,
        tm->tm_mon + 1,
        tm->tm_mday,
        tm->tm_hour,
        tm->tm_min,
        tm->tm_sec);
    }
    else {
      snprintf(datetime, sizeof(datetime), "[%02d:%02d:%02d] ",
        tm->tm_hour,
        tm->tm_min,
        tm->tm_sec);
    }

    if (write_console || write_stderr) {
      /* Mutex could be locked by dead thread on shutdown so forcelog will
       * invalidate any console lock status. */
      if (force) {
        mutex_trylock(&console_lock);
        mutex_unlock(&console_lock);
      }

      mutex_lock(&console_lock);
      /* Only output to stderr if it's not going to the screen as well */
      if (write_stderr) {
        fprintf(stderr, "%s%s\n", datetime, str); /* atomic write to stderr */
        fflush(stderr);
      }

      if (write_console) {
        _my_log_curses(prio, datetime, str);
      }
      mutex_unlock(&console_lock);
    }
  }
}

void __debug(const char *filename, const char *fmt, ...)
{
  FILE *f;
  va_list args;

  if (!(f = fopen(((!empty_string(filename))?filename:"debug.log"), "a+"))) {
    return;
  }

  //prepend timestamp
  struct timeval tv = {0, 0};
  struct tm *tm;

  cgtime(&tv);

  const time_t tmp_time = tv.tv_sec;
  tm = localtime(&tmp_time);

  fprintf(f, "[%d-%02d-%02d %02d:%02d:%02d] ",
    tm->tm_year + 1900,
    tm->tm_mon + 1,
    tm->tm_mday,
    tm->tm_hour,
    tm->tm_min,
    tm->tm_sec);

  va_start(args, fmt);
  vfprintf(f, fmt, args);
  va_end(args);

  //add \n
  fprintf(f, "\n");

  fclose(f);
}