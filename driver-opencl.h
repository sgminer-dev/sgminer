#ifndef DEVICE_GPU_H
#define DEVICE_GPU_H

#include "miner.h"


extern void print_ndevs(int *ndevs);
extern void *reinit_gpu(void *userdata);
extern char *set_gpu_map(char *arg);
extern char *set_gpu_threads(const char *arg);
extern char *set_gpu_engine(const char *arg);
extern char *set_gpu_fan(const char *arg);
extern char *set_gpu_memclock(const char *arg);
extern char *set_gpu_memdiff(char *arg);
extern char *set_gpu_powertune(char *arg);
extern char *set_gpu_vddc(char *arg);
extern char *set_temp_overheat(char *arg);
extern char *set_temp_target(char *arg);
extern char *set_intensity(const char *arg);
extern char *set_xintensity(const char *arg);
extern char *set_rawintensity(const char *arg);
extern char *set_vector(char *arg);
extern char *set_worksize(const char *arg);
extern char *set_shaders(char *arg);
extern char *set_lookup_gap(char *arg);
extern char *set_thread_concurrency(const char *arg);
void manage_gpu(void);
extern void pause_dynamic_threads(int gpu);

extern int opt_platform_id;

extern struct device_drv opencl_drv;

#endif /* DEVICE_GPU_H */
