#include "binary_kernel.h"
#include "miner.h"
#include <sys/stat.h>
#include <stdio.h>

cl_program load_opencl_binary_kernel(build_kernel_data *data)
{
  FILE *binaryfile = NULL;
  size_t binary_size;
  char **binaries = (char **)calloc(MAX_GPUDEVICES * 4, sizeof(char *));
  cl_int status;
  cl_program program;
  cl_program ret = NULL;

  binaryfile = fopen(data->binary_filename, "rb");
  if (!binaryfile) {
    applog(LOG_DEBUG, "No binary found, generating from source");
    goto out;
  } else {
    struct stat binary_stat;

    if (unlikely(stat(data->binary_filename, &binary_stat))) {
      applog(LOG_DEBUG, "Unable to stat binary, generating from source");
      goto out;
    }
    if (!binary_stat.st_size)
      goto out;

    binary_size = binary_stat.st_size;
    binaries[0] = (char *)calloc(binary_size, 1);
    if (unlikely(!binaries[0])) {
      quit(1, "Unable to calloc binaries");
    }

    if (fread(binaries[0], 1, binary_size, binaryfile) != binary_size) {
      applog(LOG_ERR, "Unable to fread binary");
      goto out;
    }

    program = clCreateProgramWithBinary(data->context, 1, data->device, &binary_size, (const unsigned char **)binaries, &status, NULL);
    if (status != CL_SUCCESS) {
      applog(LOG_ERR, "Error %d: Loading Binary into cl_program (clCreateProgramWithBinary)", status);
      goto out;
    }

    applog(LOG_DEBUG, "Loaded binary image %s", data->binary_filename);

    /* create a cl program executable for all the devices specified */
    status = clBuildProgram(program, 1, data->device, NULL, NULL, NULL);
    if (status != CL_SUCCESS) {
      applog(LOG_ERR, "Error %d: Building Program (clBuildProgram)", status);
      size_t log_size;
      status = clGetProgramBuildInfo(program, *data->device, CL_PROGRAM_BUILD_LOG, 0, NULL, &log_size);

      char *sz_log = (char *)malloc(log_size + 1);
      status = clGetProgramBuildInfo(program, *data->device, CL_PROGRAM_BUILD_LOG, log_size, sz_log, NULL);
      sz_log[log_size] = '\0';
      applog(LOG_ERR, "%s", sz_log);
      free(sz_log);
      clReleaseProgram(program);
      goto out;
    }

    ret = program;
  }
out:
  if (binaryfile) fclose(binaryfile);
  if (binaries[0]) free(binaries[0]);
  if (binaries) free(binaries);
  return ret;
}
