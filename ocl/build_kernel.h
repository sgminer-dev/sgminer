#ifndef BUILD_KERNEL_H
#define BUILD_KERNEL_H

#include "ocl.h"
#include <stdbool.h>

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
  bool has_bit_align;
  bool patch_bfi;
  float opencl_version;
} build_kernel_data;

bool needs_bfi_patch(build_kernel_data *data);
cl_program build_opencl_kernel(build_kernel_data *data, const char *filename);
bool save_opencl_kernel(build_kernel_data *data, cl_program program);
void set_base_compiler_options(build_kernel_data *data);
void append_scrypt_compiler_options(build_kernel_data *data, int lookup_gap, unsigned int thread_concurrency, unsigned int nfactor);
void append_hamsi_compiler_options(build_kernel_data *data, int expand_big);

#endif /* BUILD_KERNEL_H */
