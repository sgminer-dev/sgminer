/*
 * Copyright 2013-2014 sgminer developers (see AUTHORS.md)
 * Copyright 2011-2013 Con Kolivas
 * Copyright 2011-2012 Luke Dashjr
 * Copyright 2010 Jeff Garzik
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 3 of the License, or (at your option)
 * any later version.    See COPYING for more details.
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

#if defined(unix) || defined(__APPLE__)
    #include <errno.h>
    #include <fcntl.h>
    #include <sys/wait.h>
#endif

char *cnfbuf = NULL;    //config file loaded
int fileconf_load;     //config file load status
const char def_conf[] = "sgminer.conf";
char *default_config;
bool config_loaded;
//static int include_count;

int json_array_index = -1;    //current array index being parsed
char *last_json_error = NULL;    //last json_error
//#define JSON_INCLUDE_CONF "include"
#define JSON_LOAD_ERROR "JSON decode of file '%s' failed\n %s"
#define JSON_LOAD_ERROR_LEN strlen(JSON_LOAD_ERROR)
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

#endif

char *set_default_profile(char *arg)
{
    default_profile.name = arg;
    return NULL;
}

/****** Profile functions used in during config parsing ********/
char *set_profile_name(char *arg)
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

#endif

char *set_profile_nfactor(const char *arg)
{
    struct profile *profile = get_current_profile();

    applog(LOG_DEBUG, "Setting profile %s N-factor to %s", profile->name, arg);
    set_algorithm_nfactor(&profile->algorithm, (const uint8_t) atoi(arg));

    return NULL;
}

/***************************************
* Helper Functions
****************************************/
//set last json error
void set_last_json_error(const char *fmt, ...)
{
    va_list args;
    size_t bufsize;

    //build args
    va_start(args, fmt);
    //get final string buffer size
    bufsize = vsnprintf(NULL, 0, JSON_LOAD_ERROR, args);
    va_end(args);

    //if NULL allocate memory... otherwise reallocate
    if(!last_json_error)
    {
        if(!(last_json_error = (char *)malloc(bufsize+1)))
            quit(1, "Malloc failure in json error");
    }
    else
    {
        if(!(last_json_error = (char *)realloc(last_json_error, bufsize+1)))
            quit(1, "Realloc failure in json error");
    }

    //zero out buffer
    memset(last_json_error, '\0', bufsize+1);

    //get args again
    va_start(args, fmt);
    vsnprintf(last_json_error, bufsize, JSON_LOAD_ERROR, args);
    va_end(args);
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
    {
        set_last_json_error(JSON_LOAD_ERROR, arg, err.text);
        return last_json_error;
    }

    config_loaded = true;

    /* Parse the config now, so we can override it.    That can keep pointers
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
            default_profile.intensity = profile->intensity;
            default_profile.xintensity = profile->xintensity;
            default_profile.rawintensity = profile->rawintensity;
            default_profile.thread_concurrency = profile->thread_concurrency;
#ifdef HAVE_ADL
            default_profile.gpu_engine = profile->gpu_engine;
            default_profile.gpu_memclock = profile->gpu_memclock;
            default_profile.gpu_threads = profile->gpu_threads;
            default_profile.gpu_fan = profile->gpu_fan;
#endif
        }
    }
}

//apply default settings
void apply_defaults()
{
    set_algorithm(opt_algorithm, default_profile.algorithm.name);

    if(!empty_string(default_profile.intensity))
        set_intensity(default_profile.intensity);

        if(!empty_string(default_profile.xintensity))
                set_xintensity(default_profile.xintensity);

        if(!empty_string(default_profile.rawintensity))
                set_rawintensity(default_profile.rawintensity);

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
#endif
}

//apply profile settings to pools
void apply_pool_profiles()
{
    struct profile *profile;
    int i;

    for(i=total_pools;i--;)
    {
        //if the pool has a profile set
        if(!empty_string(pools[i]->profile))
        {
            applog(LOG_DEBUG, "Loading settings from profile \"%s\" for pool %i", pools[i]->profile, pools[i]->pool_no);

            //find profile and apply settings to the pool
            if((profile = get_profile(pools[i]->profile)))
            {
                pools[i]->algorithm = profile->algorithm;
                applog(LOG_DEBUG, "Pool %i Algorithm set to \"%s\"", pools[i]->pool_no, pools[i]->algorithm.name);

                if(!empty_string(profile->intensity))
                {
                    pools[i]->intensity = profile->intensity;
                    applog(LOG_DEBUG, "Pool %i Intensity set to \"%s\"", pools[i]->pool_no, pools[i]->intensity);
                }

                if(!empty_string(profile->xintensity))
                {
                    pools[i]->xintensity = profile->xintensity;
                    applog(LOG_DEBUG, "Pool %i XIntensity set to \"%s\"", pools[i]->pool_no, pools[i]->xintensity);
                }

                if(!empty_string(profile->rawintensity))
                {
                    pools[i]->rawintensity = profile->rawintensity;
                    applog(LOG_DEBUG, "Pool %i Raw Intensity set to \"%s\"", pools[i]->pool_no, pools[i]->rawintensity);
                }

                if(!empty_string(profile->thread_concurrency))
                {
                    pools[i]->thread_concurrency = profile->thread_concurrency;
                    applog(LOG_DEBUG, "Pool %i Thread Concurrency set to \"%s\"", pools[i]->pool_no, pools[i]->thread_concurrency);
                }

#ifdef HAVE_ADL
                if(!empty_string(profile->gpu_engine))
                {
                    pools[i]->gpu_engine = profile->gpu_engine;
                    applog(LOG_DEBUG, "Pool %i GPU Clock set to \"%s\"", pools[i]->pool_no, pools[i]->gpu_engine);
                }

                if(!empty_string(profile->gpu_memclock))
                {
                    pools[i]->gpu_memclock = profile->gpu_memclock;
                    applog(LOG_DEBUG, "Pool %i GPU Memory clock set to \"%s\"", pools[i]->pool_no, pools[i]->gpu_memclock);
                }

                if(!empty_string(profile->gpu_threads))
                {
                    pools[i]->gpu_threads = profile->gpu_threads;
                    applog(LOG_DEBUG, "Pool %i GPU Threads set to \"%s\"", pools[i]->pool_no, pools[i]->gpu_threads);
                }

                if(!empty_string(profile->gpu_fan))
                {
                    pools[i]->gpu_fan = profile->gpu_fan;
                    applog(LOG_DEBUG, "Pool %i GPU Fan set to \"%s\"", pools[i]->pool_no, pools[i]->gpu_fan);
                }
#endif
            }
            else
                applog(LOG_DEBUG, "Profile load failed for pool %i: profile %s not found.", pools[i]->pool_no, pools[i]->profile);
        }
    }
}
