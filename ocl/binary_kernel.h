#ifndef BINARY_KERNEL_H
#define BINARY_KERNEL_H

#ifdef __APPLE_CC__
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#endif

#include "build_kernel.h"

cl_program load_opencl_binary_kernel(build_kernel_data *data);

#endif /* BINARY_KERNEL_H */
