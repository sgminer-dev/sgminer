/*
 * Copyright 2011-2012 Con Kolivas
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 3 of the License, or (at your option)
 * any later version.  See COPYING for more details.
 */

#include "config.h"

#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <limits.h>
#include <sys/types.h>

#ifdef WIN32
  #include <winsock2.h>
#else
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <netdb.h>
#endif

#include <time.h>
#include <sys/time.h>
#include <pthread.h>
#include <unistd.h>

#include "findnonce.h"
#include "algorithm.h"
#include "ocl.h"
#include "ocl/build_kernel.h"
#include "ocl/binary_kernel.h"

/* FIXME: only here for global config vars, replace with configuration.h
 * or similar as soon as config is in a struct instead of littered all
 * over the global namespace.
 */
#include "miner.h"

int opt_platform_id = -1;

bool get_opencl_platform(int preferred_platform_id, cl_platform_id *platform) {
  cl_int status;
  cl_uint numPlatforms;
  cl_platform_id *platforms = NULL;
  unsigned int i;
  bool ret = false;

  status = clGetPlatformIDs(0, NULL, &numPlatforms);
  /* If this fails, assume no GPUs. */
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: clGetPlatformsIDs failed (no OpenCL SDK installed?)", status);
    goto out;
  }

  if (numPlatforms == 0) {
    applog(LOG_ERR, "clGetPlatformsIDs returned no platforms (no OpenCL SDK installed?)");
    goto out;
  }

  if (preferred_platform_id >= (int)numPlatforms) {
    applog(LOG_ERR, "Specified platform that does not exist");
    goto out;
  }

  platforms = (cl_platform_id *)malloc(numPlatforms*sizeof(cl_platform_id));
  status = clGetPlatformIDs(numPlatforms, platforms, NULL);
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: Getting Platform Ids. (clGetPlatformsIDs)", status);
    goto out;
  }

  for (i = 0; i < numPlatforms; i++) {
    if (preferred_platform_id >= 0 && (int)i != preferred_platform_id)
      continue;

    *platform = platforms[i];
    ret = true;
    break;
  }
out:
  if (platforms) free(platforms);
  return ret;
}


int clDevicesNum(void) {
  cl_int status;
  char pbuff[256];
  cl_uint numDevices;
  cl_platform_id platform = NULL;
  int ret = -1;

  if (!get_opencl_platform(opt_platform_id, &platform)) {
    goto out;
  }

  status = clGetPlatformInfo(platform, CL_PLATFORM_VENDOR, sizeof(pbuff), pbuff, NULL);
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: Getting Platform Info. (clGetPlatformInfo)", status);
    goto out;
  }

  applog(LOG_INFO, "CL Platform vendor: %s", pbuff);
  status = clGetPlatformInfo(platform, CL_PLATFORM_NAME, sizeof(pbuff), pbuff, NULL);
  if (status == CL_SUCCESS)
    applog(LOG_INFO, "CL Platform name: %s", pbuff);
  status = clGetPlatformInfo(platform, CL_PLATFORM_VERSION, sizeof(pbuff), pbuff, NULL);
  if (status == CL_SUCCESS)
    applog(LOG_INFO, "CL Platform version: %s", pbuff);
  status = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 0, NULL, &numDevices);
  if (status != CL_SUCCESS) {
    applog(LOG_INFO, "Error %d: Getting Device IDs (num)", status);
    goto out;
  }
  applog(LOG_INFO, "Platform devices: %d", numDevices);
  if (numDevices) {
    unsigned int j;
    cl_device_id *devices = (cl_device_id *)malloc(numDevices*sizeof(cl_device_id));

    clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, numDevices, devices, NULL);
    for (j = 0; j < numDevices; j++) {
      clGetDeviceInfo(devices[j], CL_DEVICE_NAME, sizeof(pbuff), pbuff, NULL);
      applog(LOG_INFO, "\t%i\t%s", j, pbuff);
    }
    free(devices);
  }

  ret = numDevices;
out:
  return ret;
}

static cl_int create_opencl_context(cl_context *context, cl_platform_id *platform)
{
  cl_context_properties cps[3] = { CL_CONTEXT_PLATFORM, (cl_context_properties)*platform, 0 };
  cl_int status;

  *context = clCreateContextFromType(cps, CL_DEVICE_TYPE_GPU, NULL, NULL, &status);
  return status;
}

static cl_int create_opencl_command_queue(cl_command_queue *command_queue, cl_context *context, cl_device_id *device, cl_command_queue_properties cq_properties)
{
  cl_int status;
  *command_queue = clCreateCommandQueue(*context, *device,
    cq_properties, &status);
  if (status != CL_SUCCESS) /* Try again without OOE enable */
    *command_queue = clCreateCommandQueue(*context, *device, 0, &status);
  return status;
}

static float get_opencl_version(cl_device_id device)
{
  /* Check for OpenCL >= 1.0 support, needed for global offset parameter usage. */
  char devoclver[1024];
  char *find;
  float version = 1.0;
  cl_int status;

  status = clGetDeviceInfo(device, CL_DEVICE_VERSION, 1024, (void *)devoclver, NULL);
  if (status != CL_SUCCESS) {
    quit(1, "Failed to clGetDeviceInfo when trying to get CL_DEVICE_VERSION");
  }
  find = strstr(devoclver, "OpenCL 1.0");
  if (!find) {
    version = 1.1;
    find = strstr(devoclver, "OpenCL 1.1");
    if (!find)
      version = 1.2;
  }
  return version;
}

static bool get_opencl_bit_align_support(cl_device_id *device)
{
  char extensions[1024];
  const char * camo = "cl_amd_media_ops";
  char *find;
  cl_int status;

  status = clGetDeviceInfo(*device, CL_DEVICE_EXTENSIONS, 1024, (void *)extensions, NULL);
  if (status != CL_SUCCESS) {
    return false;
  }
  find = strstr(extensions, camo);
  return !!find;
}

_clState *initCl(unsigned int gpu, char *name, size_t nameSize, algorithm_t *algorithm)
{
  _clState *clState = (_clState *)calloc(1, sizeof(_clState));
  struct cgpu_info *cgpu = &gpus[gpu];
  cl_platform_id platform = NULL;
  char pbuff[256];
  build_kernel_data *build_data = (build_kernel_data *) alloca(sizeof(struct _build_kernel_data));
  cl_uint preferred_vwidth;
  cl_device_id *devices;
  cl_uint numDevices;
  cl_int status;

  if (!get_opencl_platform(opt_platform_id, &platform)) {
    return NULL;
  }

  numDevices = clDevicesNum();

  if (numDevices <= 0 ) return NULL;

  devices = (cl_device_id *)alloca(numDevices*sizeof(cl_device_id));

  /* Now, get the device list data */

  status = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, numDevices, devices, NULL);
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: Getting Device IDs (list)", status);
    return NULL;
  }

  applog(LOG_INFO, "List of devices:");

  unsigned int i;
  for (i = 0; i < numDevices; i++) {
    status = clGetDeviceInfo(devices[i], CL_DEVICE_NAME, sizeof(pbuff), pbuff, NULL);
    if (status != CL_SUCCESS) {
      applog(LOG_ERR, "Error %d: Getting Device Info", status);
      return NULL;
    }

    applog(LOG_INFO, "\t%i\t%s", i, pbuff);

    if (i == gpu) {
      applog(LOG_INFO, "Selected %i: %s", gpu, pbuff);
      strncpy(name, pbuff, nameSize);
    }
  }

  if (gpu >= numDevices) {
    applog(LOG_ERR, "Invalid GPU %i", gpu);
    return NULL;
  }

  status = create_opencl_context(&clState->context, &platform);
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: Creating Context. (clCreateContextFromType)", status);
    return NULL;
  }

  status = create_opencl_command_queue(&clState->commandQueue, &clState->context, &devices[gpu], cgpu->algorithm.cq_properties);
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: Creating Command Queue. (clCreateCommandQueue)", status);
    return NULL;
  }

  clState->hasBitAlign = get_opencl_bit_align_support(&devices[gpu]);

  status = clGetDeviceInfo(devices[gpu], CL_DEVICE_PREFERRED_VECTOR_WIDTH_INT, sizeof(cl_uint), (void *)&preferred_vwidth, NULL);
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: Failed to clGetDeviceInfo when trying to get CL_DEVICE_PREFERRED_VECTOR_WIDTH_INT", status);
    return NULL;
  }
  applog(LOG_DEBUG, "Preferred vector width reported %d", preferred_vwidth);

  status = clGetDeviceInfo(devices[gpu], CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(size_t), (void *)&clState->max_work_size, NULL);
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: Failed to clGetDeviceInfo when trying to get CL_DEVICE_MAX_WORK_GROUP_SIZE", status);
    return NULL;
  }
  applog(LOG_DEBUG, "Max work group size reported %d", (int)(clState->max_work_size));

  size_t compute_units = 0;
  status = clGetDeviceInfo(devices[gpu], CL_DEVICE_MAX_COMPUTE_UNITS, sizeof(size_t), (void *)&compute_units, NULL);
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: Failed to clGetDeviceInfo when trying to get CL_DEVICE_MAX_COMPUTE_UNITS", status);
    return NULL;
  }
  // AMD architechture got 64 compute shaders per compute unit.
  // Source: http://www.amd.com/us/Documents/GCN_Architecture_whitepaper.pdf
  clState->compute_shaders = compute_units * 64;
  applog(LOG_DEBUG, "Max shaders calculated %d", (int)(clState->compute_shaders));

  status = clGetDeviceInfo(devices[gpu], CL_DEVICE_MAX_MEM_ALLOC_SIZE , sizeof(cl_ulong), (void *)&cgpu->max_alloc, NULL);
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: Failed to clGetDeviceInfo when trying to get CL_DEVICE_MAX_MEM_ALLOC_SIZE", status);
    return NULL;
  }
  applog(LOG_DEBUG, "Max mem alloc size is %lu", (long unsigned int)(cgpu->max_alloc));

  /* Create binary filename based on parameters passed to opencl
   * compiler to ensure we only load a binary that matches what
   * would have otherwise created. The filename is:
   * name + g + lg + lookup_gap + tc + thread_concurrency + nf + nfactor + w + work_size + l + sizeof(long) + .bin
   */
  char filename[255];
  char strbuf[32];

  sprintf(strbuf, "%s.cl", (!empty_string(cgpu->algorithm.kernelfile) ? cgpu->algorithm.kernelfile : cgpu->algorithm.name));
  strcpy(filename, strbuf);
  applog(LOG_DEBUG, "Using source file %s", filename);

  /* For some reason 2 vectors is still better even if the card says
   * otherwise, and many cards lie about their max so use 256 as max
   * unless explicitly set on the command line. Tahiti prefers 1 */
  if (strstr(name, "Tahiti"))
    preferred_vwidth = 1;
  else if (preferred_vwidth > 2)
    preferred_vwidth = 2;

  /* All available kernels only support vector 1 */
  cgpu->vwidth = 1;

  /* Vectors are hard-set to 1 above. */
  if (likely(cgpu->vwidth))
    clState->vwidth = cgpu->vwidth;
  else {
    clState->vwidth = preferred_vwidth;
    cgpu->vwidth = preferred_vwidth;
  }

  clState->goffset = true;

  if (cgpu->work_size && cgpu->work_size <= clState->max_work_size)
    clState->wsize = cgpu->work_size;
  else
    clState->wsize = 256;

  if (!cgpu->opt_lg) {
    applog(LOG_DEBUG, "GPU %d: selecting lookup gap of 2", gpu);
    cgpu->lookup_gap = 2;
  } else
    cgpu->lookup_gap = cgpu->opt_lg;

  if ((strcmp(cgpu->algorithm.name, "zuikkis") == 0) && (cgpu->lookup_gap != 2)) {
    applog(LOG_WARNING, "Kernel zuikkis only supports lookup-gap = 2 (currently %d), forcing.", cgpu->lookup_gap);
    cgpu->lookup_gap = 2;
  }

  if ((strcmp(cgpu->algorithm.name, "bufius") == 0) && ((cgpu->lookup_gap != 2) && (cgpu->lookup_gap != 4) && (cgpu->lookup_gap != 8))) {
    applog(LOG_WARNING, "Kernel bufius only supports lookup-gap of 2, 4 or 8 (currently %d), forcing to 2", cgpu->lookup_gap);
    cgpu->lookup_gap = 2;
  }

  if (!cgpu->opt_tc) {
    unsigned int sixtyfours;

    sixtyfours =  cgpu->max_alloc / 131072 / 64 / (algorithm->n/1024) - 1;
    cgpu->thread_concurrency = sixtyfours * 64;
    if (cgpu->shaders && cgpu->thread_concurrency > cgpu->shaders) {
      cgpu->thread_concurrency -= cgpu->thread_concurrency % cgpu->shaders;
      if (cgpu->thread_concurrency > cgpu->shaders * 5)
        cgpu->thread_concurrency = cgpu->shaders * 5;
    }
    applog(LOG_DEBUG, "GPU %d: selecting thread concurrency of %d", gpu, (int)(cgpu->thread_concurrency));
  } else
    cgpu->thread_concurrency = cgpu->opt_tc;


  cl_uint slot, cpnd;

  slot = cpnd = 0;

  build_data->context = clState->context;
  build_data->device = &devices[gpu];

  // Build information
  strcpy(build_data->source_filename, filename);
  strcpy(build_data->platform, name);
  strcpy(build_data->sgminer_path, sgminer_path);
  if (opt_kernel_path && *opt_kernel_path) {
    build_data->kernel_path = opt_kernel_path;
  }
  else {
    build_data->kernel_path = NULL;
  }

  build_data->work_size = clState->wsize;
  build_data->has_bit_align = clState->hasBitAlign;

  build_data->opencl_version = get_opencl_version(devices[gpu]);
  build_data->patch_bfi = needs_bfi_patch(build_data);

  strcpy(build_data->binary_filename, (!empty_string(cgpu->algorithm.kernelfile) ? cgpu->algorithm.kernelfile : cgpu->algorithm.name));
  strcat(build_data->binary_filename, name);
  if (clState->goffset)
    strcat(build_data->binary_filename, "g");

  set_base_compiler_options(build_data);
  if (algorithm->set_compile_options)
    algorithm->set_compile_options(build_data, cgpu, algorithm);

  strcat(build_data->binary_filename, ".bin");
  applog(LOG_DEBUG, "Using binary file %s", build_data->binary_filename);

  // Load program from file or build it if it doesn't exist
  if (!(clState->program = load_opencl_binary_kernel(build_data))) {
    applog(LOG_NOTICE, "Building binary %s", build_data->binary_filename);

    if (!(clState->program = build_opencl_kernel(build_data, filename)))
      return NULL;

    if (save_opencl_kernel(build_data, clState->program)) {
      /* Program needs to be rebuilt, because the binary was patched */
      if (build_data->patch_bfi) {
        clReleaseProgram(clState->program);
        clState->program = load_opencl_binary_kernel(build_data);
      }
    } else {
      if (build_data->patch_bfi)
        quit(1, "Could not save kernel to file, but it is necessary to apply BFI patch");
    }
  }

  // Load kernels
  applog(LOG_NOTICE, "Initialising kernel %s with%s bitalign, %spatched BFI, nfactor %d, n %d",
         filename, clState->hasBitAlign ? "" : "out", build_data->patch_bfi ? "" : "un",
         algorithm->nfactor, algorithm->n);

  /* get a kernel object handle for a kernel with the given name */
  clState->kernel = clCreateKernel(clState->program, "search", &status);
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: Creating Kernel from program. (clCreateKernel)", status);
    return NULL;
  }


  clState->n_extra_kernels = algorithm->n_extra_kernels;
  if (clState->n_extra_kernels > 0) {
    unsigned int i;
    char kernel_name[9]; // max: search99 + 0x0

    clState->extra_kernels = (cl_kernel *)malloc(sizeof(cl_kernel) * clState->n_extra_kernels);

    for (i = 0; i < clState->n_extra_kernels; i++) {
      snprintf(kernel_name, 9, "%s%d", "search", i + 1);
      clState->extra_kernels[i] = clCreateKernel(clState->program, kernel_name, &status);
      if (status != CL_SUCCESS) {
        applog(LOG_ERR, "Error %d: Creating ExtraKernel #%d from program. (clCreateKernel)", status, i);
        return NULL;
      }
    }
  }

  size_t bufsize;

  if (algorithm->rw_buffer_size < 0) {
    size_t ipt = (algorithm->n / cgpu->lookup_gap +
            (algorithm->n % cgpu->lookup_gap > 0));
    bufsize = 128 * ipt * cgpu->thread_concurrency;
  } else
    bufsize = (size_t) algorithm->rw_buffer_size;

  clState->padbuffer8 = NULL;

  if (bufsize > 0) {
    /* Use the max alloc value which has been rounded to a power of
     * 2 greater >= required amount earlier */
    if (bufsize > cgpu->max_alloc) {
      applog(LOG_WARNING, "Maximum buffer memory device %d supports says %lu",
           gpu, (unsigned long)(cgpu->max_alloc));
      applog(LOG_WARNING, "Your settings come to %lu", (unsigned long)bufsize);
    }
    applog(LOG_DEBUG, "Creating buffer sized %lu", (unsigned long)bufsize);

    /* This buffer is weird and might work to some degree even if
     * the create buffer call has apparently failed, so check if we
     * get anything back before we call it a failure. */
    clState->padbuffer8 = clCreateBuffer(clState->context, CL_MEM_READ_WRITE, bufsize, NULL, &status);
    if (status != CL_SUCCESS && !clState->padbuffer8) {
      applog(LOG_ERR, "Error %d: clCreateBuffer (padbuffer8), decrease TC or increase LG", status);
      return NULL;
    }
  }

  clState->CLbuffer0 = clCreateBuffer(clState->context, CL_MEM_READ_ONLY, 128, NULL, &status);
  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: clCreateBuffer (CLbuffer0)", status);
    return NULL;
  }
  clState->outputBuffer = clCreateBuffer(clState->context, CL_MEM_WRITE_ONLY, BUFFERSIZE, NULL, &status);

  if (status != CL_SUCCESS) {
    applog(LOG_ERR, "Error %d: clCreateBuffer (outputBuffer)", status);
    return NULL;
  }

  return clState;
}

