#ifndef OCL_H
#define OCL_H

#include "config.h"

#include <stdbool.h>
#ifdef __APPLE_CC__
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#endif

#include "algorithm.h"

typedef struct __clState {
  cl_context context;
  cl_kernel kernel;
  cl_kernel *extra_kernels;
  size_t n_extra_kernels;
  cl_command_queue commandQueue;
  cl_program program;
  cl_mem outputBuffer;
  cl_mem CLbuffer0;
  cl_mem MidstateBuf;
  cl_mem padbuffer8;
  unsigned char cldata[80];
  bool hasBitAlign;
  bool goffset;
  cl_uint vwidth;
  size_t max_work_size;
  size_t wsize;
  size_t compute_shaders;
} _clState;

extern int clDevicesNum(void);
extern _clState *initCl(unsigned int gpu, char *name, size_t nameSize, algorithm_t *algorithm);

#endif /* OCL_H */
