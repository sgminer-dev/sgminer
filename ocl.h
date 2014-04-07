#ifndef OCL_H
#define OCL_H

#include "config.h"

#include <stdbool.h>
#ifdef __APPLE_CC__
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#endif

#include "miner.h"

typedef struct {
	cl_context context;
	cl_kernel kernel;
	cl_command_queue commandQueue;
	cl_program program;
	cl_mem outputBuffer;
	cl_mem CLbuffer0;
	cl_mem padbuffer8;
	size_t padbufsize;
	void * cldata;
	bool hasBitAlign;
	bool hasOpenCL11plus;
	bool hasOpenCL12plus;
	bool goffset;
	cl_uint vwidth;
	size_t max_work_size;
	size_t wsize;
	size_t compute_shaders;
} _clState;

extern char *file_contents(const char *filename, int *length);
extern int clDevicesNum(void);
extern _clState *initCl(unsigned int gpu, char *name, size_t nameSize, algorithm_t *algorithm);

#endif /* OCL_H */
