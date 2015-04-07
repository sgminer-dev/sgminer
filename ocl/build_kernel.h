#ifndef BUILD_KERNEL_H
#define BUILD_KERNEL_H

#include <stdbool.h>
#include "logging.h"

#ifdef __APPLE_CC__
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#endif

typedef struct _build_kernel_data {
  char source_filename[255];
  char binary_filename[255];
  char compiler_options[512];

  cl_context context;
  cl_device_id *device;

// for compiler options
  char platform[64];
  char sgminer_path[255];
  const char *kernel_path;
  size_t work_size;
  float opencl_version;
} build_kernel_data;

cl_program build_opencl_kernel(build_kernel_data *data, const char *filename);
bool save_opencl_kernel(build_kernel_data *data, cl_program program);
void set_base_compiler_options(build_kernel_data *data);

#endif /* BUILD_KERNEL_H */
