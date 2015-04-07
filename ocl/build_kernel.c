#include <stdio.h>
#include "build_kernel.h"
#include "miner.h"

static char *file_contents(const char *filename, int *length)
{
  char *fullpath = (char *)alloca(PATH_MAX);
  void *buffer;
  FILE *f = NULL;

  if (opt_kernel_path && *opt_kernel_path) {
    /* Try in the optional kernel path first, defaults to PREFIX */
    snprintf(fullpath, PATH_MAX, "%s/%s", opt_kernel_path, filename);
    applog(LOG_DEBUG, "Trying to open %s...", fullpath);
    f = fopen(fullpath, "rb");
  }
  if (!f) {
    /* Then try from the path sgminer was called */
    snprintf(fullpath, PATH_MAX, "%s/%s", sgminer_path, filename);
    applog(LOG_DEBUG, "Trying to open %s...", fullpath);
    f = fopen(fullpath, "rb");
  }
  if (!f) {
    /* Then from `pwd`/kernel/ */
    snprintf(fullpath, PATH_MAX, "%s/kernel/%s", sgminer_path, filename);
    applog(LOG_DEBUG, "Trying to open %s...", fullpath);
    f = fopen(fullpath, "rb");
  }
  /* Finally try opening it directly */
  if (!f) {
    applog(LOG_DEBUG, "Trying to open %s...", fullpath);
    f = fopen(filename, "rb");
  }

  if (!f) {
    applog(LOG_ERR, "Unable to open %s for reading!", filename);
    return NULL;
  }

  applog(LOG_DEBUG, "Using %s", fullpath);

  fseek(f, 0, SEEK_END);
  *length = ftell(f);
  fseek(f, 0, SEEK_SET);

  buffer = malloc(*length+1);
  *length = fread(buffer, 1, *length, f);
  fclose(f);
  ((char*)buffer)[*length] = '\0';

  return (char*)buffer;
}

// This should NOT be in here! -- Wolf9466
void set_base_compiler_options(build_kernel_data *data)
{
  char buf[255];
  sprintf(data->compiler_options, "-I \"%s\" -I \"%s/kernel\" -I \".\" -D WORKSIZE=%d",
      data->sgminer_path, data->sgminer_path, (int)data->work_size);
  applog(LOG_DEBUG, "Setting worksize to %d", (int)(data->work_size));

  sprintf(buf, "w%dl%d", (int)data->work_size, (int)sizeof(long));
  strcat(data->binary_filename, buf);
  
  if (data->kernel_path) {
    strcat(data->compiler_options, " -I \"");
    strcat(data->compiler_options, data->kernel_path);
    strcat(data->compiler_options, "\"");
  }

  if (data->opencl_version < 1.1)
    strcat(data->compiler_options, " -D OCL1");
}

cl_program build_opencl_kernel(build_kernel_data *data, const char *filename)
{
  int pl;
  char *source = file_contents(data->source_filename, &pl);
  size_t sourceSize[] = {(size_t)pl};
  cl_int status;
  cl_program program = NULL;
  cl_program ret = NULL;

  if (!source)
    goto out;

  program = clCreateProgramWithSource(data->context, 1, (const char **)&source, sourceSize, &status);
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: Loading Binary into cl_program (clCreateProgramWithSource)", status);
    goto out;
  }

  applog(LOG_DEBUG, "CompilerOptions: %s", data->compiler_options);
  status = clBuildProgram(program, 1, data->device, data->compiler_options, NULL, NULL);

  if (status != CL_SUCCESS) {
    size_t log_size;
    applog(LOG_ERR, "Error %d: Building Program (clBuildProgram)", status);
    status = clGetProgramBuildInfo(program, *data->device, CL_PROGRAM_BUILD_LOG, 0, NULL, &log_size);

    char *sz_log = (char *)malloc(log_size + 1);
    status = clGetProgramBuildInfo(program, *data->device, CL_PROGRAM_BUILD_LOG, log_size, sz_log, NULL);
    sz_log[log_size] = '\0';
    applogsiz(LOG_ERR, log_size, "%s", sz_log);
    free(sz_log);
    goto out;
  }

  ret = program;
out:
  if (source) free(source);
  return ret;
}

bool save_opencl_kernel(build_kernel_data *data, cl_program program)
{
  cl_uint slot, cpnd = 0;
  size_t *binary_sizes = (size_t *)calloc(MAX_GPUDEVICES * 4, sizeof(size_t));
  char **binaries = NULL;
  cl_int status;
  FILE *binaryfile;
  bool ret = false;

  #ifdef __APPLE__
    /* OSX OpenCL breaks reading off binaries with >1 GPU so always build
     * from source. */
    goto out;
  #endif

  status = clGetProgramInfo(program, CL_PROGRAM_NUM_DEVICES, sizeof(cl_uint), &cpnd, NULL);
  if (unlikely(status != CL_SUCCESS)) {
    applog(LOG_ERR, "Error %d: Getting program info CL_PROGRAM_NUM_DEVICES. (clGetProgramInfo)", status);
    goto out;
  }

  status = clGetProgramInfo(program, CL_PROGRAM_BINARY_SIZES, sizeof(size_t)*cpnd, binary_sizes, NULL);
  if (unlikely(status != CL_SUCCESS)) {
    applog(LOG_ERR, "Error %d: Getting program info CL_PROGRAM_BINARY_SIZES. (clGetProgramInfo)", status);
    goto out;
  }

  binaries = (char **)calloc(MAX_GPUDEVICES * 4, sizeof(char *));
  for (slot = 0; slot < cpnd; slot++)
    if (binary_sizes[slot])
      binaries[slot] = (char *)calloc(binary_sizes[slot], 1);

  status = clGetProgramInfo(program, CL_PROGRAM_BINARIES, sizeof(char *) * cpnd, binaries, NULL );
  if (unlikely(status != CL_SUCCESS)) {
    applog(LOG_ERR, "Error %d: Getting program info. CL_PROGRAM_BINARIES (clGetProgramInfo)", status);
    goto out;
  }

  /* The actual compiled binary ends up in a RANDOM slot! Grr, so we have
   * to iterate over all the binary slots and find where the real program
   * is. What the heck is this!? */
  for (slot = 0; slot < cpnd; slot++)
    if (binary_sizes[slot])
      break;

  /* copy over all of the generated binaries. */
  applog(LOG_DEBUG, "Binary size found in binary slot %d: %d", slot, (int)(binary_sizes[slot]));
  if (!binary_sizes[slot]) {
    applog(LOG_ERR, "OpenCL compiler generated a zero sized binary!");
    goto out;
  }

  /* Save the binary to be loaded next time */
  binaryfile = fopen(data->binary_filename, "wb");
  if (!binaryfile) {
    /* Not fatal, just means we build it again next time */
    applog(LOG_DEBUG, "Unable to create file %s", data->binary_filename);
    goto out;
  } else {
    if (unlikely(fwrite(binaries[slot], 1, binary_sizes[slot], binaryfile) != binary_sizes[slot])) {
      applog(LOG_ERR, "Unable to fwrite to binaryfile");
      goto out;
    }
    fclose(binaryfile);
  }

  ret = true;
out:
  for (slot = 0; slot < cpnd; slot++)
    if (binary_sizes[slot])
      free(binaries[slot]);
  if (binaries) free(binaries);
  free(binary_sizes);

  return ret;
}
