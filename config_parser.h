#ifndef CONFIG_PARSER_H
#define CONFIG_PARSER_H

#include "config.h"

#include "miner.h"
#include "api.h"
#include "algorithm.h"

//helper to check for empty or NULL strings
#ifndef empty_string
  #define empty_string(str) ((str && str[0] != '\0')?0:1)
#endif
#ifndef safe_cmp
  #define safe_cmp(val1, val2) (((val1 && strcmp(val1, val2) != 0) || empty_string(val1))?1:0)
#endif

//helper function to get a gpu option value
#ifndef gpu_opt
  #define gpu_opt(i,optname) gpus[i].optname
#endif

//profile structure
struct profile {
  int profile_no;
  char *name;
  bool removed;

  algorithm_t algorithm;
  const char *devices;
  const char *intensity;
  const char *xintensity;
  const char *rawintensity;
  const char *lookup_gap;
  const char *gpu_engine;
  const char *gpu_memclock;
  const char *gpu_threads;
  const char *gpu_fan;
  const char *gpu_powertune;
  const char *gpu_vddc;
  const char *shaders;
  const char *thread_concurrency;
  const char *worksize;
};

/* globals needed outside */
extern char *cnfbuf;
extern int fileconf_load;
extern const char def_conf[];
extern char *default_config;
extern bool config_loaded;

extern int json_array_index;

extern struct profile default_profile;
extern struct profile **profiles;
extern int total_profiles;

/* option parser functions */
extern char *set_default_devices(const char *arg);
extern char *set_default_lookup_gap(const char *arg);
extern char *set_default_intensity(const char *arg);
extern char *set_default_xintensity(const char *arg);
extern char *set_default_rawintensity(const char *arg);
extern char *set_default_thread_concurrency(const char *arg);
#ifdef HAVE_ADL
  extern char *set_default_gpu_engine(const char *arg);
  extern char *set_default_gpu_memclock(const char *arg);
  extern char *set_default_gpu_threads(const char *arg);
  extern char *set_default_gpu_fan(const char *arg);
  extern char *set_default_gpu_powertune(const char *arg);
  extern char *set_default_gpu_vddc(const char *arg);
#endif
extern char *set_default_profile(char *arg);
extern char *set_default_shaders(const char *arg);
extern char *set_default_worksize(const char *arg);

extern char *set_profile_name(const char *arg);
extern char *set_profile_algorithm(const char *arg);
extern char *set_profile_devices(const char *arg);
extern char *set_profile_lookup_gap(const char *arg);
extern char *set_profile_intensity(const char *arg);
extern char *set_profile_xintensity(const char *arg);
extern char *set_profile_rawintensity(const char *arg);
extern char *set_profile_thread_concurrency(const char *arg);
#ifdef HAVE_ADL
  extern char *set_profile_gpu_engine(const char *arg);
  extern char *set_profile_gpu_memclock(const char *arg);
  extern char *set_profile_gpu_threads(const char *arg);
  extern char *set_profile_gpu_fan(const char *arg);
  extern char *set_profile_gpu_powertune(const char *arg);
  extern char *set_profile_gpu_vddc(const char *arg);
#endif
extern char *set_profile_nfactor(const char *arg);
extern char *set_profile_shaders(const char *arg);
extern char *set_profile_worksize(const char *arg);

/* config parser functions */
extern char *parse_config(json_t *val, const char *key, const char *parentkey, bool fileconf, int parent_iteration);
extern char *load_config(const char *arg, const char *parentkey, void __maybe_unused *unused);
extern char *set_default_config(const char *arg);
extern void load_default_config(void);

/* startup functions */
extern void load_default_profile();
extern void apply_defaults();
extern void apply_pool_profiles();
extern void apply_pool_profile(struct pool *pool);

/* config writer */
extern void write_config(const char *filename);

/* API functions */
extern void api_profile_list(struct io_data *io_data, __maybe_unused SOCKETTYPE c, __maybe_unused char *param, bool isjson, __maybe_unused char group);
extern void api_profile_add(struct io_data *io_data, __maybe_unused SOCKETTYPE c, char *param, bool isjson, __maybe_unused char group);
extern void api_profile_remove(struct io_data *io_data, __maybe_unused SOCKETTYPE c, char *param, bool isjson, __maybe_unused char group);

#endif // CONFIG_PARSER_H
