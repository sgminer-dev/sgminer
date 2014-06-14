#ifndef CONFIG_PARSER_H
#define CONFIG_PARSER_H

#include "config.h"

#include "miner.h"
#include "algorithm.h"

//helper to check for empty or NULL strings
#ifndef empty_string
    #define empty_string(str) ((str && str[0] != '\0')?0:1)
#endif

//profile structure
struct profile {
	int profile_no;
	char *name;

	algorithm_t algorithm;
	const char *intensity;
	const char *xintensity;
	const char *rawintensity;
	const char *thread_concurrency;
	const char *gpu_engine;
	const char *gpu_memclock;
	const char *gpu_threads;
	const char *gpu_fan;
};

/* globals needed outside */
extern char *cnfbuf;
extern int fileconf_load;
extern const char def_conf[];
extern char *default_config;
extern bool config_loaded;

extern int json_array_index;

extern struct profile default_profile;

/* option parser functions */
extern char *set_default_intensity(const char *arg);
extern char *set_default_xintensity(const char *arg);
extern char *set_default_rawintensity(const char *arg);
extern char *set_default_thread_concurrency(const char *arg);
#ifdef HAVE_ADL
	extern char *set_default_gpu_engine(const char *arg);
	extern char *set_default_gpu_memclock(const char *arg);
	extern char *set_default_gpu_threads(const char *arg);
    extern char *set_default_gpu_fan(const char *arg);
#endif
extern char *set_default_profile(char *arg);

extern char *set_profile_name(char *arg);
extern char *set_profile_algorithm(const char *arg);
extern char *set_profile_intensity(const char *arg);
extern char *set_profile_xintensity(const char *arg);
extern char *set_profile_rawintensity(const char *arg);
extern char *set_profile_thread_concurrency(const char *arg);
#ifdef HAVE_ADL
	extern char *set_profile_gpu_engine(const char *arg);
    extern char *set_profile_gpu_memclock(const char *arg);
    extern char *set_profile_gpu_threads(const char *arg);
    extern char *set_profile_gpu_fan(const char *arg);
#endif
extern char *set_profile_nfactor(const char *arg);

/* helpers */
//void set_last_json_error(const char *fmt, ...);
//struct opt_table *opt_find(struct opt_table *tbl, char *optname);

/* config parser functions */
//void parse_config_object(json_t *obj, const char *parentkey, bool fileconf, int parent_iteration);
//char *parse_config_array(json_t *obj, char *parentkey, bool fileconf);
extern char *parse_config(json_t *val, const char *key, const char *parentkey, bool fileconf, int parent_iteration);
extern char *load_config(const char *arg, const char *parentkey, void __maybe_unused *unused);
extern char *set_default_config(const char *arg);
extern void load_default_config(void);

/*struct profile *add_profile();
struct profile *get_current_profile();
struct profile *get_profile(char *name);*/

extern void load_default_profile();
extern void apply_defaults();
extern void apply_pool_profiles();

#endif // CONFIG_PARSER_H
