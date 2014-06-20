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
#include <ccan/opt/opt.h>
#include <jansson.h>
#include <libgen.h>
#include <sha2.h>

#include "compat.h"
#include "miner.h"
#include "config_parser.h"
#include "driver-opencl.h"
#include "bench_block.h"

#include "algorithm.h"
#include "pool.h"

#ifdef HAVE_ADL
#include "adl.h"
#endif

#if defined(unix) || defined(__APPLE__)
  #include <errno.h>
  #include <fcntl.h>
  #include <sys/wait.h>
#endif

char *cnfbuf = NULL;  //config file loaded
int fileconf_load;   //config file load status
const char def_conf[] = "sgminer.conf";
char *default_config;
bool config_loaded;
//static int include_count;

int json_array_index = -1;  //current array index being parsed
char *last_json_error = NULL;  //last json_error
/*#define JSON_MAX_DEPTH 10
#define JSON_MAX_DEPTH_ERR "Too many levels of JSON includes (limit 10) or a loop"*/

/*******************************************
 * Profile list functions
 *******************************************/
struct profile default_profile;
struct profile **profiles;
int total_profiles;

static struct profile *add_profile()
{
  struct profile *profile;
  char buf[32];

  if(!(profile = (struct profile *)calloc(sizeof(struct profile), 1)))
    quit(1, "Failed to calloc profile in add_profile");
  profile->profile_no = total_profiles;

  //default profile name is the profile index
  sprintf(buf, "%d", profile->profile_no);
  profile->name = strdup(buf);

  profiles = (struct profile **)realloc(profiles, sizeof(struct profile *) * (total_profiles + 2));
  profiles[total_profiles++] = profile;

  return profile;
}

//only used while loading config
static struct profile *get_current_profile()
{
  while ((json_array_index + 1) > total_profiles)
    add_profile();

  if (json_array_index < 0)
  {
    if (!total_profiles)
      add_profile();
    return profiles[total_profiles - 1];
  }

  return profiles[json_array_index];
}

//find a profile by name
static struct profile *get_profile(char *name)
{
  int i;

  for(i=total_profiles;i--;)
  {
    if(!strcasecmp(profiles[i]->name, name))
      return profiles[i];
  }

  return NULL;
}

/******* Default profile functions used during config parsing *****/
char *set_default_devices(const char *arg)
{
  default_profile.devices = arg;
  return NULL;
}

char *set_default_lookup_gap(const char *arg)
{
  default_profile.lookup_gap = arg;
  return NULL;
}

char *set_default_intensity(const char *arg)
{
  default_profile.intensity = arg;
  return NULL;
}

char *set_default_xintensity(const char *arg)
{
  default_profile.xintensity = arg;
  return NULL;
}

char *set_default_rawintensity(const char *arg)
{
  default_profile.rawintensity = arg;
  return NULL;
}

char *set_default_thread_concurrency(const char *arg)
{
  default_profile.thread_concurrency = arg;
  return NULL;
}

#ifdef HAVE_ADL

  char *set_default_gpu_engine(const char *arg)
  {
    default_profile.gpu_engine = arg;
    return NULL;
  }

  char *set_default_gpu_memclock(const char *arg)
  {
    default_profile.gpu_memclock = arg;
    return NULL;
  }

  char *set_default_gpu_threads(const char *arg)
  {
    default_profile.gpu_threads = arg;
    return NULL;
  }

  char *set_default_gpu_fan(const char *arg)
  {
    default_profile.gpu_fan = arg;
    return NULL;
  }

  char *set_default_gpu_powertune(const char *arg)
  {
    default_profile.gpu_powertune = arg;
    return NULL;
  }

  char *set_default_gpu_vddc(const char *arg)
  {
    default_profile.gpu_vddc = arg;
    return NULL;
  }

#endif

char *set_default_profile(char *arg)
{
  default_profile.name = arg;
  return NULL;
}

char *set_default_shaders(const char *arg)
{
  default_profile.shaders = arg;
  return NULL;
}

char *set_default_worksize(const char *arg)
{
  default_profile.worksize = arg;
  return NULL;
}

/****** Profile functions used in during config parsing ********/
char *set_profile_name(const char *arg)
{
  struct profile *profile = get_current_profile();

  applog(LOG_DEBUG, "Setting profile %i name to %s", profile->profile_no, arg);
  opt_set_charp(arg, &profile->name);

  return NULL;
}

char *set_profile_algorithm(const char *arg)
{
  struct profile *profile = get_current_profile();

  //applog(LOG_DEBUG, "Setting profile %s algorithm to %s", profile->name, arg);
  set_algorithm(&profile->algorithm, arg);

  return NULL;
}

char *set_profile_devices(const char *arg)
{
  struct profile *profile = get_current_profile();
  profile->devices = arg;
  return NULL;
}

char *set_profile_lookup_gap(const char *arg)
{
  struct profile *profile = get_current_profile();
  profile->lookup_gap = arg;
  return NULL;
}

char *set_profile_intensity(const char *arg)
{
  struct profile *profile = get_current_profile();
  profile->intensity = arg;
  return NULL;
}

char *set_profile_xintensity(const char *arg)
{
  struct profile *profile = get_current_profile();
  profile->xintensity = arg;
  return NULL;
}

char *set_profile_rawintensity(const char *arg)
{
  struct profile *profile = get_current_profile();
  profile->rawintensity = arg;
  return NULL;
}

char *set_profile_thread_concurrency(const char *arg)
{
  struct profile *profile = get_current_profile();
  profile->thread_concurrency = arg;
  return NULL;
}

#ifdef HAVE_ADL

  char *set_profile_gpu_engine(const char *arg)
  {
    struct profile *profile = get_current_profile();
    profile->gpu_engine = arg;
    return NULL;
  }

  char *set_profile_gpu_memclock(const char *arg)
  {
    struct profile *profile = get_current_profile();
    profile->gpu_memclock = arg;
    return NULL;
  }

  char *set_profile_gpu_threads(const char *arg)
  {
    struct profile *profile = get_current_profile();
    profile->gpu_threads = arg;
    return NULL;
  }

  char *set_profile_gpu_fan(const char *arg)
  {
    struct profile *profile = get_current_profile();
    profile->gpu_fan = arg;
    return NULL;
  }

  char *set_profile_gpu_powertune(const char *arg)
  {
    struct profile *profile = get_current_profile();
    profile->gpu_powertune = arg;
    return NULL;
  }

  char *set_profile_gpu_vddc(const char *arg)
  {
    struct profile *profile = get_current_profile();
    profile->gpu_vddc = arg;
    return NULL;
  }

#endif

char *set_profile_nfactor(const char *arg)
{
  struct profile *profile = get_current_profile();

  applog(LOG_DEBUG, "Setting profile %s N-factor to %s", profile->name, arg);
  set_algorithm_nfactor(&profile->algorithm, (const uint8_t) atoi(arg));

  return NULL;
}

char *set_profile_shaders(const char *arg)
{
  struct profile *profile = get_current_profile();
  profile->shaders = arg;
  return NULL;
}

char *set_profile_worksize(const char *arg)
{
  struct profile *profile = get_current_profile();
  profile->worksize = arg;
  return NULL;
}

/***************************************
* Helper Functions
****************************************/
json_t *json_sprintf(const char *fmt, ...)
{
  va_list args;
  char *buf;
  size_t bufsize;
  
  //build args
  va_start(args, fmt);
  //get final string buffer size
  bufsize = vsnprintf(NULL, 0, fmt, args);
  va_end(args);
  
  if(!(buf = (char *)malloc(++bufsize)))
    quit(1, "Malloc failure in config_parser::json_sprintf().");

  //zero out buffer
  memset(buf, '\0', bufsize);

  //get args again
  va_start(args, fmt);
  vsnprintf(buf, bufsize, fmt, args);
  va_end(args);

  //return json string
  return json_string(buf);
}

//set last json error
char *set_last_json_error(const char *fmt, ...)
{
  va_list args;
  size_t bufsize;

  //build args
  va_start(args, fmt);
  //get final string buffer size
  bufsize = vsnprintf(NULL, 0, fmt, args);
  va_end(args);

  //if NULL allocate memory... otherwise reallocate
  if(!last_json_error)
  {
    if(!(last_json_error = (char *)malloc(++bufsize)))
      quit(1, "Malloc failure in config_parser::set_last_json_error().");
  }
  else
  {
    if(!(last_json_error = (char *)realloc(last_json_error, ++bufsize)))
      quit(1, "Realloc failure in config_parser::set_last_json_error().");
  }

  //zero out buffer
  memset(last_json_error, '\0', bufsize);

  //get args again
  va_start(args, fmt);
  vsnprintf(last_json_error, bufsize, fmt, args);
  va_end(args);
  
  return last_json_error;
}

//find opt by name in an opt table
static struct opt_table *opt_find(struct opt_table *tbl, char *optname)
{
  struct opt_table *opt;
  char *p, *name;

  for(opt = tbl;opt->type != OPT_END;opt++)
  {
    /* We don't handle subtables. */
    assert(!(opt->type & OPT_SUBTABLE));

    if(!opt->names)
      continue;

    /* Pull apart the option name(s). */
    name = strdup(opt->names);
    for(p = strtok(name, "|");p;p = strtok(NULL, "|"))
    {
      /* Ignore short options. */
      if(p[1] != '-')
        continue;

      //if this is the opt we're looking for, return it...
      if(!strcasecmp(optname, p))
      {
        free(name);
        return opt;
      }
    }
    free(name);
  }

  return NULL;
}


/***************************************
* Config Parsing Functions
****************************************/
//Handle parsing JSON objects
void parse_config_object(json_t *obj, const char *parentkey, bool fileconf, int parent_iteration)
{
  //char *err = NULL;
  const char *key;
  json_t *val;

  json_object_foreach(obj, key, val)
  {
    //process include
    if(!strcasecmp(key, "include"))
    {
      if(val && json_is_string(val))
        load_config(json_string_value(val), parentkey, NULL);
    }
    else
      parse_config(val, key, parentkey, fileconf, parent_iteration);
    /*
    {
      if((err = parse_config(val, key, parentkey, fileconf, parent_iteration)))
        return err;
    }*/
  }
}

//Handle parsing JSON arrays
static char *parse_config_array(json_t *obj, char *parentkey, bool fileconf)
{
  char *err = NULL;
  size_t idx;
  json_t *val;

  //fix parent key - remove extra "s" to match opt names (e.g. --pool-gpu-memclock not --pools-gpu-memclock)
  if(!strcasecmp(parentkey, "pools") || !strcasecmp(parentkey, "profiles"))
    parentkey[(strlen(parentkey) - 1)] = '\0';

  json_array_foreach(obj, idx, val)
  {
    //abort on error
    if((err = parse_config(val, "", parentkey, fileconf, idx)))
      return err;
  }

  return NULL;
}

//Parse JSON values from config file
char *parse_config(json_t *val, const char *key, const char *parentkey, bool fileconf, int parent_iteration)
{
  static char err_buf[200];
  char *err = NULL;
  struct opt_table *opt;
  char optname[255];
  /*const char *key
  json_t *val;*/

  json_array_index = parent_iteration;

  if (fileconf && !fileconf_load)
    fileconf_load = 1;

  /*
  parse the json config items into opts instead of looking for opts in the json config...
  This adds greater flexibility with config files.
  */
  switch(json_typeof(val))
  {
    //json value is an object
    case JSON_OBJECT:
      parse_config_object(val, parentkey, false, parent_iteration);
      break;

    //json value is an array
    case JSON_ARRAY:
      err = parse_config_array(val, (char *)key, fileconf);
      break;

    //other json types process here
    default:
      //convert json key to opt name
      sprintf(optname, "--%s%s%s", ((!empty_string(parentkey))?parentkey:""), ((!empty_string(parentkey))?"-":""), key);

      //look up opt name in config table
      if((opt = opt_find(opt_config_table, optname)) != NULL)
      {
        //strings
        if ((opt->type & OPT_HASARG) && json_is_string(val))
          err = opt->cb_arg(json_string_value(val), opt->u.arg);
        //boolean values
        else if ((opt->type & OPT_NOARG) && json_is_true(val))
          err = opt->cb(opt->u.arg);
        else
          err = "Invalid value";
      }
      else
        err = "Invalid option";

      break;
  }

  //error processing JSON...
  if(err)
  {
    /* Allow invalid values to be in configuration
     * file, just skipping over them provided the
     * JSON is still valid after that. */
    if(fileconf)
    {
      applog(LOG_WARNING, "Skipping config option %s: %s", optname+2, err);
      fileconf_load = -1;
    }
    else
    {
      snprintf(err_buf, sizeof(err_buf), "Error parsing JSON option %s: %s", optname+2, err);
      return err_buf;
    }
  }

  return NULL;
}

char *load_config(const char *arg, const char *parentkey, void __maybe_unused *unused)
{
  json_error_t err;
  json_t *config;

  //most likely useless but leaving it here for now...
  if(!cnfbuf)
    cnfbuf = strdup(arg);

  //no need to restrict the number of includes... if it causes problems, restore it later
  /*if(++include_count > JSON_MAX_DEPTH)
    return JSON_MAX_DEPTH_ERR;
  */

#if JANSSON_MAJOR_VERSION > 1
  config = json_load_file(arg, 0, &err);
#else
  config = json_load_file(arg, &err);
#endif

  //if json root is not an object, error out
  if(!json_is_object(config))
    return set_last_json_error("Error: JSON decode of file \"%s\" failed:\n %s", arg, err.text);

  config_loaded = true;

  /* Parse the config now, so we can override it.  That can keep pointers
  * so don't free config object. */
  return parse_config(config, "", parentkey, true, -1);
}

char *set_default_config(const char *arg)
{
  opt_set_charp(arg, &default_config);
  return NULL;
}

void load_default_config(void)
{
  cnfbuf = (char *)malloc(PATH_MAX);

  default_save_file(cnfbuf);

  if (!access(cnfbuf, R_OK))
  load_config(cnfbuf, "", NULL);
  else {
  free(cnfbuf);
  cnfbuf = NULL;
  }
}

/*******************************************
 * Startup functions
 * *****************************************/

//assign default settings from default profile if set
void load_default_profile()
{
  struct profile *profile;

  //if a default profile name is set
  if(!empty_string(default_profile.name))
  {
    //find profile and copy settings
    if((profile = get_profile(default_profile.name)))
    {
      default_profile.algorithm = profile->algorithm;
      default_profile.devices = profile->devices;
      default_profile.lookup_gap = profile->lookup_gap;
      default_profile.intensity = profile->intensity;
      default_profile.xintensity = profile->xintensity;
      default_profile.rawintensity = profile->rawintensity;
      default_profile.thread_concurrency = profile->thread_concurrency;
#ifdef HAVE_ADL
      default_profile.gpu_engine = profile->gpu_engine;
      default_profile.gpu_memclock = profile->gpu_memclock;
      default_profile.gpu_threads = profile->gpu_threads;
      default_profile.gpu_fan = profile->gpu_fan;
      default_profile.gpu_powertune = profile->gpu_powertune;
      default_profile.gpu_vddc = profile->gpu_vddc;
#endif
      default_profile.shaders = profile->shaders;
      default_profile.worksize = profile->worksize;
    }
  }
}

//apply default settings
void apply_defaults()
{
  set_algorithm(opt_algorithm, default_profile.algorithm.name);

  if(!empty_string(default_profile.devices))
    set_devices((char *)default_profile.devices);

  if(!empty_string(default_profile.intensity))
    set_intensity(default_profile.intensity);

  if(!empty_string(default_profile.xintensity))
    set_xintensity(default_profile.xintensity);

  if(!empty_string(default_profile.rawintensity))
    set_rawintensity(default_profile.rawintensity);

  if(!empty_string(default_profile.lookup_gap))
    set_lookup_gap((char *)default_profile.lookup_gap);

  if(!empty_string(default_profile.thread_concurrency))
    set_thread_concurrency(default_profile.thread_concurrency);

#ifdef HAVE_ADL
  if(!empty_string(default_profile.gpu_engine))
    set_gpu_engine(default_profile.gpu_engine);

  if(!empty_string(default_profile.gpu_memclock))
    set_gpu_memclock(default_profile.gpu_memclock);

  if(!empty_string(default_profile.gpu_threads))
    set_gpu_threads(default_profile.gpu_threads);

  if(!empty_string(default_profile.gpu_fan))
    set_gpu_fan(default_profile.gpu_fan);

  if(!empty_string(default_profile.gpu_powertune))
    set_gpu_powertune((char *)default_profile.gpu_powertune);

  if(!empty_string(default_profile.gpu_vddc))
    set_gpu_vddc((char *)default_profile.gpu_vddc);
#endif

  if(!empty_string(default_profile.shaders))
    set_shaders((char *)default_profile.shaders);

  if(!empty_string(default_profile.worksize))
    set_worksize((char *)default_profile.worksize);
}

//apply profile settings to pools
void apply_pool_profiles()
{
  int i;

  for(i=total_pools;i--;)
  {
    apply_pool_profile(pools[i]);
  }
}

void apply_pool_profile(struct pool *pool)
{
  struct profile *profile;
  
  //if the pool has a profile set
  if(!empty_string(pool->profile))
  {
    applog(LOG_DEBUG, "Loading settings from profile \"%s\" for pool %i", pool->profile, pool->pool_no);

    //find profile and apply settings to the pool
    if((profile = get_profile(pool->profile)))
    {
      pool->algorithm = profile->algorithm;
      applog(LOG_DEBUG, "Pool %i Algorithm set to \"%s\"", pool->pool_no, pool->algorithm.name);

      if(!empty_string(profile->devices))
      {
        pool->devices = profile->devices;
        applog(LOG_DEBUG, "Pool %i devices set to \"%s\"", pool->pool_no, pool->devices);
      }

      if(!empty_string(profile->lookup_gap))
      {
        pool->lookup_gap = profile->lookup_gap;
        applog(LOG_DEBUG, "Pool %i lookup gap set to \"%s\"", pool->pool_no, pool->lookup_gap);
      }

      if(!empty_string(profile->intensity))
      {
        pool->intensity = profile->intensity;
        applog(LOG_DEBUG, "Pool %i Intensity set to \"%s\"", pool->pool_no, pool->intensity);
      }

      if(!empty_string(profile->xintensity))
      {
        pool->xintensity = profile->xintensity;
        applog(LOG_DEBUG, "Pool %i XIntensity set to \"%s\"", pool->pool_no, pool->xintensity);
      }

      if(!empty_string(profile->rawintensity))
      {
        pool->rawintensity = profile->rawintensity;
        applog(LOG_DEBUG, "Pool %i Raw Intensity set to \"%s\"", pool->pool_no, pool->rawintensity);
      }

      if(!empty_string(profile->thread_concurrency))
      {
        pool->thread_concurrency = profile->thread_concurrency;
        applog(LOG_DEBUG, "Pool %i Thread Concurrency set to \"%s\"", pool->pool_no, pool->thread_concurrency);
      }

#ifdef HAVE_ADL
      if(!empty_string(profile->gpu_engine))
      {
        pool->gpu_engine = profile->gpu_engine;
        applog(LOG_DEBUG, "Pool %i GPU Clock set to \"%s\"", pool->pool_no, pool->gpu_engine);
      }

      if(!empty_string(profile->gpu_memclock))
      {
        pool->gpu_memclock = profile->gpu_memclock;
        applog(LOG_DEBUG, "Pool %i GPU Memory clock set to \"%s\"", pool->pool_no, pool->gpu_memclock);
      }

      if(!empty_string(profile->gpu_threads))
      {
        pool->gpu_threads = profile->gpu_threads;
        applog(LOG_DEBUG, "Pool %i GPU Threads set to \"%s\"", pool->pool_no, pool->gpu_threads);
      }

      if(!empty_string(profile->gpu_fan))
      {
        pool->gpu_fan = profile->gpu_fan;
        applog(LOG_DEBUG, "Pool %i GPU Fan set to \"%s\"", pool->pool_no, pool->gpu_fan);
      }

      if(!empty_string(profile->gpu_powertune))
      {
        pool->gpu_powertune = profile->gpu_powertune;
        applog(LOG_DEBUG, "Pool %i GPU Powertune set to \"%s\"", pool->pool_no, pool->gpu_powertune);
      }

      if(!empty_string(profile->gpu_vddc))
      {
        pool->gpu_vddc = profile->gpu_vddc;
        applog(LOG_DEBUG, "Pool %i GPU Vddc set to \"%s\"", pool->pool_no, pool->gpu_vddc);
      }
#endif

      if(!empty_string(profile->shaders))
      {
        pool->shaders = profile->shaders;
        applog(LOG_DEBUG, "Pool %i Shaders set to \"%s\"", pool->pool_no, pool->shaders);
      }

      if(!empty_string(profile->worksize))
      {
        pool->worksize = profile->worksize;
        applog(LOG_DEBUG, "Pool %i Worksize set to \"%s\"", pool->pool_no, pool->worksize);
      }
    }
    else
    {
      applog(LOG_DEBUG, "Profile load failed for pool %i: profile %s not found.", pool->pool_no, pool->profile);
      //remove profile name
      pool->profile[0] = '\0';
    }
  }
}

//builds the "pools" json array for config file
json_t *build_pool_json()
{
  json_t *pool_array, *obj;
  struct pool *pool;
  struct profile *profile;
  int i;
  
  //create the "pools" array
  if(!(pool_array = json_array()))
  {
    set_last_json_error("json_array() failed on pools");
    return NULL;
  }
  
  //process pool entries
  for(i=0;i<total_pools;i++)
  {
    pool = pools[i];

    //create a new object
    if(!(obj = json_object()))
    {
      set_last_json_error("json_object() failed on pool %d", pool->pool_no);
      return NULL;
    }

    //pool name
    if(!empty_string(pool->name))
    {
      if(json_object_set(obj, "name", json_string(pool->name)) == -1)
      {
        set_last_json_error("json_object_set() failed on pool(%d):name", pool->pool_no);
        return NULL;
      }
    }
    
    //add quota/url
    if(pool->quota != 1)
    {
      if(json_object_set(obj, "quota", json_sprintf("%s%s%s%d;%s",
        ((pool->rpc_proxy)?(char *)proxytype(pool->rpc_proxytype):""),
        ((pool->rpc_proxy)?pool->rpc_proxy:""),
        ((pool->rpc_proxy)?"|":""),
        pool->quota,
        pool->rpc_url)) == -1)
      {
        set_last_json_error("json_object_set() failed on pool(%d):quota", pool->pool_no);
        return NULL;
      }
    }
    else
    {
      if(json_object_set(obj, "url", json_sprintf("%s%s%s%s",
        ((pool->rpc_proxy)?(char *)proxytype(pool->rpc_proxytype):""),
        ((pool->rpc_proxy)?pool->rpc_proxy:""),
        ((pool->rpc_proxy)?"|":""),
        pool->rpc_url)) == -1)
      {
        set_last_json_error("json_object_set() failed on pool(%d):url", pool->pool_no);
        return NULL;
      }
    }

    //user
    if(json_object_set(obj, "user", json_string(pool->rpc_user)) == -1)
    {
      set_last_json_error("json_object_set() failed on pool(%d):user", pool->pool_no);
      return NULL;
    }
    
    //pass
    if(json_object_set(obj, "pass", json_string(pool->rpc_pass)) == -1)
    {
      set_last_json_error("json_object_set() failed on pool(%d):pass", pool->pool_no);
      return NULL;
    }

    if(!pool->extranonce_subscribe)
    {
      if(json_object_set(obj, "no-extranonce-subscribe", json_true()) == -1)
      {
        set_last_json_error("json_object_set() failed on pool(%d):no-extranonce-subscribe", pool->pool_no);
        return NULL;
      }
    }
    
    if(!empty_string(pool->description))
    {
      if(json_object_set(obj, "description", json_string(pool->description)) == -1)
      {
        set_last_json_error("json_object_set() failed on pool(%d):description", pool->pool_no);
        return NULL;
      }
    }
    
    //if priority isnt the same as array index, specify it
    if(pool->prio != i) 
    {
      if(json_object_set(obj, "priority", json_sprintf("%d", pool->prio)) == -1)
      {
        set_last_json_error("json_object_set() failed on pool(%d):description", pool->pool_no);
        return NULL;
      }
    }
    
    //if a profile was specified, add it then compare pool/profile settings to see what we write
    if(!empty_string(pool->profile))
    {
      if((profile = get_profile(pool->profile)))
      {
        //save profile name
        if(json_object_set(obj, "profile", json_string(pool->profile)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):profile", pool->pool_no);
          return NULL;
        }
      }
      //profile not found use default profile
      else
        profile = &default_profile;
    }
    //or select default profile
    else
      profile = &default_profile;
    
    //if algorithm is different than profile, add it
    if(!cmp_algorithm(&pool->algorithm, &profile->algorithm)) 
    {
      //save algorithm name
      if(json_object_set(obj, "algorithm", json_string(pool->algorithm.name)) == -1)
      {
        set_last_json_error("json_object_set() failed on pool(%d):algorithm", pool->pool_no);
        return NULL;
      }
      
      //TODO: add other options like nfactor etc...
    }

    //if pool and profile value doesn't match below, add it
    //devices
    if(!empty_string(pool->devices))
    {
      if(strcmp(pool->devices, profile->devices))
      {
        if(json_object_set(obj, "devices", json_string(pool->devices)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):device", pool->pool_no);
          return NULL;
        }
      }
    }

    //lookup-gap
    if(!empty_string(pool->lookup_gap))
    {
      if(strcmp(pool->lookup_gap, profile->lookup_gap))
      {
        if(json_object_set(obj, "lookup-gap", json_string(pool->lookup_gap)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):lookup-gap", pool->pool_no);
          return NULL;
        }
      }
    }

    //intensity
    if(!empty_string(pool->intensity))
    {
      if(strcmp(pool->intensity, profile->intensity))
      {
        if(json_object_set(obj, "intensity", json_string(pool->intensity)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):intensity", pool->pool_no);
          return NULL;
        }
      }
    }

    //xintensity
    if(!empty_string(pool->xintensity))
    {
      if(strcmp(pool->xintensity, profile->xintensity) != 0)
      {
        if(json_object_set(obj, "xintensity", json_string(pool->xintensity)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):xintensity", pool->pool_no);
          return NULL;
        }
      }
    }
      
    //rawintensity
    if(!empty_string(pool->rawintensity))
    {
      if(strcmp(pool->rawintensity, profile->rawintensity) != 0)
      {
        if(json_object_set(obj, "rawintensity", json_string(pool->rawintensity)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):rawintensity", pool->pool_no);
          return NULL;
        }
      }
    }
      
    //shaders
    if(!empty_string(pool->shaders))
    {
      if(strcmp(pool->shaders, profile->shaders) != 0)
      {
        if(json_object_set(obj, "shaders", json_string(pool->shaders)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):shaders", pool->pool_no);
          return NULL;
        }
      }
    }

    //thread_concurrency
    if(!empty_string(pool->thread_concurrency))
    {
      if(strcmp(pool->thread_concurrency, profile->thread_concurrency) != 0)
      {
        if(json_object_set(obj, "thread-concurrency", json_string(pool->thread_concurrency)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):thread-concurrency", pool->pool_no);
          return NULL;
        }
      }
    }

    //worksize
    if(!empty_string(pool->worksize))
    {
      if(strcmp(pool->worksize, profile->worksize) != 0)
      {
        if(json_object_set(obj, "worksize", json_string(pool->worksize)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):worksize", pool->pool_no);
          return NULL;
        }
      }
    }
#ifdef HAVE_ADL      
    //gpu_engine
    if(!empty_string(pool->gpu_engine))
    {
      if(strcmp(pool->gpu_engine, profile->gpu_engine) != 0)
      {
        if(json_object_set(obj, "gpu-engine", json_string(pool->gpu_engine)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):gpu-engine", pool->pool_no);
          return NULL;
        }
      }
    }

    //gpu_memclock
    if(!empty_string(pool->gpu_memclock))
    {
      if(strcmp(pool->gpu_memclock, profile->gpu_memclock) != 0)
      {
        if(json_object_set(obj, "gpu-memclock", json_string(pool->gpu_memclock)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):gpu-memclock", pool->pool_no);
          return NULL;
        }
      }
    }

    //gpu_threads
    if(!empty_string(pool->gpu_threads))
    {
      if(strcmp(pool->gpu_threads, profile->gpu_threads) != 0)
      {
        if(json_object_set(obj, "gpu-threads", json_string(pool->gpu_threads)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):gpu-threads", pool->pool_no);
          return NULL;
        }
      }
    }

    //gpu_fan
    if(!empty_string(pool->gpu_fan))
    {
      if(strcmp(pool->gpu_fan, profile->gpu_fan) != 0)
      {
        if(json_object_set(obj, "gpu-fan", json_string(pool->gpu_fan)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):gpu-fan", pool->pool_no);
          return NULL;
        }
      }
    }

    //gpu-powertune
    if(!empty_string(pool->gpu_powertune))
    {
      if(strcmp(pool->gpu_powertune, profile->gpu_powertune) != 0)
      {
        if(json_object_set(obj, "gpu-powertune", json_string(pool->gpu_powertune)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):gpu-powertune", pool->pool_no);
          return NULL;
        }
      }
    }

    //gpu-vddc
    if(!empty_string(pool->gpu_vddc))
    {
      if(strcmp(pool->gpu_vddc, profile->gpu_vddc) != 0)
      {
        if(json_object_set(obj, "gpu-vddc", json_string(pool->gpu_vddc)) == -1)
        {
          set_last_json_error("json_object_set() failed on pool(%d):gpu-vddc", pool->pool_no);
          return NULL;
        }
      }
    }
#endif
    
    //all done, add pool to array...
    if(json_array_append_new(pool_array, obj) == -1)
    {
      set_last_json_error("json_array_append() failed on pool %d", pool->pool_no);
      return NULL;
    }
  }
  
  return pool_array;
}

//builds the "profiles" json array for config file
json_t *build_profile_json()
{
  json_t *profile_array, *obj;
  struct profile *profile;
  int i;
  
  //create the "pools" array
  if(!(profile_array = json_array()))
  {
    set_last_json_error("json_array() failed on profiles");
    return NULL;
  }
  
  //process pool entries
  for(i=0;i<total_profiles;i++)
  {
    profile = profiles[i];

    //create a new object
    if(!(obj = json_object()))
    {
      set_last_json_error("json_object() failed on profile %d", profile->profile_no);
      return NULL;
    }

    //profile name
    if(!empty_string(profile->name))
    {
      if(json_object_set(obj, "name", json_string(profile->name)) == -1)
      {
        set_last_json_error("json_object_set() failed on profile(%d):name", profile->profile_no);
        return NULL;
      }
    }
    
    //if algorithm is different than profile, add it - if default profile is the current profile, always add
    if(!cmp_algorithm(&default_profile.algorithm, &profile->algorithm) || !strcasecmp(default_profile.name, profile->name)) 
    {
      //save algorithm name
      if(json_object_set(obj, "algorithm", json_string(profile->algorithm.name)) == -1)
      {
        set_last_json_error("json_object_set() failed on profile(%d):algorithm", profile->profile_no);
        return NULL;
      }
      
      //TODO: add other options like nfactor etc...
    }

    //if pool and profile value doesn't match below, add it
    //devices
    if(!empty_string(profile->devices))
    {
      //always add if default profile is this profile
      if(strcmp(default_profile.devices, profile->devices) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "devices", json_string(profile->devices)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):device", profile->profile_no);
          return NULL;
        }
      }
    }

    //lookup-gap
    if(!empty_string(profile->lookup_gap))
    {
      //always add if default profile is this profile
      if(strcmp(default_profile.lookup_gap, profile->lookup_gap) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "lookup-gap", json_string(profile->lookup_gap)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):lookup-gap", profile->profile_no);
          return NULL;
        }
      }
    }

    //intensity
    if(!empty_string(profile->intensity))
    {
      //always add if default profile is this profile
      if(strcmp(default_profile.intensity, profile->intensity) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "intensity", json_string(profile->intensity)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):intensity", profile->profile_no);
          return NULL;
        }
      }
    }

    //xintensity
    if(!empty_string(profile->xintensity))
    {
      if(strcmp(default_profile.xintensity, profile->xintensity) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "xintensity", json_string(profile->xintensity)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):xintensity", profile->profile_no);
          return NULL;
        }
      }
    }
      
    //rawintensity
    if(!empty_string(profile->rawintensity))
    {
      if(strcmp(default_profile.rawintensity, profile->rawintensity) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "rawintensity", json_string(profile->rawintensity)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):rawintensity", profile->profile_no);
          return NULL;
        }
      }
    }
      
    //shaders
    if(!empty_string(profile->shaders))
    {
      if(strcmp(default_profile.shaders, profile->shaders) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "shaders", json_string(profile->shaders)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):shaders", profile->profile_no);
          return NULL;
        }
      }
    }

    //thread_concurrency
    if(!empty_string(profile->thread_concurrency))
    {
      if(strcmp(default_profile.thread_concurrency, profile->thread_concurrency) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "thread-concurrency", json_string(profile->thread_concurrency)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):thread_concurrency", profile->profile_no);
          return NULL;
        }
      }
    }

    //worksize
    if(!empty_string(profile->worksize))
    {
      if(strcmp(default_profile.worksize, profile->worksize) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "worksize", json_string(profile->worksize)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):worksize", profile->profile_no);
          return NULL;
        }
      }
    }

#ifdef HAVE_ADL      
    //gpu_engine
    if(!empty_string(profile->gpu_engine))
    {
      if(strcmp(default_profile.gpu_engine, profile->gpu_engine) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "gpu-engine", json_string(profile->gpu_engine)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):gpu-engine", profile->profile_no);
          return NULL;
        }
      }
    }

    //gpu_memclock
    if(!empty_string(profile->gpu_memclock))
    {
      if(strcmp(default_profile.gpu_memclock, profile->gpu_memclock) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "gpu-memclock", json_string(profile->gpu_memclock)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):gpu-memclock", profile->profile_no);
          return NULL;
        }
      }
    }

    //gpu_threads
    if(!empty_string(profile->gpu_threads))
    {
      if(strcmp(default_profile.gpu_threads, profile->gpu_threads) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "gpu-threads", json_string(profile->gpu_threads)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):gpu-threads", profile->profile_no);
          return NULL;
        }
      }
    }

    //gpu_fan
    if(!empty_string(profile->gpu_fan))
    {
      if(strcmp(default_profile.gpu_fan, profile->gpu_fan) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "gpu-fan", json_string(profile->gpu_fan)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):gpu-fan", profile->profile_no);
          return NULL;
        }
      }
    }

    //gpu-powertune
    if(!empty_string(profile->gpu_powertune))
    {
      if(strcmp(default_profile.gpu_powertune, profile->gpu_powertune) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "gpu-powertune", json_string(profile->gpu_powertune)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):gpu-powertune", profile->profile_no);
          return NULL;
        }
      }
    }

    //gpu-vddc
    if(!empty_string(profile->gpu_vddc))
    {
      if(strcmp(default_profile.gpu_vddc, profile->gpu_vddc) != 0 || !strcasecmp(default_profile.name, profile->name))
      {
        if(json_object_set(obj, "gpu-vddc", json_string(profile->gpu_vddc)) == -1)
        {
          set_last_json_error("json_object_set() failed on profile(%d):gpu-vddc", profile->profile_no);
          return NULL;
        }
      }
    }
#endif
    
    //all done, add pool to array...
    if(json_array_append_new(profile_array, obj) == -1)
    {
      set_last_json_error("json_array_append() failed on profile %d", profile->profile_no);
      return NULL;
    }
  }
  
  return profile_array;
}

void write_config(const char *filename)
{
  json_t *config, *obj;
  struct opt_table *opt;
  char *p, *optname;
  int i;
  
  if(!(config = json_object()))
  {
    applog(LOG_ERR, "Error: config_parser::write_config():\n json_object() failed on root."); 
    return;
  }
  
  //build pools
  if(!(obj = build_pool_json()))
  {
    applog(LOG_ERR, "Error: config_parser::write_config():\n %s.", last_json_error); 
    return;
  }
  
  //add pools to config
  if(json_object_set(config, "pools", obj) == -1)
  {
    applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set(pools) failed."); 
    return;
  }
  
  //build profiles
  if(!(obj = build_profile_json()))
  {
    applog(LOG_ERR, "Error: config_parser::write_config():\n %s.", last_json_error); 
    return;
  }
  
  //add profiles to config
  if(json_object_set(config, "profiles", obj) == -1)
  {
    applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set(profiles) failed."); 
    return;
  }

  //pool strategy
  switch(pool_strategy)
  {
    case POOL_BALANCE:
      if(json_object_set(config, "balance", json_true()) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on balance");
        return;
      }
      break;
    case POOL_LOADBALANCE:
      if(json_object_set(config, "load-balance", json_true()) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on load-balance");
        return;
      }
      break;
    case POOL_ROUNDROBIN:
      if(json_object_set(config, "round-robin", json_true()) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on round-robin");
        return;
      }
      break;
    case POOL_ROTATE:
      if(json_object_set(config, "rotate", json_sprintf("%d", opt_rotate_period)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on rotate");
        return;
      }
      break;
    //default failover only
    default:
      if(json_object_set(config, "failover-only", json_true()) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on failover-only");
        return;
      }
      break;
  }
  
  //if using a specific profile as default, set it
  if(!empty_string(default_profile.name))
  {
    if(json_object_set(config, "default-profile", json_string(default_profile.name)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on default_profile");
      return;
    }
  }
  //otherwise save default profile values
  else
  {
    //save algorithm name
    if(json_object_set(config, "algorithm", json_string(opt_algorithm->name)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on algorithm");
      return;
    }
    //TODO: add other options like nfactor etc...

    //devices
    if(!empty_string(default_profile.devices))
    {
      if(json_object_set(config, "devices", json_string(default_profile.devices)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on devices");
        return;
      }
    }

    //lookup-gap
    if(!empty_string(default_profile.lookup_gap))
    {
      if(json_object_set(config, "lookup-gap", json_string(default_profile.lookup_gap)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on lookup-gap");
        return;
      }
    }

    //intensity
    if(!empty_string(default_profile.intensity))
    {
      if(json_object_set(config, "intensity", json_string(default_profile.intensity)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on intensity");
        return;
      }
    }

    //xintensity
    if(!empty_string(default_profile.xintensity))
    {
      if(json_object_set(config, "xintensity", json_string(default_profile.xintensity)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on xintensity");
        return;
      }
    }
      
    //rawintensity
    if(!empty_string(default_profile.rawintensity))
    {
      if(json_object_set(config, "rawintensity", json_string(default_profile.rawintensity)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on rawintensity");
        return;
      }
    }
      
    //shaders
    if(!empty_string(default_profile.shaders))
    {
      if(json_object_set(config, "shaders", json_string(default_profile.shaders)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on shaders");
        return;
      }
    }

    //thread_concurrency
    if(!empty_string(default_profile.thread_concurrency))
    {
      if(json_object_set(config, "thread-concurrency", json_string(default_profile.thread_concurrency)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on thread_concurrency");
        return;
      }
    }

    //worksize
    if(!empty_string(default_profile.worksize))
    {
      if(json_object_set(config, "worksize", json_string(default_profile.worksize)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on worksize");
        return;
      }
    }

#ifdef HAVE_ADL      
    //gpu_engine
    if(!empty_string(default_profile.gpu_engine))
    {
      if(json_object_set(config, "gpu-engine", json_string(default_profile.gpu_engine)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on gpu-engine");
        return;
      }
    }

    //gpu_memclock
    if(!empty_string(default_profile.gpu_memclock))
    {
      if(json_object_set(config, "gpu-memclock", json_string(default_profile.gpu_memclock)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on gpu-memclock");
        return;
      }
    }

    //gpu_threads
    if(!empty_string(default_profile.gpu_threads))
    {
      if(json_object_set(config, "gpu-threads", json_string(default_profile.gpu_threads)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on gpu-threads");
        return;
      }
    }

    //gpu_fan
    if(!empty_string(default_profile.gpu_fan))
    {
      if(json_object_set(config, "gpu-fan", json_string(default_profile.gpu_fan)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on gpu-fan");
        return;
      }
    }

    //gpu-powertune
    if(!empty_string(default_profile.gpu_powertune))
    {
      if(json_object_set(config, "gpu-powertune", json_string(default_profile.gpu_powertune)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on gpu-powertune");
        return;
      }
    }

    //gpu-vddc
    if(!empty_string(default_profile.gpu_vddc))
    {
      if(json_object_set(config, "gpu-vddc", json_string(default_profile.gpu_vddc)) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on gpu-vddc");
        return;
      }
    }
#endif
  }

  //devices
  /*if(opt_devs_enabled) 
  {
    bool extra_devs = false;
    obj = json_string("");

    for(i = 0; i < MAX_DEVICES; i++) 
    {
      if(devices_enabled[i]) 
      {
        int startd = i;

        if(extra_devs)
          obj = json_sprintf("%s%s", json_string_value(obj), ",");

        while (i < MAX_DEVICES && devices_enabled[i + 1])
          ++i;
        
        obj = json_sprintf("%s%d", json_string_value(obj), startd);
        if(i > startd)
          obj = json_sprintf("%s-%d", json_string_value(obj), i);
      }
    }
    
    if(json_object_set(config, "devices", obj) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on devices");
      return;
    }    
  }*/
  
  //remove-disabled
  if(opt_removedisabled)
  {
    if(json_object_set(config, "remove-disabled", json_true()) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on remove-disabled");
      return;
    }    
    
  }

  //write gpu settings that aren't part of profiles -- only write if gpus are available
  if(nDevs)
  {
  
#ifdef HAVE_ADL
    //temp-cutoff
    for(i = 0;i < nDevs; i++)
      obj = json_sprintf("%s%s%d", ((i > 0)?json_string_value(obj):""), ((i > 0)?",":""), gpus[i].cutofftemp);
      
    if(json_object_set(config, "temp-cutoff", obj) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on temp-cutoff");
      return;
    }

    //temp-overheat
    for(i = 0;i < nDevs; i++)
      obj = json_sprintf("%s%s%d", ((i > 0)?json_string_value(obj):""), ((i > 0)?",":""), gpus[i].adl.overtemp);
      
    if(json_object_set(config, "temp-overheat", obj) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on temp-overheat");
      return;
    }

    //temp-target
    for(i = 0;i < nDevs; i++)
      obj = json_sprintf("%s%s%d", ((i > 0)?json_string_value(obj):""), ((i > 0)?",":""), gpus[i].adl.targettemp);
      
    if(json_object_set(config, "temp-target", obj) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on temp-target");
      return;
    }
    
    //reorder gpus
    if(opt_reorder)
    {
      if(json_object_set(config, "gpu-reorder", json_true()) == -1)
      {
        applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on gpu-reorder");
        return;
      }
    }

    //gpu-memdiff
    for(i = 0;i < nDevs; i++)
      obj = json_sprintf("%s%s%d", ((i > 0)?json_string_value(obj):""), ((i > 0)?",":""), (int)gpus[i].gpu_memdiff);
      
    if(json_object_set(config, "gpu-memdiff", obj) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on gpu-memdiff");
      return;
    }
#endif
  }

  //add other misc options
  //shares
  if(json_object_set(config, "shares", json_sprintf("%d", opt_shares)) == -1)
  {
    applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on shares");
    return;
  }
  
#if defined(unix) || defined(__APPLE__)
  //monitor
  if(opt_stderr_cmd && *opt_stderr_cmd)
  {
    if(json_object_set(config, "monitor", json_string(opt_stderr_cmd)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on monitor");
      return;
    }
  }
#endif // defined(unix)

  //kernel path
  if(opt_kernel_path && *opt_kernel_path) 
  {
    //strip end /
    char *kpath = strdup(opt_kernel_path);
    if(kpath[strlen(kpath)-1] == '/')
      kpath[strlen(kpath)-1] = 0;
    
    if(json_object_set(config, "kernel-path", json_string(kpath)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on kernel-path");
      return;
    }
  }
  
  //sched-time
  if(schedstart.enable)
  {
    if(json_object_set(config, "sched-time", json_sprintf("%d:%d", schedstart.tm.tm_hour, schedstart.tm.tm_min)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on sched-time");
      return;
    }
  }
  
  //stop-time
  if(schedstop.enable)
  {
    if(json_object_set(config, "stop-time", json_sprintf("%d:%d", schedstop.tm.tm_hour, schedstop.tm.tm_min)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on stop-time");
      return;
    }
  }
  
  //socks-proxy
  if(opt_socks_proxy && *opt_socks_proxy)
  {
    if(json_object_set(config, "socks-proxy", json_string(opt_socks_proxy)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on socks-proxy");
      return;
    }
  }
  
  
  //api stuff
  //api-allow
  if(opt_api_allow)
  {
    if(json_object_set(config, "api-allow", json_string(opt_api_allow)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on api-allow");
      return;
    }
  }
  
  //api-mcast-addr
  if(strcmp(opt_api_mcast_addr, API_MCAST_ADDR) != 0)
  {
    if(json_object_set(config, "api-mcast-addr", json_string(opt_api_mcast_addr)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on api-mcast-addr");
      return;
    }
  }

  //api-mcast-code
  if(strcmp(opt_api_mcast_code, API_MCAST_CODE) != 0)
  {
    if(json_object_set(config, "api-mcast-code", json_string(opt_api_mcast_code)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on api-mcast-code");
      return;
    }
  }

  //api-mcast-des
  if(*opt_api_mcast_des)
  {
    if(json_object_set(config, "api-mcast-des", json_string(opt_api_mcast_des)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on api-mcast-des");
      return;
    }
  }

  //api-description
  if(strcmp(opt_api_description, PACKAGE_STRING) != 0)
  {
    if(json_object_set(config, "api-description", json_string(opt_api_description)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on api-description");
      return;
    }
  }
  
  //api-groups
  if(opt_api_groups)
  {
    if(json_object_set(config, "api-groups", json_string(opt_api_groups)) == -1)
    {
      applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on api-groups");
      return;
    }
  }

  //add other misc bool/int options
  for(opt = opt_config_table; opt->type != OPT_END; opt++) 
  {
    optname = strdup(opt->names);
    
    //ignore --pool-* and --profile-* options
    if(!strstr(optname, "--pool-") && !strstr(optname, "--profile-"))
    {
      //get first available long form option name
      for(p = strtok(optname, "|"); p; p = strtok(NULL, "|")) 
      {
        //skip short options
        if(p[1] != '-')
          continue;

        //type bool
        if (opt->type & OPT_NOARG &&
          ((void *)opt->cb == (void *)opt_set_bool || (void *)opt->cb == (void *)opt_set_invbool) &&
          (*(bool *)opt->u.arg == ((void *)opt->cb == (void *)opt_set_bool)))
        {
          if(json_object_set(config, p+2, json_true()) == -1)
          {
            applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on %s.", p+2); 
            return;
          }
          break;  //exit for loop... so we don't enter a duplicate value if an option has multiple names
        }
        //numeric types
        else if (opt->type & OPT_HASARG &&
          ((void *)opt->cb_arg == (void *)set_int_0_to_9999 ||
          (void *)opt->cb_arg == (void *)set_int_1_to_65535 ||
          (void *)opt->cb_arg == (void *)set_int_0_to_10 ||
          (void *)opt->cb_arg == (void *)set_int_1_to_10) && opt->desc != opt_hidden)
        {
          if(json_object_set(config, p+2, json_sprintf("%d", *(int *)opt->u.arg)) == -1)
          {
            applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set() failed on %s.", p+2); 
            return;
          }
          break;  //exit for loop... so we don't enter a duplicate value if an option has multiple names
        }
      }
    }
  } 
  
  json_dump_file(config, filename, JSON_PRESERVE_ORDER|JSON_INDENT(4));
}
