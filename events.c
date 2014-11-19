/*
 * Copyright 2013-2014 sgminer developers (see AUTHORS.md)
 * Copyright 2011-2013 Con Kolivas
 * Copyright 2011-2012 Luke Dashjr
 * Copyright 2010 Jeff Garzik
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 3 of the License, or (at your option)
 * any later version.  See COPYING for more details.
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/time.h>
#include <time.h>
#include <math.h>
#include <stdarg.h>
#include <assert.h>
#include <signal.h>
#include <limits.h>

#include <sys/stat.h>
#include <sys/types.h>

#include "compat.h"
#include "miner.h"
#include "events.h"
#include "config_parser.h"

// global event list
event_t *events = NULL, *last_event = NULL;

/***************************************************
 * Helper functions
 **************************************************/
static void *cmd_thread(void *cmdp)
{
	const char *cmd = (const char*)cmdp;

	applog(LOG_DEBUG, "Executing command: %s", cmd);
	system(cmd);

	return NULL;
}

static void runcmd(const char *cmd)
{
	if (empty_string(cmd))
		return;

	pthread_t pth;
	pthread_create(&pth, NULL, cmd_thread, (void*)cmd);
}

/****************************************************
* Event list functions
****************************************************/
//find an event by event_type
static event_t *get_event(const char *event_type)
{
  event_t *p = events;

  while (p != NULL)
  {
    if(!strcasecmp(p->event_type, event_type))
      return p;

    p = p->next;
  }

  return NULL;
}

// add event to the list
static event_t *add_event(unsigned int id)
{
  event_t *event;

  // allocate memory
  if (!(event = (event_t *)malloc(sizeof(event_t))))
    quit(1, "malloc() failed in add_event()");

  // set defaults
  event->id = id;
  event->event_type = "";
  event->runcmd = "";
  event->reboot = false;
  event->reboot_delay = 0;
  event->quit = false;
  event->quit_msg = "";
  event->prev = event->next = NULL;

  // first event?
  if(events == NULL)
  {
    events = event;
    last_event = event;
  }
  // no, append to the list
  else
  {
    last_event->next = event;
    event->prev = last_event;
    last_event = event;
  }

  return event;
}

// remove event from the list
static void remove_event(event_t *event)
{
  // only event?
  if(event == events && event == last_event)
    events = last_event = NULL;
  // first event?
  else if(event == events)
  {
    event->next->prev = NULL;
    events = event->next;
  }
  // last event?
  else if(event == last_event)
  {
    event->prev->next = NULL;
    last_event = event->prev;
  }
  // in the middle
  else
  {
    event->prev->next = event->next;
    event->next->prev = event->prev;
  }

  // free memory
  free(event);
}

#ifndef EVENT_ADD_CHECK
  #define EVENT_ADD_CHECK if (!last_event || (last_event->id != json_array_index)) add_event(json_array_index);
#endif

/********************************************
* Config functions
*********************************************/
char *set_event_type(const char *event_type)
{
  event_t *event;

  // make sure event type doesn't already exist
  if ((event = get_event(event_type)) != NULL)
    return NULL;

  EVENT_ADD_CHECK;

  last_event->event_type = event_type;

  return NULL;
}

char *set_event_runcmd(const char *cmd)
{
  EVENT_ADD_CHECK;

  last_event->runcmd = cmd;

  return NULL;
}

char *set_event_reboot(const char *arg)
{
  EVENT_ADD_CHECK;

  if (empty_string(arg))
    return NULL;

  last_event->reboot = strtobool(arg);

  applog(LOG_NOTICE, "Event %s reboot = %s", last_event->event_type, ((last_event->reboot)?"true":"false"));

  return NULL;
}

char *set_event_reboot_delay(const char *delay)
{
  EVENT_ADD_CHECK;

  last_event->reboot_delay = atoi(delay);

  // if the reboot delay is greater than 0 seconds, automatically turn on reboot
  if (last_event->reboot_delay > 0)
    last_event->reboot = true;

  return NULL;
}

char *set_event_quit(const char *arg)
{
  EVENT_ADD_CHECK;

  if (empty_string(arg))
    return NULL;

  last_event->quit = strtobool(arg);

  applog(LOG_DEBUG, "Event %s quit = %s", last_event->event_type, ((last_event->quit)?"true":"false"));

  return NULL;
}

char *set_event_quit_message(const char *msg)
{
  EVENT_ADD_CHECK;

  last_event->quit_msg = msg;

  // if the quit message is set, automatically turn on quit
  if (!empty_string(last_event->quit_msg))
    last_event->quit = true;

  return NULL;
}

/******************************************
* Event functions
*******************************************/
void event_notify(const char *event_type)
{
  event_t *event;

  // find an event of the specified type
  if ((event = get_event(event_type)) == NULL)
    return;

  applog(LOG_DEBUG, "Executing event %s", event_type);

  // run command if defined
  if (!empty_string(event->runcmd))
    runcmd(event->runcmd);

  // reboot if set
  if (event->reboot == true)
  {
    //wait specified amount of time
    if (event->reboot_delay > 0)
    {
      applog(LOG_NOTICE, "waiting %d to reboot", event->reboot_delay);
      sleep(event->reboot_delay);
    }

    #ifdef WIN32
      runcmd("shutdown /r /t 0");
    #else
      applog(LOG_NOTICE, "running shutdown -r now");
      runcmd("/sbin/shutdown -r now");
    #endif
  }

  // quit sgminer if set
  if (event->quit == true)
    quit(0, ((empty_string(event->quit_msg))?event_type:event->quit_msg));

}