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

#ifdef HAVE_LIBCURL
#include <curl/curl.h>
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
  profile->algorithm.name[0] = '\0';

  // intensity set to blank by default
  buf[0] = 0;
  profile->intensity = strdup(buf);
  profile->xintensity = strdup(buf);
  profile->rawintensity = strdup(buf);

  profiles = (struct profile **)realloc(profiles, sizeof(struct profile *) * (total_profiles + 2));
  profiles[total_profiles++] = profile;

  return profile;
}

static void remove_profile(struct profile *profile)
{
  int i;
  int found = 0;

  for(i = 0; i < (total_profiles - 1); i++)
  {
    //look for the profile
    if(profiles[i]->profile_no == profile->profile_no)
      found = 1;

    //once we found the profile, change the current index profile to next
    if(found)
    {
      profiles[i] = profiles[i+1];
      profiles[i]->profile_no = i;
    }
  }

  //give the profile an invalid number and remove
  profile->profile_no = total_profiles;
  profile->removed = true;
  total_profiles--;
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

  if (empty_string(name)) {
    return NULL;
  }

  for (i=0;i<total_profiles;++i) {
    if (!safe_cmp(profiles[i]->name, name)) {
      return profiles[i];
    }
  }

  return NULL;
}

struct profile *get_gpu_profile(int gpuid)
{
  struct profile *profile;
  struct pool *pool = pools[gpus[gpuid].thr[0]->pool_no];

  if (!(profile = get_profile(pool->profile))) {
    if (!(profile = get_profile(default_profile.name))) {
      profile = &default_profile;
    }
  }

  return profile;
}

/******* Default profile functions used during config parsing *****/
char *set_default_algorithm(const char *arg)
{
  set_algorithm(&default_profile.algorithm, arg);
  applog(LOG_INFO, "Set default algorithm to %s", default_profile.algorithm.name);

  return NULL;
}

char *set_default_nfactor(const char *arg)
{
  set_algorithm_nfactor(&default_profile.algorithm, (const uint8_t) atoi(arg));
  applog(LOG_INFO, "Set algorithm N-factor to %d (N to %d)", default_profile.algorithm.nfactor);

  return NULL;
}

char *set_default_devices(const char *arg)
{
  default_profile.devices = arg;
  return NULL;
}

char *set_default_kernelfile(const char *arg)
{
  applog(LOG_INFO, "Set default kernel file to %s", arg);
  default_profile.algorithm.kernelfile = arg;

  return NULL;
}

char *set_default_lookup_gap(const char *arg)
{
  default_profile.lookup_gap = arg;
  return NULL;
}

char *set_default_intensity(const char *arg)
{
  opt_set_charp(arg, &default_profile.intensity);
  return NULL;
}

char *set_default_xintensity(const char *arg)
{
  opt_set_charp(arg, &default_profile.xintensity);
  return NULL;
}

char *set_default_rawintensity(const char *arg)
{
  opt_set_charp(arg, &default_profile.rawintensity);
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

  applog(LOG_DEBUG, "Setting profile %s algorithm to %s", profile->name, arg);
  set_algorithm(&profile->algorithm, arg);

  return NULL;
}

char *set_profile_devices(const char *arg)
{
  struct profile *profile = get_current_profile();
  profile->devices = arg;
  return NULL;
}

char *set_profile_kernelfile(const char *arg)
{
  struct profile *profile = get_current_profile();

  applog(LOG_DEBUG, "Setting profile %s algorithm kernel file to %s", profile->name, arg);
  profile->algorithm.kernelfile = arg;

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
  opt_set_charp(arg, &profile->intensity);
  return NULL;
}

char *set_profile_xintensity(const char *arg)
{
  struct profile *profile = get_current_profile();
  opt_set_charp(arg, &profile->xintensity);
  return NULL;
}

char *set_profile_rawintensity(const char *arg)
{
  struct profile *profile = get_current_profile();
  opt_set_charp(arg, &profile->rawintensity);
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

/**************************************
 * Remote Config Functions (Curl Only)
 **************************************/
#ifdef HAVE_LIBCURL
  struct remote_config {
    const char *filename;
    FILE *stream;
  };

  //curl file data write callback
  static size_t fetch_remote_config_cb(void *buffer, size_t size, size_t nmemb, void *stream)
  {
    struct remote_config *out = (struct remote_config *)stream;

    //create file if not created
    if(out && !out->stream)
    {
      if(!(out->stream = fopen(out->filename, "w+")))
        return -1;
    }

    return fwrite(buffer, size, nmemb, out->stream);
  }

  //download remote config file - return filename on success or NULL on failure
  static char *fetch_remote_config(const char *url)
  {
    CURL *curl;
    CURLcode res;
    char *p;
    struct remote_config file = { "", NULL };

    //get filename out of url
    if((p = (char *)strrchr(url, '/')) == NULL)
    {
      applog(LOG_ERR, "Fetch remote file failed: Invalid URL");
      return NULL;
    }

    file.filename = p+1;

    //check for empty filename
    if(file.filename[0] == '\0')
    {
      applog(LOG_ERR, "Fetch remote file failed: Invalid Filename");
      return NULL;
    }

    //init curl
    if((curl = curl_easy_init()) == NULL)
    {
      applog(LOG_ERR, "Fetch remote file failed: curl init failed.");
      return NULL;
    }

    //https stuff - skip verification we just want the data
    if(strstr(url, "https") != NULL)
      curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);

    //set url
    curl_easy_setopt(curl, CURLOPT_URL, url);
    //set write callback and fileinfo
    curl_easy_setopt(curl, CURLOPT_FAILONERROR, 1); // fail on 404 or other 4xx http codes
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30); // timeout after 30 secs to prevent being stuck
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &file); // stream to write data to
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, fetch_remote_config_cb);  // callback function to write to config file

    if((res = curl_easy_perform(curl)) != CURLE_OK)
      applog(LOG_ERR, "Fetch remote file failed: %s", curl_easy_strerror(res));

    if(file.stream)
      fclose(file.stream);

    curl_easy_cleanup(curl);

    return (char *)((res == CURLE_OK)?file.filename:NULL);
  }
#endif

/***************************************
* Config Parsing Functions
****************************************/
//Handle parsing JSON objects
void parse_config_object(json_t *obj, const char *parentkey, bool fileconf, int parent_iteration)
{
  //char *err = NULL;
  const char *key;
  size_t idx;
  json_t *val, *subval;

  json_object_foreach(obj, key, val)
  {
    //process include
    if(!strcasecmp(key, "include"))
    {
      if(val && json_is_string(val))
        load_config(json_string_value(val), parentkey, NULL);
    }
    //process includes - multi include
    else if(!strcasecmp(key, "includes"))
    {
      if(val && json_is_array(val))
      {
        json_array_foreach(val, idx, subval)
        {
          if(subval && json_is_string(subval))
            load_config(json_string_value(subval), parentkey, NULL);
        }
      }
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
  if(!strcasecmp(parentkey, "pools") || !strcasecmp(parentkey, "profiles") || !strcasecmp(parentkey, "events"))
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
        if ((opt->type & OPT_HASARG) && json_is_string(val)) {
          err = opt->cb_arg(json_string_value(val), opt->u.arg);
        }
        //boolean values
        else if ((opt->type & OPT_NOARG) && json_is_true(val)) {
          err = opt->cb(opt->u.arg);
        }
        else {
          err = "Invalid value";
        }
      }
      else {
        err = "Invalid option";
      }
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

  #ifdef HAVE_LIBCURL
    int retry = opt_remoteconf_retry;
    const char *url;

    // if detected as url
    if ((strstr(arg, "http://") != NULL) || (strstr(arg, "https://") != NULL) || (strstr(arg, "ftp://") != NULL)) {
      url = strdup(arg);

      do {
        // wait for next retry
        if (retry < opt_remoteconf_retry) {
          sleep(opt_remoteconf_wait);
        }

        // download config file locally and reset arg to it so we can parse it
        if ((arg = fetch_remote_config(url)) != NULL) {
          break;
        }

        --retry;
      } while (retry);

      // file not downloaded... abort
      if (arg == NULL) {
        // if we should use last downloaded copy...
        if (opt_remoteconf_usecache) {
          char *p;

          // extract filename out of url
          if ((p = (char *)strrchr(url, '/')) == NULL) {
            quit(1, "%s: invalid URL.", url);
          }

          arg = p+1;
        } else {
          quit(1, "%s: unable to download config file.", url);
        }
      }
    }
  #endif

  // most likely useless but leaving it here for now...
  if (!cnfbuf) {
    cnfbuf = strdup(arg);
  }

  // no need to restrict the number of includes... if it causes problems, restore it later
  /*if(++include_count > JSON_MAX_DEPTH)
    return JSON_MAX_DEPTH_ERR;
  */

  // check if the file exists
  if (access(arg, F_OK) == -1) {
    quit(1, "%s: file not found.", arg);
  }

  #if JANSSON_MAJOR_VERSION > 1
    config = json_load_file(arg, 0, &err);
  #else
    config = json_load_file(arg, &err);
  #endif

  // if json root is not an object, error out
  if (!json_is_object(config)) {
    return set_last_json_error("Error: JSON decode of file \"%s\" failed:\n %s", arg, err.text);
  }

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

void init_default_profile()
{
  char buf[32];

  buf[0] = 0;

  default_profile.name = strdup(buf);
  default_profile.algorithm.name[0] = 0;
  default_profile.algorithm.kernelfile = strdup(buf);
  default_profile.intensity = strdup(buf);
  default_profile.xintensity = strdup(buf);
  default_profile.rawintensity = strdup(buf);
}

// assign default settings from default profile if set
void load_default_profile()
{
  struct profile *profile;

  if (empty_string(default_profile.name))
    return;

  applog(LOG_DEBUG, "default_profile.name is %s", default_profile.name);

  // find profile ...
  if(!(profile = get_profile(default_profile.name)))
  {
    applog(LOG_WARNING, "Could not load default profile %s", default_profile.name);
    return;
  }

  // ... and copy settings
  if(!empty_string(profile->algorithm.name))
    default_profile.algorithm = profile->algorithm;

  if(!empty_string(profile->devices))
    default_profile.devices = profile->devices;

  if(!empty_string(profile->lookup_gap))
    default_profile.lookup_gap = profile->lookup_gap;

  if(!empty_string(profile->intensity))
    default_profile.intensity = profile->intensity;

  if(!empty_string(profile->xintensity))
    default_profile.xintensity = profile->xintensity;

  if(!empty_string(profile->rawintensity))
    default_profile.rawintensity = profile->rawintensity;

  if(!empty_string(profile->thread_concurrency))
    default_profile.thread_concurrency = profile->thread_concurrency;

#ifdef HAVE_ADL
  if(!empty_string(profile->gpu_engine))
    default_profile.gpu_engine = profile->gpu_engine;

  if(!empty_string(profile->gpu_memclock))
    default_profile.gpu_memclock = profile->gpu_memclock;

  if(!empty_string(profile->gpu_threads))
    default_profile.gpu_threads = profile->gpu_threads;

  if(!empty_string(profile->gpu_fan))
    default_profile.gpu_fan = profile->gpu_fan;

  if(!empty_string(profile->gpu_powertune))
    default_profile.gpu_powertune = profile->gpu_powertune;

  if(!empty_string(profile->gpu_vddc))
    default_profile.gpu_vddc = profile->gpu_vddc;
#endif
  if(!empty_string(profile->shaders))
    default_profile.shaders = profile->shaders;

  if(!empty_string(profile->worksize))
    default_profile.worksize = profile->worksize;
}

//apply default settings
void apply_defaults()
{
  //if no algorithm specified, use scrypt as default
  if (empty_string(default_profile.algorithm.name))
    set_algorithm(&default_profile.algorithm, "scrypt");

  //by default all unless specified
  if(empty_string(default_profile.devices))
    default_profile.devices = strdup("all");

  applog(LOG_DEBUG, "Default Devices = %s", default_profile.devices);
  set_devices((char *)default_profile.devices);

  //set raw intensity first
  if (!empty_string(default_profile.rawintensity))
    set_rawintensity(default_profile.rawintensity);
  //then try xintensity
  else if (!empty_string(default_profile.xintensity))
    set_xintensity(default_profile.xintensity);
  //then try intensity
  else if (!empty_string(default_profile.intensity))
    set_intensity(default_profile.intensity);

  if (!empty_string(default_profile.lookup_gap))
    set_lookup_gap((char *)default_profile.lookup_gap);

  if (!empty_string(default_profile.thread_concurrency))
    set_thread_concurrency(default_profile.thread_concurrency);

#ifdef HAVE_ADL
  if (!empty_string(default_profile.gpu_engine))
    set_gpu_engine(default_profile.gpu_engine);

  if (!empty_string(default_profile.gpu_memclock))
    set_gpu_memclock(default_profile.gpu_memclock);

  if (!empty_string(default_profile.gpu_threads))
    set_gpu_threads(default_profile.gpu_threads);

  if (!empty_string(default_profile.gpu_fan))
    set_gpu_fan(default_profile.gpu_fan);

  if (!empty_string(default_profile.gpu_powertune))
    set_gpu_powertune((char *)default_profile.gpu_powertune);

  if (!empty_string(default_profile.gpu_vddc))
    set_gpu_vddc((char *)default_profile.gpu_vddc);
#endif

  if (!empty_string(default_profile.shaders))
    set_shaders((char *)default_profile.shaders);

  if (!empty_string(default_profile.worksize))
    set_worksize((char *)default_profile.worksize);
}

//apply profile settings to pools
void apply_pool_profiles()
{
  int i;

  for (i=total_pools; i--;)
    apply_pool_profile(pools[i]);
}

void apply_pool_profile(struct pool *pool)
{
  struct profile *profile;

  //if the pool has a profile set load it
  if(!empty_string(pool->profile))
  {
    applog(LOG_DEBUG, "Loading settings from profile \"%s\" for pool %i", pool->profile, pool->pool_no);

    //find profile and apply settings to the pool
    if(!(profile = get_profile(pool->profile)))
    {
      //if not found, remove profile name and use default profile.
      applog(LOG_DEBUG, "Profile load failed for pool %i: profile %s not found. Using default profile.", pool->pool_no, pool->profile);
      //remove profile name
      pool->profile[0] = '\0';

      profile = &default_profile;
    }
  }
  //no profile specified in pool, use default profile
  else
  {
    applog(LOG_DEBUG, "Loading settings from default_profile for pool %i", pool->pool_no);
    profile = &default_profile;
  }

  //only apply profiles settings not already defined in the pool
  //if no algorithm is specified, use profile's or default profile's
  if(empty_string(pool->algorithm.name))
  {
    if(!empty_string(profile->algorithm.name))
        pool->algorithm = profile->algorithm;
    else
        pool->algorithm = default_profile.algorithm;
  }
  applog(LOG_DEBUG, "Pool %i Algorithm set to \"%s\"", pool->pool_no, pool->algorithm.name);

  // if the pool doesn't have a specific kernel file...
  if (empty_string(pool->algorithm.kernelfile)) {
    // ...but profile does, apply it to the pool
    if (!empty_string(profile->algorithm.kernelfile)) {
        pool->algorithm.kernelfile = profile->algorithm.kernelfile;
        applog(LOG_DEBUG, "Pool %i Kernel File set to \"%s\"", pool->pool_no, pool->algorithm.kernelfile);
    // ...or default profile does, apply it to the pool
    } else if (!empty_string(default_profile.algorithm.kernelfile)) {
        pool->algorithm.kernelfile = default_profile.algorithm.kernelfile;
        applog(LOG_DEBUG, "Pool %i Kernel File set to \"%s\"", pool->pool_no, pool->algorithm.kernelfile);
    }
  }

  if(pool_cmp(pool->devices, default_profile.devices))
  {
    if(!empty_string(profile->devices))
        pool->devices = profile->devices;
    else
        pool->devices = default_profile.devices;
  }
  applog(LOG_DEBUG, "Pool %i devices set to \"%s\"", pool->pool_no, pool->devices);

  if(pool_cmp(pool->lookup_gap, default_profile.lookup_gap))
  {
    if(!empty_string(profile->lookup_gap))
        pool->lookup_gap = profile->lookup_gap;
    else
        pool->lookup_gap = default_profile.lookup_gap;
  }
  applog(LOG_DEBUG, "Pool %i lookup gap set to \"%s\"", pool->pool_no, pool->lookup_gap);

  int int_type = 0;

  // FIXME: ifs from hell...
  // First look for an existing intensity on pool
  if (!empty_string(pool->rawintensity)) {
    int_type = 2;
  }
  else if (!empty_string(pool->xintensity)) {
    int_type = 1;
  }
  else if (!empty_string(pool->intensity)) {
    int_type = 0;
  }
  else {
    //no intensity found on pool... check if the profile has one and use it...
    if (!empty_string(profile->rawintensity)) {
      int_type = 2;
      pool->rawintensity = profile->rawintensity;
    }
    else if (!empty_string(profile->xintensity)) {
      int_type = 1;
      pool->xintensity = profile->xintensity;
    }
    else if (!empty_string(profile->intensity)) {
      int_type = 0;
      pool->intensity = profile->intensity;
    }
    else {
      //nothing in profile... check default profile/globals
      if (!empty_string(default_profile.rawintensity)) {
        int_type = 2;
        pool->rawintensity = default_profile.rawintensity;
      }
      else if (!empty_string(default_profile.xintensity)) {
        int_type = 1;
        pool->xintensity = default_profile.xintensity;
      }
      else if (!empty_string(default_profile.intensity)) {
        int_type = 0;
        pool->intensity = default_profile.intensity;
      }
      else {
        //nothing anywhere? default to sgminer default of 8
        int_type = 0;
        pool->intensity = strdup("8");
      }
    }
  }

  switch(int_type) {
    case 2:
      applog(LOG_DEBUG, "Pool %d Raw Intensity set to \"%s\"", pool->pool_no, pool->rawintensity);
      break;

    case 1:
      applog(LOG_DEBUG, "Pool %d XIntensity set to \"%s\"", pool->pool_no, pool->xintensity);
      break;

    default:
      applog(LOG_DEBUG, "Pool %d Intensity set to \"%s\"", pool->pool_no, pool->intensity);
      break;
  }

  if(pool_cmp(pool->thread_concurrency, default_profile.thread_concurrency))
  {
    /* allow empty string TC
      if(!empty_string(profile->thread_concurrency))*/
      pool->thread_concurrency = profile->thread_concurrency;
/*    else
        pool->thread_concurrency = default_profile.thread_concurrency;*/
  }
  applog(LOG_DEBUG, "Pool %i Thread Concurrency set to \"%s\"", pool->pool_no, pool->thread_concurrency);

  #ifdef HAVE_ADL
    if(pool_cmp(pool->gpu_engine, default_profile.gpu_engine))
    {
      if(!empty_string(profile->gpu_engine))
          pool->gpu_engine = profile->gpu_engine;
      else
          pool->gpu_engine = default_profile.gpu_engine;
    }
    applog(LOG_DEBUG, "Pool %i GPU Clock set to \"%s\"", pool->pool_no, pool->gpu_engine);

    if(pool_cmp(pool->gpu_memclock, default_profile.gpu_memclock))
    {
      if(!empty_string(profile->gpu_memclock))
          pool->gpu_memclock = profile->gpu_memclock;
      else
          pool->gpu_memclock = default_profile.gpu_memclock;
    }
    applog(LOG_DEBUG, "Pool %i GPU Memory clock set to \"%s\"", pool->pool_no, pool->gpu_memclock);

    if(pool_cmp(pool->gpu_threads, default_profile.gpu_threads))
    {
      if(!empty_string(profile->gpu_threads))
          pool->gpu_threads = profile->gpu_threads;
      else
          pool->gpu_threads = default_profile.gpu_threads;
    }
    applog(LOG_DEBUG, "Pool %i GPU Threads set to \"%s\"", pool->pool_no, pool->gpu_threads);

    if(pool_cmp(pool->gpu_fan, default_profile.gpu_fan))
    {
      if(!empty_string(profile->gpu_fan))
          pool->gpu_fan = profile->gpu_fan;
      else
          pool->gpu_fan = default_profile.gpu_fan;
    }
    applog(LOG_DEBUG, "Pool %i GPU Fan set to \"%s\"", pool->pool_no, pool->gpu_fan);

    if(pool_cmp(pool->gpu_powertune, default_profile.gpu_powertune))
    {
      if(!empty_string(profile->gpu_powertune))
          pool->gpu_powertune = profile->gpu_powertune;
      else
          pool->gpu_powertune = default_profile.gpu_powertune;
    }
    applog(LOG_DEBUG, "Pool %i GPU Powertune set to \"%s\"", pool->pool_no, pool->gpu_powertune);

    if(pool_cmp(pool->gpu_vddc, default_profile.gpu_vddc))
    {
      if(!empty_string(profile->gpu_vddc))
          pool->gpu_vddc = profile->gpu_vddc;
      else
          pool->gpu_vddc = default_profile.gpu_vddc;
    }
    applog(LOG_DEBUG, "Pool %i GPU Vddc set to \"%s\"", pool->pool_no, pool->gpu_vddc);
  #endif

  if(pool_cmp(pool->shaders, default_profile.shaders))
  {
    if(!empty_string(profile->shaders))
        pool->shaders = profile->shaders;
    else
        pool->shaders = default_profile.shaders;
  }
  applog(LOG_DEBUG, "Pool %i Shaders set to \"%s\"", pool->pool_no, pool->shaders);

  if(pool_cmp(pool->worksize, default_profile.worksize))
  {
    if(!empty_string(profile->worksize))
        pool->worksize = profile->worksize;
    else
        pool->worksize = default_profile.worksize;
  }
  applog(LOG_DEBUG, "Pool %i Worksize set to \"%s\"", pool->pool_no, pool->worksize);
}

/***************************************
* Config Writer Functions
****************************************/

/*******************************
 * Helper macros
 *******************************/
#define JSON_POOL_ERR "json_object_set() failed on pool(%d):%s"
#define JSON_PROFILE_ERR "json_object_set() failed on profile(%d):%s"
#define JSON_ROOT_ERR "Error: config_parser::write_config():\n json_object_set() failed on %s"

#ifndef json_pool_add
  #define json_pool_add(obj, key, val, id) \
    if(json_object_set(obj, key, val) == -1) { \
      set_last_json_error(JSON_POOL_ERR, id, key); \
      return NULL; \
    }
#endif

#ifndef json_profile_add
  #define json_profile_add(obj, key, val, parentkey, id) \
    if(json_object_set(obj, key, val) == -1) { \
      if(!empty_string(parentkey)) { \
        set_last_json_error(JSON_PROFILE_ERR, id, key); \
        return NULL; \
      } else { \
        applog(LOG_ERR, JSON_ROOT_ERR, key); \
        return NULL; \
      } \
    }
#endif

#ifndef json_add
  #define json_add(obj, key, val) \
    if(json_object_set(obj, key, val) == -1) { \
      applog(LOG_ERR, JSON_ROOT_ERR, key); \
      return; \
    }
#endif

// helper function to add json values to pool object
static json_t *build_pool_json_add(json_t *object, const char *key, const char *val, const char *str_compare, const char *default_compare, int id)
{
  // if pool value is empty, abort
  if (empty_string(val))
    return object;

  // check to see if its the same value as profile, abort if it is
  if(safe_cmp(str_compare, val) == 0)
    return object;

  // check to see if it's the same value as default profile, abort if it is
  if(safe_cmp(default_compare, val) == 0)
    return object;

  // not same value, add value to JSON
  json_pool_add(object, key, json_string(val), id);

  return object;
}

//builds the "pools" json array for config file
static json_t *build_pool_json()
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

    // pool name
    if(!empty_string(pool->name))
      json_pool_add(obj, "name", json_string(pool->name), pool->pool_no);

    // add quota/url
    if(pool->quota != 1)
    {
      json_pool_add(obj, "quota", json_sprintf("%s%s%s%d;%s",
        ((pool->rpc_proxy)?(char *)proxytype(pool->rpc_proxytype):""),
        ((pool->rpc_proxy)?pool->rpc_proxy:""),
        ((pool->rpc_proxy)?"|":""),
        pool->quota,
        pool->rpc_url), pool->pool_no);
    }
    else
    {
      json_pool_add(obj, "url", json_sprintf("%s%s%s%s",
        ((pool->rpc_proxy)?(char *)proxytype(pool->rpc_proxytype):""),
        ((pool->rpc_proxy)?pool->rpc_proxy:""),
        ((pool->rpc_proxy)?"|":""),
        pool->rpc_url), pool->pool_no);
    }

    // user
    json_pool_add(obj, "user", json_string(pool->rpc_user), pool->pool_no);

    // pass
    json_pool_add(obj, "pass", json_string(pool->rpc_pass), pool->pool_no);

    if (!pool->extranonce_subscribe)
      json_pool_add(obj, "no-extranonce", json_true(), pool->pool_no);

    if (!empty_string(pool->description))
      json_pool_add(obj, "no-description", json_string(pool->description), pool->pool_no);

    // if priority isnt the same as array index, specify it
    if (pool->prio != i)
      json_pool_add(obj, "priority", json_sprintf("%d", pool->prio), pool->pool_no);

    // if a profile was specified, add it then compare pool/profile settings to see what we write
    if (!empty_string(pool->profile))
    {
      if ((profile = get_profile(pool->profile)))
      {
        // save profile name
        json_pool_add(obj, "profile", json_string(pool->profile), pool->pool_no);
      }
      // profile not found use default profile
      else
        profile = &default_profile;
    }
    // or select default profile
    else
      profile = &default_profile;

    // if algorithm is different than profile, add it
    if (!cmp_algorithm(&pool->algorithm, &profile->algorithm))
    {
      // save algorithm name
      json_pool_add(obj, "algorithm", json_string(pool->algorithm.name), pool->pool_no);

      // save nfactor also
      if (pool->algorithm.type == ALGO_NSCRYPT)
        json_pool_add(obj, "nfactor", json_sprintf("%d", profile->algorithm.nfactor), pool->pool_no);
    }

    // if pool and profile value doesn't match below, add it
    // devices
    if (!build_pool_json_add(obj, "device", pool->devices, profile->devices, default_profile.devices, pool->pool_no))
      return NULL;

    // kernelfile
    if (!build_pool_json_add(obj, "kernelfile", pool->algorithm.kernelfile, profile->algorithm.kernelfile, default_profile.algorithm.kernelfile, pool->pool_no))
      return NULL;

    // lookup-gap
    if (!build_pool_json_add(obj, "lookup-gap", pool->lookup_gap, profile->lookup_gap, default_profile.lookup_gap, pool->pool_no))
      return NULL;

    // rawintensity
    if (!empty_string(pool->rawintensity)) {
      if (!build_pool_json_add(obj, "rawintensity", pool->rawintensity, profile->rawintensity, default_profile.rawintensity, pool->pool_no)) {
        return NULL;
      }
    }
    // xintensity
    else if (!empty_string(pool->xintensity)) {
      if (!build_pool_json_add(obj, "xintensity", pool->xintensity, profile->xintensity, default_profile.xintensity, pool->pool_no)) {
        return NULL;
      }
    }
    // intensity
    else if (!empty_string(pool->intensity)) {
      if (!build_pool_json_add(obj, "intensity", pool->intensity, profile->intensity, default_profile.intensity, pool->pool_no)) {
        return NULL;
      }
    }

    // shaders
    if (!build_pool_json_add(obj, "shaders", pool->shaders, profile->shaders, default_profile.shaders, pool->pool_no))
      return NULL;

    // thread_concurrency
    if (!build_pool_json_add(obj, "thread-concurrency", pool->thread_concurrency, profile->thread_concurrency, default_profile.thread_concurrency, pool->pool_no))
      return NULL;

    // worksize
    if (!build_pool_json_add(obj, "worksize", pool->worksize, profile->worksize, default_profile.worksize, pool->pool_no))
      return NULL;

#ifdef HAVE_ADL
    // gpu_engine
    if (!build_pool_json_add(obj, "gpu-engine", pool->gpu_engine, profile->gpu_engine, default_profile.gpu_engine, pool->pool_no))
      return NULL;

    // gpu_memclock
    if (!build_pool_json_add(obj, "gpu-memclock", pool->gpu_memclock, profile->gpu_memclock, default_profile.gpu_memclock, pool->pool_no))
      return NULL;

    // gpu_threads
    if (!build_pool_json_add(obj, "gpu-threads", pool->gpu_threads, profile->gpu_threads, default_profile.gpu_threads, pool->pool_no))
      return NULL;

    // gpu_fan
    if (!build_pool_json_add(obj, "gpu-fan", pool->gpu_fan, profile->gpu_fan, default_profile.gpu_fan, pool->pool_no))
      return NULL;

    // gpu-powertune
    if (!build_pool_json_add(obj, "gpu-powertune", pool->gpu_powertune, profile->gpu_powertune, default_profile.gpu_powertune, pool->pool_no))
      return NULL;

    // gpu-vddc
    if (!build_pool_json_add(obj, "gpu-vddc", pool->gpu_vddc, profile->gpu_vddc, default_profile.gpu_vddc, pool->pool_no))
      return NULL;
#endif

    // all done, add pool to array...
    if (json_array_append_new(pool_array, obj) == -1)
    {
      set_last_json_error("json_array_append() failed on pool %d", pool->pool_no);
      return NULL;
    }
  }

  return pool_array;
}

//helper function to add json values to profile object
static json_t *build_profile_json_add(json_t *object, const char *key, const char *val, const char *str_compare, const bool isdefault, const char *parentkey, int id)
{
  //if default profile, make sure we sync profile and default_profile values...
  if(isdefault)
    val = str_compare;

  // no value, return...
  if (empty_string(val)) {
    return object;
  }

  //if the value is the same as default profile and, the current profile is not default profile, return...
  if ((safe_cmp(str_compare, val) == 0) && isdefault == false) {
    return object;
  }

  json_profile_add(object, key, json_string(val), parentkey, id);

  return object;
}

// helper function to write all the profile settings
static json_t *build_profile_settings_json(json_t *object, struct profile *profile, const bool isdefault, const char *parentkey)
{
  // if algorithm is different than default profile or profile is default profile, add it
  if (!cmp_algorithm(&default_profile.algorithm, &profile->algorithm) || isdefault)
  {
    // save algorithm name
    json_profile_add(object, "algorithm", json_string(profile->algorithm.name), parentkey, profile->profile_no);

    // save nfactor also
    if (profile->algorithm.type == ALGO_NSCRYPT)
      json_profile_add(object, "nfactor", json_sprintf("%u", profile->algorithm.nfactor), parentkey, profile->profile_no);
  }

  // devices
  if (!build_profile_json_add(object, "device", profile->devices, default_profile.devices, isdefault, parentkey, profile->profile_no))
    return NULL;

  // kernelfile
  if (!build_profile_json_add(object, "kernelfile", profile->algorithm.kernelfile, default_profile.algorithm.kernelfile, isdefault, parentkey, profile->profile_no))
    return NULL;

  // lookup-gap
  if (!build_profile_json_add(object, "lookup-gap", profile->lookup_gap, default_profile.lookup_gap, isdefault, parentkey, profile->profile_no))
    return NULL;

  // rawintensity
  if (!empty_string(profile->rawintensity) || (isdefault && !empty_string(default_profile.rawintensity))) {
    if(!build_profile_json_add(object, "rawintensity", profile->rawintensity, default_profile.rawintensity, isdefault, parentkey, profile->profile_no)) {
      return NULL;
    }
  }
  // xintensity
  else if (!empty_string(profile->xintensity) || (isdefault && !empty_string(default_profile.xintensity))) {
    if(!build_profile_json_add(object, "xintensity", profile->xintensity, default_profile.xintensity, isdefault, parentkey, profile->profile_no)) {
      return NULL;
    }
  }
  // intensity
  else if (!empty_string(profile->intensity) || (isdefault && !empty_string(default_profile.intensity))) {
    if(!build_profile_json_add(object, "intensity", profile->intensity, default_profile.intensity, isdefault, parentkey, profile->profile_no)) {
      return NULL;
    }
  }

  //shaders
  if (!build_profile_json_add(object, "shaders", profile->shaders, default_profile.shaders, isdefault, parentkey, profile->profile_no))
    return NULL;

  // thread_concurrency
  if (!build_profile_json_add(object, "thread-concurrency", profile->thread_concurrency, default_profile.thread_concurrency, isdefault, parentkey, profile->profile_no))
    return NULL;

  // worksize
  if (!build_profile_json_add(object, "worksize", profile->worksize, default_profile.worksize, isdefault, parentkey, profile->profile_no))
    return NULL;

  #ifdef HAVE_ADL
    // gpu_engine
    if (!build_profile_json_add(object, "gpu-engine", profile->gpu_engine, default_profile.gpu_engine, isdefault, parentkey, profile->profile_no))
      return NULL;

    // gpu_memclock
    if (!build_profile_json_add(object, "gpu-memclock", profile->gpu_memclock, default_profile.gpu_memclock, isdefault, parentkey, profile->profile_no))
      return NULL;

    // gpu_threads
    if (!build_profile_json_add(object, "gpu-threads", profile->gpu_threads, default_profile.gpu_threads, isdefault, parentkey, profile->profile_no))
      return NULL;

    // gpu_fan
    if (!build_profile_json_add(object, "gpu-fan", profile->gpu_fan, default_profile.gpu_fan, isdefault, parentkey, profile->profile_no))
      return NULL;

    // gpu-powertune
    if (!build_profile_json_add(object, "gpu-powertune", profile->gpu_powertune, default_profile.gpu_powertune, isdefault, parentkey, profile->profile_no))
      return NULL;

    // gpu-vddc
    if (!build_profile_json_add(object, "gpu-vddc", profile->gpu_vddc, default_profile.gpu_vddc, isdefault, parentkey, profile->profile_no))
      return NULL;
  #endif

  return object;
}

// builds the "profiles" json array for config file
json_t *build_profile_json()
{
  json_t *profile_array, *obj;
  struct profile *profile;
  bool isdefault;
  int i;

  // create the "profiles" array
  if (!(profile_array = json_array()))
  {
    set_last_json_error("json_array() failed on profiles");
    return NULL;
  }

  //process pool entries
  for (i=0;i<total_profiles;i++)
  {
    profile = profiles[i];
    isdefault = false;

    if (!empty_string(default_profile.name))
    {
      if (!strcasecmp(profile->name, default_profile.name))
        isdefault = true;
    }

    // create a new object
    if(!(obj = json_object()))
    {
      set_last_json_error("json_object() failed on profile %d", profile->profile_no);
      return NULL;
    }

    // profile name
    if (!empty_string(profile->name))
      json_profile_add(obj, "name", json_string(profile->name), "profile", profile->profile_no);

    // save profile settings
    if(!build_profile_settings_json(obj, profile, isdefault, "profile"))
      return NULL;

    // all done, add pool to array...
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

  // json root
  if (!(config = json_object()))
  {
    applog(LOG_ERR, "Error: config_parser::write_config():\n json_object() failed on root.");
    return;
  }

  // build pools
  if (!(obj = build_pool_json()))
  {
    applog(LOG_ERR, "Error: config_parser::write_config():\n %s.", last_json_error);
    return;
  }

  // add pools to config
  if (json_object_set(config, "pools", obj) == -1)
  {
    applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set(pools) failed.");
    return;
  }

  // build profiles
  if (!(obj = build_profile_json()))
  {
    applog(LOG_ERR, "Error: config_parser::write_config():\n %s.", last_json_error);
    return;
  }

  // add profiles to config
  if (json_object_set(config, "profiles", obj) == -1)
  {
    applog(LOG_ERR, "Error: config_parser::write_config():\n json_object_set(profiles) failed.");
    return;
  }

  // pool strategy
  switch (pool_strategy)
  {
    case POOL_BALANCE:
      json_add(config, "balance", json_true());
      break;
    case POOL_LOADBALANCE:
      json_add(config, "load-balance", json_true());
      break;
    case POOL_ROUNDROBIN:
      json_add(config, "round-robin", json_true());
      break;
    case POOL_ROTATE:
      json_add(config, "rotate", json_sprintf("%d", opt_rotate_period));
      break;
    //default failover only
    default:
      json_add(config, "failover-only", json_true());
      break;
  }

  //if using a specific profile as default, set it
  if (!empty_string(default_profile.name))
  {
    json_add(config, "default-profile", json_string(default_profile.name));
  }
  //otherwise save default profile values
  else
    // save default profile settings
    if(!build_profile_settings_json(config, &default_profile, true, ""))
      return;

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
    json_add(config, "remove-disabled", json_true());

  //write gpu settings that aren't part of profiles -- only write if gpus are available
  if(nDevs)
  {
    #ifdef HAVE_ADL
      //temp-cutoff
      for(i = 0;i < nDevs; i++)
        obj = json_sprintf("%s%s%d", ((i > 0)?json_string_value(obj):""), ((i > 0)?",":""), gpus[i].cutofftemp);

      json_add(config, "temp-cutoff", obj);

      //temp-overheat
      for(i = 0;i < nDevs; i++)
        obj = json_sprintf("%s%s%d", ((i > 0)?json_string_value(obj):""), ((i > 0)?",":""), gpus[i].adl.overtemp);

      json_add(config, "temp-overheat", obj);

      //temp-target
      for(i = 0;i < nDevs; i++)
        obj = json_sprintf("%s%s%d", ((i > 0)?json_string_value(obj):""), ((i > 0)?",":""), gpus[i].adl.targettemp);

      json_add(config, "temp-target", obj);

      //reorder gpus
      if(opt_reorder)
        json_add(config, "gpu-reorder", json_true());

      //gpu-memdiff - FIXME: should be moved to pool/profile options
      for(i = 0;i < nDevs; i++)
        obj = json_sprintf("%s%s%d", ((i > 0)?json_string_value(obj):""), ((i > 0)?",":""), (int)gpus[i].gpu_memdiff);

      json_add(config, "gpu-memdiff", obj);
    #endif
  }

  //add other misc options
  //shares
  json_add(config, "shares", json_sprintf("%d", opt_shares));

  #if defined(unix) || defined(__APPLE__)
    //monitor
    if(opt_stderr_cmd && *opt_stderr_cmd)
      json_add(config, "monitor", json_string(opt_stderr_cmd));
  #endif // defined(unix)

  //kernel path
  if(opt_kernel_path && *opt_kernel_path)
  {
    //strip end /
    char *kpath = strdup(opt_kernel_path);
    if(kpath[strlen(kpath)-1] == '/')
      kpath[strlen(kpath)-1] = 0;

    json_add(config, "kernel-path", json_string(kpath));
  }

  //sched-time
  if(schedstart.enable)
    json_add(config, "sched-time", json_sprintf("%d:%d", schedstart.tm.tm_hour, schedstart.tm.tm_min));

  //stop-time
  if(schedstop.enable)
    json_add(config, "stop-time", json_sprintf("%d:%d", schedstop.tm.tm_hour, schedstop.tm.tm_min));

  //socks-proxy
  if(opt_socks_proxy && *opt_socks_proxy)
    json_add(config, "socks-proxy", json_string(opt_socks_proxy));

  //api stuff
  //api-allow
  if(opt_api_allow)
    json_add(config, "api-allow", json_string(opt_api_allow));

  //api-mcast-addr
  if(strcmp(opt_api_mcast_addr, API_MCAST_ADDR) != 0)
    json_add(config, "api-mcast-addr", json_string(opt_api_mcast_addr));

  //api-mcast-code
  if(strcmp(opt_api_mcast_code, API_MCAST_CODE) != 0)
    json_add(config, "api-mcast-code", json_string(opt_api_mcast_code));

  //api-mcast-des
  if(*opt_api_mcast_des)
    json_add(config, "api-mcast-des", json_string(opt_api_mcast_des));

  //api-description
  if(strcmp(opt_api_description, PACKAGE_STRING) != 0)
    json_add(config, "api-description", json_string(opt_api_description));

  //api-groups
  if(opt_api_groups)
    json_add(config, "api-groups", json_string(opt_api_groups));

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
          json_add(config, p+2, json_true());
          break;  //exit for loop... so we don't enter a duplicate value if an option has multiple names
        }
        //numeric types
        else if (opt->type & OPT_HASARG &&
          ((void *)opt->cb_arg == (void *)set_int_0_to_9999 ||
          (void *)opt->cb_arg == (void *)set_int_1_to_65535 ||
          (void *)opt->cb_arg == (void *)set_int_0_to_10 ||
          (void *)opt->cb_arg == (void *)set_int_1_to_10) && opt->desc != opt_hidden)
        {
          json_add(config, p+2, json_sprintf("%d", *(int *)opt->u.arg));
          break;  //exit for loop... so we don't enter a duplicate value if an option has multiple names
        }
      }
    }
  }

  json_dump_file(config, filename, JSON_PRESERVE_ORDER|JSON_INDENT(2));
}

/*********************************************
 * API functions
 * *******************************************/
//profile parameters
enum {
  PR_ALGORITHM,
  PR_NFACTOR,
  PR_LOOKUPGAP,
  PR_DEVICES,
  PR_INTENSITY,
  PR_XINTENSITY,
  PR_RAWINTENSITY,
  PR_GPUENGINE,
  PR_GPUMEMCLOCK,
  PR_GPUTHREADS,
  PR_GPUFAN,
  PR_GPUPOWERTUNE,
  PR_GPUVDDC,
  PR_SHADERS,
  PR_TC,
  PR_WORKSIZE
};

void api_profile_list(struct io_data *io_data, __maybe_unused SOCKETTYPE c, __maybe_unused char *param, bool isjson, __maybe_unused char group)
{
  struct api_data *root = NULL;
  struct profile *profile;
  char buf[TMPBUFSIZ];
  bool io_open = false;
  bool b, default_done = false;
  int i;

  if (total_profiles == 0)
  {
    message(io_data, MSG_NOPROFILE, 0, NULL, isjson);
    return;
  }

  message(io_data, MSG_PROFILE, 0, NULL, isjson);

  if (isjson)
    io_open = io_add(io_data, COMSTR JSON_PROFILES);

  for (i = 0; i <= total_profiles; i++)
  {
    //last profile is the default profile
    if(i == total_profiles)
    {
      // if the default profile was already processed, skip posting it again
      if(default_done)
        break;

      profile = &default_profile;
    }
    else
      profile = profiles[i];

    //if default profile name is profile name or loop index is beyond the last profile, then it is the default profile
    if((b = (((i == total_profiles) || (!strcasecmp(default_profile.name, profile->name)))?true:false)))
      default_done = true;

    root = api_add_int(root, "PROFILE", &i, false);
    root = api_add_escape(root, "Name", profile->name, true);
    root = api_add_bool(root, "IsDefault", &b, false);
    root = api_add_escape(root, "Algorithm", isnull((char *)profile->algorithm.name, ""), true);
    root = api_add_escape(root, "Algorithm Type", (char *)algorithm_type_str[profile->algorithm.type], false);

    //show nfactor for nscrypt
    if(profile->algorithm.type == ALGO_NSCRYPT)
      root = api_add_int(root, "Algorithm NFactor", (int *)&(profile->algorithm.nfactor), false);

    root = api_add_escape(root, "LookupGap", isnull((char *)profile->lookup_gap, ""), true);
    root = api_add_escape(root, "Devices", isnull((char *)profile->devices, ""), true);
    root = api_add_escape(root, "Intensity", isnull((char *)profile->intensity, ""), true);
    root = api_add_escape(root, "XIntensity", isnull((char *)profile->xintensity, ""), true);
    root = api_add_escape(root, "RawIntensity", isnull((char *)profile->rawintensity, ""), true);
    root = api_add_escape(root, "Gpu Engine", isnull((char *)profile->gpu_engine, ""), true);
    root = api_add_escape(root, "Gpu MemClock", isnull((char *)profile->gpu_memclock, ""), true);
    root = api_add_escape(root, "Gpu Threads", isnull((char *)profile->gpu_threads, ""), true);
    root = api_add_escape(root, "Gpu Fan%", isnull((char *)profile->gpu_fan, ""), true);
    root = api_add_escape(root, "Gpu Powertune%", isnull((char *)profile->gpu_powertune, ""), true);
    root = api_add_escape(root, "Gpu Vddc", isnull((char *)profile->gpu_vddc, ""), true);
    root = api_add_escape(root, "Shaders", isnull((char *)profile->shaders, ""), true);
    root = api_add_escape(root, "Thread Concurrency", isnull((char *)profile->thread_concurrency, ""), true);
    root = api_add_escape(root, "Worksize", isnull((char *)profile->worksize, ""), true);

    root = print_data(root, buf, isjson, isjson && (i > 0));
    io_add(io_data, buf);
  }

  if (isjson && io_open)
    io_close(io_data);
}

void api_profile_add(struct io_data *io_data, __maybe_unused SOCKETTYPE c, char *param, bool isjson, __maybe_unused char group)
{
  char *p;
  char *split_str;
  struct profile *profile;
  int idx;

  split_str = strdup(param);

  //split all params by colon (:) because the comma (,) can be used in some of those parameters
  if((p = strsep(&split_str, ":")))
  {
    //get name first and see if the profile already exists
    if((profile = get_profile(p)))
    {
      message(io_data, MSG_PROFILEEXIST, 0, p, isjson);
      return;
    }

    //doesnt exist, create new profile
    profile = add_profile();

    //assign name
    profile->name = strdup(p);

    //get other parameters
    idx = 0;
    while((p = strsep(&split_str, ":")) != NULL)
    {
      switch(idx)
      {
        case PR_ALGORITHM:
          set_algorithm(&profile->algorithm, p);
          break;
        case PR_NFACTOR:
          if(!empty_string(p))
            set_algorithm_nfactor(&profile->algorithm, (const uint8_t)atoi(p));
          break;
        case PR_LOOKUPGAP:
          if(!empty_string(p))
            profile->lookup_gap = strdup(p);
          break;
        case PR_DEVICES:
          if(!empty_string(p))
            profile->devices = strdup(p);
          break;
        case PR_INTENSITY:
          if(!empty_string(p))
            profile->intensity = strdup(p);
          break;
        case PR_XINTENSITY:
          if(!empty_string(p))
            profile->xintensity = strdup(p);
          break;
        case PR_RAWINTENSITY:
          if(!empty_string(p))
            profile->rawintensity = strdup(p);
          break;
        case PR_GPUENGINE:
          if(!empty_string(p))
            profile->gpu_engine = strdup(p);
          break;
        case PR_GPUMEMCLOCK:
          if(!empty_string(p))
            profile->gpu_memclock = strdup(p);
          break;
        case PR_GPUTHREADS:
          if(!empty_string(p))
            profile->gpu_threads = strdup(p);
          break;
        case PR_GPUFAN:
          if(!empty_string(p))
            profile->gpu_fan = strdup(p);
          break;
        case PR_GPUPOWERTUNE:
          if(!empty_string(p))
            profile->gpu_powertune = strdup(p);
          break;
        case PR_GPUVDDC:
          if(!empty_string(p))
            profile->gpu_vddc = strdup(p);
          break;
        case PR_SHADERS:
          if(!empty_string(p))
            profile->shaders = strdup(p);
          break;
        case PR_TC:
          if(!empty_string(p))
            profile->thread_concurrency = strdup(p);
          break;
        case PR_WORKSIZE:
          if(!empty_string(p))
            profile->worksize = strdup(p);
          break;
        default:
          //invalid option ignore
          break;
      }

      idx++;
    }
  }
  else
  {
      message(io_data, MSG_MISPRD, 0, NULL, isjson);
      return;
  }

  message(io_data, MSG_ADDPROFILE, 0, profile->name, isjson);
}

void api_profile_remove(struct io_data *io_data, __maybe_unused SOCKETTYPE c, char *param, bool isjson, __maybe_unused char group)
{
  struct profile *profile;
  struct pool *pool;
  int i;

  //no profiles, nothing to remove
  if (total_profiles == 0)
  {
    message(io_data, MSG_NOPROFILE, 0, NULL, isjson);
    return;
  }

  //make sure profile name is supplied
  if(param == NULL || *param == '\0')
  {
    message(io_data, MSG_MISPRID, 0, NULL, isjson);
    return;
  }

  //see if the profile exists
  if(!(profile = get_profile(param)))
  {
    message(io_data, MSG_PRNOEXIST, 0, param, isjson);
    return;
  }

  //next make sure it's not the default profile
  if(!strcasecmp(default_profile.name, profile->name))
  {
    message(io_data, MSG_PRISDEFAULT, 0, param, isjson);
    return;
  }

  //make sure no pools use it
  for(i = 0;i < total_pools; i++)
  {
    pool = pools[i];

    if(!strcasecmp(pool->profile, profile->name))
    {
      message(io_data, MSG_PRINUSE, 0, param, isjson);
      return;
    }
  }

  //all set, delete the profile
  remove_profile(profile);

  message(io_data, MSG_REMPROFILE, profile->profile_no, profile->name, isjson);

  free(profile);
}

//should move to pool.c with the other pool stuff...
void api_pool_profile(struct io_data *io_data, __maybe_unused SOCKETTYPE c, char *param, bool isjson, __maybe_unused char group)
{
  struct profile *profile;
  struct pool *pool;
  char *p;
  int i;

  //no pool, nothing to change
  if (total_pools == 0)
  {
    message(io_data, MSG_NOPOOL, 0, NULL, isjson);
    return;
  }

  //no profiles, nothing to change
  if (total_profiles == 0)
  {
    message(io_data, MSG_NOPROFILE, 0, NULL, isjson);
    return;
  }

  //check if parameters were passed
  if (param == NULL || *param == '\0')
  {
    message(io_data, MSG_MISPID, 0, NULL, isjson);
    return;
  }

  //get pool number in parameter 1
  if(!(p = strtok(param, ",")))
  {
    message(io_data, MSG_MISPID, 0, NULL, isjson);
    return;
  }

  //check valid pool id
  i = atoi(p);

  if(i < 0 || i >= total_pools)
  {
    message(io_data, MSG_INVPID, i, NULL, isjson);
    return;
  }

  //get pool
  pool = pools[i];

  //get profile name in parameter 2
  if(!(p = strtok(NULL, ",")))
  {
    message(io_data, MSG_MISPRID, 0, NULL, isjson);
    return;
  }

  //see if the profile exists
  if(!(profile = get_profile(p)))
  {
    message(io_data, MSG_PRNOEXIST, 0, p, isjson);
    return;
  }

  //set profile
  pool->profile = strdup(profile->name);
  //apply settings
  apply_pool_profile(pool);

  //if current pool restart it
  if (pool == current_pool())
    switch_pools(NULL);

  message(io_data, MSG_CHPOOLPR, pool->pool_no, profile->name, isjson);
}


void update_config_intensity(struct profile *profile)
{
  int i;
  char buf[255];
  memset(buf, 0, 255);

  for (i = 0; i<nDevs; ++i) {
    if (gpus[i].dynamic) {
      sprintf(buf, "%s%sd", buf, ((i > 0)?",":""));
    }
    else {
      sprintf(buf, "%s%s%d", buf, ((i > 0)?",":""), gpus[i].intensity);
    }
  }

  if (profile->intensity) {
    free(profile->intensity);
  }

  profile->intensity = strdup((const char *)buf);

  if (profile->xintensity) {
    profile->xintensity[0] = 0;
  }

  if (profile->rawintensity) {
    profile->rawintensity[0] = 0;
  }

  // if this profile is also default profile, make sure to set the default_profile structure value
  if (!safe_cmp(profile->name, default_profile.name)) {
    if (default_profile.intensity) {
      free(default_profile.intensity);
    }

    default_profile.intensity = strdup((const char *)buf);

    if (default_profile.xintensity) {
      default_profile.xintensity[0] = 0;
    }

    if (default_profile.rawintensity) {
      default_profile.rawintensity[0] = 0;
    }
  }
}

void update_config_xintensity(struct profile *profile)
{
  int i;
  char buf[255];
  memset(buf, 0, 255);

  for (i = 0; i<nDevs; ++i) {
    sprintf(buf, "%s%s%d", buf, ((i > 0)?",":""), gpus[i].xintensity);
  }

  if (profile->intensity) {
    profile->intensity[0] = 0;
  }

  if (profile->xintensity) {
    free(profile->xintensity);
  }

  profile->xintensity = strdup((const char *)buf);

  if (profile->rawintensity) {
    profile->rawintensity[0] = 0;
  }

  // if this profile is also default profile, make sure to set the default_profile structure value
  if (!safe_cmp(profile->name, default_profile.name)) {
    if (default_profile.intensity) {
      default_profile.intensity[0] = 0;
    }

    if (default_profile.xintensity) {
      free(default_profile.xintensity);
    }

    default_profile.xintensity = strdup((const char *)buf);

    if (default_profile.rawintensity) {
      default_profile.rawintensity[0] = 0;
    }
  }
}

void update_config_rawintensity(struct profile *profile)
{
  int i;
  char buf[255];
  memset(buf, 0, 255);

  for (i = 0; i<nDevs; ++i) {
    sprintf(buf, "%s%s%d", buf, ((i > 0)?",":""), gpus[i].rawintensity);
  }

  if (profile->intensity) {
    profile->intensity[0] = 0;
  }

  if (profile->xintensity) {
    profile->xintensity[0] = 0;
  }

  if (profile->rawintensity) {
    free(profile->rawintensity);
  }

  profile->rawintensity = strdup((const char *)buf);

  // if this profile is also default profile, make sure to set the default_profile structure value
  if (!safe_cmp(profile->name, default_profile.name)) {
    if (default_profile.intensity) {
      default_profile.intensity[0] = 0;
    }

    if (default_profile.xintensity) {
      default_profile.xintensity[0] = 0;
    }

    if (default_profile.rawintensity) {
      free(default_profile.rawintensity);
    }

    default_profile.rawintensity = strdup((const char *)buf);
  }
}

