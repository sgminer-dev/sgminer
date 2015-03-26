/*
 * Copyright 2014 sgminer developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or (at
 * your option) any later version.  See COPYING for more details.
 */

#include "algorithm.h"
#include "sph/sph_sha2.h"
#include "ocl.h"
#include "ocl/build_kernel.h"

#include "algorithm/scrypt.h"
#include "algorithm/animecoin.h"
#include "algorithm/inkcoin.h"
#include "algorithm/quarkcoin.h"
#include "algorithm/qubitcoin.h"
#include "algorithm/sifcoin.h"
#include "algorithm/darkcoin.h"
#include "algorithm/myriadcoin-groestl.h"
#include "algorithm/fuguecoin.h"
#include "algorithm/groestlcoin.h"
#include "algorithm/twecoin.h"
#include "algorithm/marucoin.h"
#include "algorithm/maxcoin.h"
#include "algorithm/talkcoin.h"
#include "algorithm/bitblock.h"
#include "algorithm/x14.h"
#include "algorithm/fresh.h"
#include "algorithm/whirlcoin.h"
#include "algorithm/neoscrypt.h"
#include "algorithm/whirlpoolx.h"
#include "algorithm/lyra2re.h"
#include "algorithm/pluck.h"

#include "compat.h"

#include <inttypes.h>
#include <string.h>

const char *algorithm_type_str[] = {
  "Unknown",
  "Scrypt",
  "NScrypt",
  "X11",
  "X13",
  "X14",
  "X15",
  "Keccak",
  "Quarkcoin",
  "Twecoin",
  "Fugue256",
  "NIST",
  "Fresh",
  "Whirlcoin",
  "Neoscrypt",
  "WhirlpoolX",
  "Lyra2RE",
  "Pluck"
};

void sha256(const unsigned char *message, unsigned int len, unsigned char *digest)
{
  sph_sha256_context ctx_sha2;

  sph_sha256_init(&ctx_sha2);
  sph_sha256(&ctx_sha2, message, len);
  sph_sha256_close(&ctx_sha2, (void*)digest);
}

void gen_hash(const unsigned char *data, unsigned int len, unsigned char *hash)
{
  unsigned char hash1[32];
  sph_sha256_context ctx_sha2;

  sph_sha256_init(&ctx_sha2);
  sph_sha256(&ctx_sha2, data, len);
  sph_sha256_close(&ctx_sha2, hash1);
  sph_sha256(&ctx_sha2, hash1, 32);
  sph_sha256_close(&ctx_sha2, hash);
}

#define CL_SET_BLKARG(blkvar) status |= clSetKernelArg(*kernel, num++, sizeof(uint), (void *)&blk->blkvar)
#define CL_SET_VARG(args, var) status |= clSetKernelArg(*kernel, num++, args * sizeof(uint), (void *)var)
#define CL_SET_ARG_N(n, var) do { status |= clSetKernelArg(*kernel, n, sizeof(var), (void *)&var); } while (0)
#define CL_SET_ARG_0(var) CL_SET_ARG_N(0, var)
#define CL_SET_ARG(var) CL_SET_ARG_N(num++, var)
#define CL_NEXTKERNEL_SET_ARG_N(n, var) do { kernel++; CL_SET_ARG_N(n, var); } while (0)
#define CL_NEXTKERNEL_SET_ARG_0(var) CL_NEXTKERNEL_SET_ARG_N(0, var)
#define CL_NEXTKERNEL_SET_ARG(var) CL_NEXTKERNEL_SET_ARG_N(num++, var)

static void append_scrypt_compiler_options(struct _build_kernel_data *data, struct cgpu_info *cgpu, struct _algorithm_t *algorithm)
{
  char buf[255];
  sprintf(buf, " -D LOOKUP_GAP=%d -D CONCURRENT_THREADS=%u -D NFACTOR=%d",
    cgpu->lookup_gap, (unsigned int)cgpu->thread_concurrency, algorithm->nfactor);
  strcat(data->compiler_options, buf);

  sprintf(buf, "lg%utc%unf%u", cgpu->lookup_gap, (unsigned int)cgpu->thread_concurrency, algorithm->nfactor);
  strcat(data->binary_filename, buf);
}

static void append_neoscrypt_compiler_options(struct _build_kernel_data *data, struct cgpu_info *cgpu, struct _algorithm_t *algorithm)
{
  char buf[255];
  sprintf(buf, " %s-D MAX_GLOBAL_THREADS=%lu ",
    ((cgpu->lookup_gap > 0) ? " -D LOOKUP_GAP=2 " : ""), (unsigned long)cgpu->thread_concurrency);
  strcat(data->compiler_options, buf);

  sprintf(buf, "%stc%lu", ((cgpu->lookup_gap > 0) ? "lg" : ""), (unsigned long)cgpu->thread_concurrency);
  strcat(data->binary_filename, buf);
}

static void append_x11_compiler_options(struct _build_kernel_data *data, struct cgpu_info *cgpu, struct _algorithm_t *algorithm)
{
  char buf[255];
  sprintf(buf, " -D SPH_COMPACT_BLAKE_64=%d -D SPH_LUFFA_PARALLEL=%d -D SPH_KECCAK_UNROLL=%u ",
    ((opt_blake_compact) ? 1 : 0), ((opt_luffa_parallel) ? 1 : 0), (unsigned int)opt_keccak_unroll);
  strcat(data->compiler_options, buf);

  sprintf(buf, "ku%u%s%s", (unsigned int)opt_keccak_unroll, ((opt_blake_compact) ? "bc" : ""), ((opt_luffa_parallel) ? "lp" : ""));
  strcat(data->binary_filename, buf);
}


static void append_x13_compiler_options(struct _build_kernel_data *data, struct cgpu_info *cgpu, struct _algorithm_t *algorithm)
{
  char buf[255];

  append_x11_compiler_options(data, cgpu, algorithm);

  sprintf(buf, " -D SPH_HAMSI_EXPAND_BIG=%d -D SPH_HAMSI_SHORT=%d ",
    (unsigned int)opt_hamsi_expand_big, ((opt_hamsi_short) ? 1 : 0));
  strcat(data->compiler_options, buf);

  sprintf(buf, "big%u%s", (unsigned int)opt_hamsi_expand_big, ((opt_hamsi_short) ? "hs" : ""));
  strcat(data->binary_filename, buf);
}

static cl_int queue_scrypt_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  unsigned char *midstate = blk->work->midstate;
  cl_kernel *kernel = &clState->kernel;
  unsigned int num = 0;
  cl_uint le_target;
  cl_int status = 0;

  le_target = *(cl_uint *)(blk->work->device_target + 28);
  memcpy(clState->cldata, blk->work->data, 80);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(clState->padbuffer8);
  CL_SET_VARG(4, &midstate[0]);
  CL_SET_VARG(4, &midstate[16]);
  CL_SET_ARG(le_target);

  return status;
}

static cl_int queue_neoscrypt_kernel(_clState *clState, dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel = &clState->kernel;
  unsigned int num = 0;
  cl_uint le_target;
  cl_int status = 0;

  /* This looks like a unnecessary double cast, but to make sure, that
   * the target's most significant entry is adressed as a 32-bit value
   * and not accidently by something else the double cast seems wise.
   * The compiler will get rid of it anyway. */
  le_target = (cl_uint)le32toh(((uint32_t *)blk->work->/*device_*/target)[7]);
  memcpy(clState->cldata, blk->work->data, 80);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(le_target);

  return status;
}

static cl_int queue_maxcoin_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel = &clState->kernel;
  unsigned int num = 0;
  cl_int status = 0;

  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->outputBuffer);

  return status;
}

static cl_int queue_sph_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel = &clState->kernel;
  unsigned int num = 0;
  cl_ulong le_target;
  cl_int status = 0;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(le_target);

  return status;
}

static cl_int queue_darkcoin_mod_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel;
  unsigned int num;
  cl_ulong le_target;
  cl_int status = 0;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  // blake - search
  kernel = &clState->kernel;
  num = 0;
  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->padbuffer8);
  // bmw - search1
  kernel = clState->extra_kernels;
  CL_SET_ARG_0(clState->padbuffer8);
  // groestl - search2
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // skein - search3
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // jh - search4
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // keccak - search5
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // luffa - search6
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // cubehash - search7
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // shavite - search8
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // simd - search9
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // echo - search10
  num = 0;
  CL_NEXTKERNEL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(le_target);

  return status;
}

static cl_int queue_bitblock_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel;
  unsigned int num;
  cl_ulong le_target;
  cl_int status = 0;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  // blake - search
  kernel = &clState->kernel;
  num = 0;
  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->padbuffer8);
  // bmw - search1
  kernel = clState->extra_kernels;
  CL_SET_ARG_0(clState->padbuffer8);
  // groestl - search2
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // skein - search3
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // jh - search4
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // keccak - search5
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // luffa - search6
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // cubehash - search7
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // shavite - search8
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // simd - search9
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // echo - search10
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // hamsi - search11
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // fugue - search12
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // hamsi - search11
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // fugue - search12
  num = 0;
  CL_NEXTKERNEL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(le_target);

  return status;
}

static cl_int queue_bitblockold_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel;
  unsigned int num;
  cl_ulong le_target;
  cl_int status = 0;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  // blake - search
  kernel = &clState->kernel;
  num = 0;
  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->padbuffer8);
  // bmw - search1
  kernel = clState->extra_kernels;
  CL_SET_ARG_0(clState->padbuffer8);
  // groestl - search2
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // skein - search3
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // jh - search4
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // keccak - search5
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // luffa - search6
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // cubehash - search7
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // shavite - search8
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // simd - search9
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // combined echo, hamsi, fugue - shabal - whirlpool - search10
  num = 0;
  CL_NEXTKERNEL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(le_target);

  return status;
}


static cl_int queue_marucoin_mod_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel;
  unsigned int num;
  cl_ulong le_target;
  cl_int status = 0;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  // blake - search
  kernel = &clState->kernel;
  num = 0;
  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->padbuffer8);
  // bmw - search1
  kernel = clState->extra_kernels;
  CL_SET_ARG_0(clState->padbuffer8);
  // groestl - search2
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // skein - search3
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // jh - search4
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // keccak - search5
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // luffa - search6
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // cubehash - search7
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // shavite - search8
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // simd - search9
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // echo - search10
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // hamsi - search11
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // fugue - search12
  num = 0;
  CL_NEXTKERNEL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(le_target);

  return status;
}

static cl_int queue_marucoin_mod_old_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel;
  unsigned int num;
  cl_ulong le_target;
  cl_int status = 0;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  // blake - search
  kernel = &clState->kernel;
  num = 0;
  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->padbuffer8);
  // bmw - search1
  kernel = clState->extra_kernels;
  CL_SET_ARG_0(clState->padbuffer8);
  // groestl - search2
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // skein - search3
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // jh - search4
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // keccak - search5
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // luffa - search6
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // cubehash - search7
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // shavite - search8
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // simd - search9
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // combined echo, hamsi, fugue - search10
  num = 0;
  CL_NEXTKERNEL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(le_target);

  return status;
}

static cl_int queue_talkcoin_mod_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel;
  unsigned int num;
  cl_ulong le_target;
  cl_int status = 0;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  // blake - search
  kernel = &clState->kernel;
  num = 0;
  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->padbuffer8);
  // groestl - search1
  kernel = clState->extra_kernels;
  CL_SET_ARG_0(clState->padbuffer8);
  // jh - search2
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // keccak - search3
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // skein - search4
  num = 0;
  CL_NEXTKERNEL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(le_target);

  return status;
}

static cl_int queue_x14_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel;
  unsigned int num;
  cl_ulong le_target;
  cl_int status = 0;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  // blake - search
  kernel = &clState->kernel;
  num = 0;
  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->padbuffer8);
  // bmw - search1
  kernel = clState->extra_kernels;
  CL_SET_ARG_0(clState->padbuffer8);
  // groestl - search2
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // skein - search3
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // jh - search4
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // keccak - search5
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // luffa - search6
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // cubehash - search7
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // shavite - search8
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // simd - search9
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // echo - search10
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // hamsi - search11
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // fugue - search12
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // shabal - search13
  num = 0;
  CL_NEXTKERNEL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(le_target);

  return status;
}

static cl_int queue_x14_old_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel;
  unsigned int num;
  cl_ulong le_target;
  cl_int status = 0;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  // blake - search
  kernel = &clState->kernel;
  num = 0;
  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->padbuffer8);
  // bmw - search1
  kernel = clState->extra_kernels;
  CL_SET_ARG_0(clState->padbuffer8);
  // groestl - search2
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // skein - search3
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // jh - search4
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // keccak - search5
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // luffa - search6
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // cubehash - search7
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // shavite - search8
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // simd - search9
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // combined echo, hamsi, fugue - shabal - search10
  num = 0;
  CL_NEXTKERNEL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(le_target);

  return status;
}

static cl_int queue_fresh_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel;
  unsigned int num;
  cl_ulong le_target;
  cl_int status = 0;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  // shavite 1 - search
  kernel = &clState->kernel;
  num = 0;
  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->padbuffer8);
  // smid 1 - search1
  kernel = clState->extra_kernels;
  CL_SET_ARG_0(clState->padbuffer8);
  // shavite 2 - search2
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // smid 2 - search3
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // echo - search4
  num = 0;
  CL_NEXTKERNEL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(le_target);

  return status;
}

static cl_int queue_whirlcoin_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel;
  cl_ulong le_target;
  cl_int status = 0;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  //clbuffer, hashes
  kernel = &clState->kernel;
  CL_SET_ARG_N(0, clState->CLbuffer0);
  CL_SET_ARG_N(1, clState->padbuffer8);

  kernel = clState->extra_kernels;
  CL_SET_ARG_N(0, clState->padbuffer8);

  CL_NEXTKERNEL_SET_ARG_N(0, clState->padbuffer8);

  //hashes, output, target
  CL_NEXTKERNEL_SET_ARG_N(0, clState->padbuffer8);
  CL_SET_ARG_N(1, clState->outputBuffer);
  CL_SET_ARG_N(2, le_target);

  return status;
}

static cl_int queue_whirlpoolx_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  uint64_t midblock[8], key[8] = { 0 }, tmp[8] = { 0 };
  cl_ulong le_target;
  cl_int status;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);

  memcpy(midblock, clState->cldata, 64);

  // midblock = n, key = h
  for (int i = 0; i < 10; ++i) {
    tmp[0] = WHIRLPOOL_ROUND_CONSTANTS[i];
    whirlpool_round(key, tmp);
    tmp[0] = 0;
    whirlpool_round(midblock, tmp);

    for (int x = 0; x < 8; ++x) {
      midblock[x] ^= key[x];
    }
  }

  for (int i = 0; i < 8; ++i) {
    midblock[i] ^= ((uint64_t *)(clState->cldata))[i];
  }

  status = clSetKernelArg(clState->kernel, 0, sizeof(cl_ulong8), (cl_ulong8 *)&midblock);
  status |= clSetKernelArg(clState->kernel, 1, sizeof(cl_ulong), (void *)(((uint64_t *)clState->cldata) + 8));
  status |= clSetKernelArg(clState->kernel, 2, sizeof(cl_ulong), (void *)(((uint64_t *)clState->cldata) + 9));
  status |= clSetKernelArg(clState->kernel, 3, sizeof(cl_mem), (void *)&clState->outputBuffer);
  status |= clSetKernelArg(clState->kernel, 4, sizeof(cl_ulong), (void *)&le_target);

  return status;
}

static cl_int queue_lyra2RE_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel;
  unsigned int num;
  cl_int status = 0;
  cl_ulong le_target;

  le_target = *(cl_ulong *)(blk->work->device_target + 24);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  // blake - search
  kernel = &clState->kernel;
  num = 0;

  CL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(blk->work->blk.ctx_a);
  CL_SET_ARG(blk->work->blk.ctx_b);
  CL_SET_ARG(blk->work->blk.ctx_c);
  CL_SET_ARG(blk->work->blk.ctx_d);
  CL_SET_ARG(blk->work->blk.ctx_e);
  CL_SET_ARG(blk->work->blk.ctx_f);
  CL_SET_ARG(blk->work->blk.ctx_g);
  CL_SET_ARG(blk->work->blk.ctx_h);
  CL_SET_ARG(blk->work->blk.cty_a);
  CL_SET_ARG(blk->work->blk.cty_b);
  CL_SET_ARG(blk->work->blk.cty_c);

  // bmw - search1
  kernel = clState->extra_kernels;
  CL_SET_ARG_0(clState->padbuffer8);
  // groestl - search2
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // skein - search3
  CL_NEXTKERNEL_SET_ARG_0(clState->padbuffer8);
  // jh - search4
  num = 0;
  CL_NEXTKERNEL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(le_target);

  return status;
}

static cl_int queue_pluck_kernel(_clState *clState, dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
  cl_kernel *kernel = &clState->kernel;
  unsigned int num = 0;
  cl_uint le_target;
  cl_int status = 0;

  le_target = (cl_uint)le32toh(((uint32_t *)blk->work->/*device_*/target)[7]);
  flip80(clState->cldata, blk->work->data);
  status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL, NULL);

  CL_SET_ARG(clState->CLbuffer0);
  CL_SET_ARG(clState->outputBuffer);
  CL_SET_ARG(clState->padbuffer8);
  CL_SET_ARG(le_target);

  return status;
}

static algorithm_settings_t algos[] = {
  // kernels starting from this will have difficulty calculated by using litecoin algorithm
#define A_SCRYPT(a) \
  { a, ALGO_SCRYPT, "", 1, 65536, 65536, 0, 0, 0xFF, 0xFFFFFFFFULL, 0x0000ffffUL, 0, -1, CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, scrypt_regenhash, queue_scrypt_kernel, gen_hash, append_scrypt_compiler_options }
  A_SCRYPT("ckolivas"),
  A_SCRYPT("alexkarnew"),
  A_SCRYPT("alexkarnold"),
  A_SCRYPT("bufius"),
  A_SCRYPT("psw"),
  A_SCRYPT("zuikkis"),
  A_SCRYPT("arebyp"),
#undef A_SCRYPT

#define A_NEOSCRYPT(a) \
  { a, ALGO_NEOSCRYPT, "", 1, 65536, 65536, 0, 0, 0xFF, 0xFFFF000000000000ULL, 0x0000ffffUL, 0, -1, CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, neoscrypt_regenhash, queue_neoscrypt_kernel, gen_hash, append_neoscrypt_compiler_options }
  A_NEOSCRYPT("neoscrypt"),
#undef A_NEOSCRYPT

#define A_PLUCK(a) \
  { a, ALGO_PLUCK, "", 1, 65536, 65536, 0, 0, 0xFF, 0xFFFF000000000000ULL, 0x0000ffffUL, 0, -1, CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, pluck_regenhash, queue_pluck_kernel, gen_hash, append_neoscrypt_compiler_options }
  A_PLUCK("pluck"),
#undef A_PLUCK
  // kernels starting from this will have difficulty calculated by using quarkcoin algorithm
#define A_QUARK(a, b) \
  { a, ALGO_QUARK, "", 256, 256, 256, 0, 0, 0xFF, 0xFFFFFFULL, 0x0000ffffUL, 0, 0, CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, b, queue_sph_kernel, gen_hash, append_x11_compiler_options }
  A_QUARK("quarkcoin", quarkcoin_regenhash),
  A_QUARK("qubitcoin", qubitcoin_regenhash),
  A_QUARK("animecoin", animecoin_regenhash),
  A_QUARK("sifcoin", sifcoin_regenhash),
#undef A_QUARK

  // kernels starting from this will have difficulty calculated by using bitcoin algorithm
#define A_DARK(a, b) \
  { a, ALGO_X11, "", 1, 1, 1, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 0, 0, CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, b, queue_sph_kernel, gen_hash, append_x11_compiler_options }
  A_DARK("darkcoin", darkcoin_regenhash),
  A_DARK("inkcoin", inkcoin_regenhash),
  A_DARK("myriadcoin-groestl", myriadcoin_groestl_regenhash),
#undef A_DARK

  { "twecoin", ALGO_TWE, "", 1, 1, 1, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 0, 0, CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, twecoin_regenhash, queue_sph_kernel, sha256, NULL },
  { "maxcoin", ALGO_KECCAK, "", 1, 256, 1, 4, 15, 0x0F, 0xFFFFULL, 0x000000ffUL, 0, 0, CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, maxcoin_regenhash, queue_maxcoin_kernel, sha256, NULL },

  { "darkcoin-mod", ALGO_X11, "", 1, 1, 1, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 10, 8 * 16 * 4194304, 0, darkcoin_regenhash, queue_darkcoin_mod_kernel, gen_hash, append_x11_compiler_options },

  { "marucoin", ALGO_X13, "", 1, 1, 1, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 0, 0, CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, marucoin_regenhash, queue_sph_kernel, gen_hash, append_x13_compiler_options },
  { "marucoin-mod", ALGO_X13, "", 1, 1, 1, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 12, 8 * 16 * 4194304, 0, marucoin_regenhash, queue_marucoin_mod_kernel, gen_hash, append_x13_compiler_options },
  { "marucoin-modold", ALGO_X13, "", 1, 1, 1, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 10, 8 * 16 * 4194304, 0, marucoin_regenhash, queue_marucoin_mod_old_kernel, gen_hash, append_x13_compiler_options },

  { "x14", ALGO_X14, "", 1, 1, 1, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 13, 8 * 16 * 4194304, 0, x14_regenhash, queue_x14_kernel, gen_hash, append_x13_compiler_options },
  { "x14old", ALGO_X14, "", 1, 1, 1, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 10, 8 * 16 * 4194304, 0, x14_regenhash, queue_x14_old_kernel, gen_hash, append_x13_compiler_options },

  { "bitblock", ALGO_X15, "", 1, 1, 1, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 14, 4 * 16 * 4194304, 0, bitblock_regenhash, queue_bitblock_kernel, gen_hash, append_x13_compiler_options },
  { "bitblockold", ALGO_X15, "", 1, 1, 1, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 10, 4 * 16 * 4194304, 0, bitblock_regenhash, queue_bitblockold_kernel, gen_hash, append_x13_compiler_options },

  { "talkcoin-mod", ALGO_NIST, "", 1, 1, 1, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 4, 8 * 16 * 4194304, 0, talkcoin_regenhash, queue_talkcoin_mod_kernel, gen_hash, append_x11_compiler_options },

  { "fresh", ALGO_FRESH, "", 1, 256, 256, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 4, 4 * 16 * 4194304, 0, fresh_regenhash, queue_fresh_kernel, gen_hash, NULL },

  { "lyra2re", ALGO_LYRA2RE, "", 1, 128, 128, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 4, 2 * 8 * 4194304, 0, lyra2re_regenhash, queue_lyra2RE_kernel, gen_hash, NULL },

  // kernels starting from this will have difficulty calculated by using fuguecoin algorithm
#define A_FUGUE(a, b, c) \
  { a, ALGO_FUGUE, "", 1, 256, 256, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 0, 0, CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, b, queue_sph_kernel, c, NULL }
  A_FUGUE("fuguecoin", fuguecoin_regenhash, sha256),
  A_FUGUE("groestlcoin", groestlcoin_regenhash, sha256),
  A_FUGUE("diamond", groestlcoin_regenhash, gen_hash),
#undef A_FUGUE

  { "whirlcoin", ALGO_WHIRL, "", 1, 1, 1, 0, 0, 0xFF, 0xFFFFULL, 0x0000ffffUL, 3, 8 * 16 * 4194304, CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, whirlcoin_regenhash, queue_whirlcoin_kernel, sha256, NULL },
  { "whirlpoolx", ALGO_WHIRLPOOLX, "", 1, 1, 1, 0, 0, 0xFFU, 0xFFFFULL, 0x0000FFFFUL, 0, 0, 0, whirlpoolx_regenhash, queue_whirlpoolx_kernel, gen_hash, NULL },

  // Terminator (do not remove)
  { NULL, ALGO_UNK, "", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, NULL }
};

void copy_algorithm_settings(algorithm_t* dest, const char* algo)
{
  algorithm_settings_t* src;

  // Find algorithm settings and copy
  for (src = algos; src->name; src++)
  {
    if (strcmp(src->name, algo) == 0)
    {
      strcpy(dest->name, src->name);
      dest->kernelfile = src->kernelfile;
      dest->type = src->type;

      dest->diff_multiplier1 = src->diff_multiplier1;
      dest->diff_multiplier2 = src->diff_multiplier2;
      dest->share_diff_multiplier = src->share_diff_multiplier;
      dest->xintensity_shift = src->xintensity_shift;
      dest->intensity_shift = src->intensity_shift;
      dest->found_idx = src->found_idx;
      dest->diff_numerator = src->diff_numerator;
      dest->diff1targ = src->diff1targ;
      dest->n_extra_kernels = src->n_extra_kernels;
      dest->rw_buffer_size = src->rw_buffer_size;
      dest->cq_properties = src->cq_properties;
      dest->regenhash = src->regenhash;
      dest->queue_kernel = src->queue_kernel;
      dest->gen_hash = src->gen_hash;
      dest->set_compile_options = src->set_compile_options;
      break;
    }
  }

  // if not found
  if (src->name == NULL)
  {
    applog(LOG_WARNING, "Algorithm %s not found, using %s.", algo, algos->name);
    copy_algorithm_settings(dest, algos->name);
  }
}

static const char *lookup_algorithm_alias(const char *lookup_alias, uint8_t *nfactor)
{
#define ALGO_ALIAS_NF(alias, name, nf) \
  if (strcasecmp(alias, lookup_alias) == 0) { *nfactor = nf; return name; }
#define ALGO_ALIAS(alias, name) \
  if (strcasecmp(alias, lookup_alias) == 0) return name;

  ALGO_ALIAS_NF("scrypt", "ckolivas", 10);
  ALGO_ALIAS_NF("scrypt", "ckolivas", 10);
  ALGO_ALIAS_NF("adaptive-n-factor", "ckolivas", 11);
  ALGO_ALIAS_NF("adaptive-nfactor", "ckolivas", 11);
  ALGO_ALIAS_NF("nscrypt", "ckolivas", 11);
  ALGO_ALIAS_NF("adaptive-nscrypt", "ckolivas", 11);
  ALGO_ALIAS_NF("adaptive-n-scrypt", "ckolivas", 11);
  ALGO_ALIAS("x11mod", "darkcoin-mod");
  ALGO_ALIAS("x11", "darkcoin-mod");
  ALGO_ALIAS("x13mod", "marucoin-mod");
  ALGO_ALIAS("x13", "marucoin-mod");
  ALGO_ALIAS("x13old", "marucoin-modold");
  ALGO_ALIAS("x13modold", "marucoin-modold");
  ALGO_ALIAS("x15mod", "bitblock");
  ALGO_ALIAS("x15", "bitblock");
  ALGO_ALIAS("x15modold", "bitblockold");
  ALGO_ALIAS("x15old", "bitblockold");
  ALGO_ALIAS("nist5", "talkcoin-mod");
  ALGO_ALIAS("keccak", "maxcoin");
  ALGO_ALIAS("whirlpool", "whirlcoin");
  ALGO_ALIAS("Lyra2RE", "lyra2re");
  ALGO_ALIAS("lyra2", "lyra2re");

#undef ALGO_ALIAS
#undef ALGO_ALIAS_NF

  return NULL;
}

void set_algorithm(algorithm_t* algo, const char* newname_alias)
{
  const char *newname;

  //load previous algorithm nfactor in case nfactor was applied before algorithm... or default to 10
  uint8_t old_nfactor = ((algo->nfactor) ? algo->nfactor : 0);
  //load previous kernel file name if was applied before algorithm...
  const char *kernelfile = algo->kernelfile;
  uint8_t nfactor = 10;

  if (!(newname = lookup_algorithm_alias(newname_alias, &nfactor)))
    newname = newname_alias;

  copy_algorithm_settings(algo, newname);

  // use old nfactor if it was previously set and is different than the one set by alias
  if ((old_nfactor > 0) && (old_nfactor != nfactor))
    nfactor = old_nfactor;

  set_algorithm_nfactor(algo, nfactor);

  //reapply kernelfile if was set
  if (!empty_string(kernelfile)) {
    algo->kernelfile = kernelfile;
  }
}

void set_algorithm_nfactor(algorithm_t* algo, const uint8_t nfactor)
{
  algo->nfactor = nfactor;
  algo->n = (1 << nfactor);

  //adjust algo type accordingly
  switch (algo->type)
  {
  case ALGO_SCRYPT:
    //if nfactor isnt 10, switch to NSCRYPT
    if (algo->nfactor != 10)
      algo->type = ALGO_NSCRYPT;
    break;
    //nscrypt
  case ALGO_NSCRYPT:
    //if nfactor is 10, switch to SCRYPT
    if (algo->nfactor == 10)
      algo->type = ALGO_SCRYPT;
    break;
    //ignore rest
  default:
    break;
  }
}

bool cmp_algorithm(const algorithm_t* algo1, const algorithm_t* algo2)
{
  return (!safe_cmp(algo1->name, algo2->name) && !safe_cmp(algo1->kernelfile, algo2->kernelfile) && (algo1->nfactor == algo2->nfactor));
}
