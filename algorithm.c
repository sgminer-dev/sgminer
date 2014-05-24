/*
 * Copyright 2014 sgminer developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or (at
 * your option) any later version.  See COPYING for more details.
 */

#include "algorithm.h"
#include "sha2.h"
#include "ocl.h"

#include "scrypt.h"
#include "animecoin.h"
#include "inkcoin.h"
#include "quarkcoin.h"
#include "qubitcoin.h"
#include "sifcoin.h"
#include "darkcoin.h"
#include "myriadcoin-groestl.h"
#include "fuguecoin.h"
#include "groestlcoin.h"
#include "twecoin.h"
#include "marucoin.h"

#include <inttypes.h>
#include <string.h>

void gen_hash(const unsigned char *data, unsigned int len, unsigned char *hash)
{
    unsigned char hash1[32];

    sha256(data, len, hash1);
    sha256(hash1, 32, hash);
}

#define CL_SET_BLKARG(blkvar) status |= clSetKernelArg(*kernel, num++, sizeof(uint), (void *)&blk->blkvar)
#define CL_SET_ARG(var) status |= clSetKernelArg(*kernel, num++, sizeof(var), (void *)&var)
#define CL_SET_VARG(args, var) status |= clSetKernelArg(*kernel, num++, args * sizeof(uint), (void *)var)

static cl_int queue_scrypt_kernel(struct __clState *clState, struct _dev_blk_ctx *blk, __maybe_unused cl_uint threads)
{
    unsigned char *midstate = blk->work->midstate;
    cl_kernel *kernel = &clState->kernel;
    unsigned int num = 0;
    cl_uint le_target;
    cl_int status = 0;

    le_target = *(cl_uint *)(blk->work->device_target + 28);
    memcpy(clState->cldata, blk->work->data, 80);
    status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL,NULL);

    CL_SET_ARG(clState->CLbuffer0);
    CL_SET_ARG(clState->outputBuffer);
    CL_SET_ARG(clState->padbuffer8);
    CL_SET_VARG(4, &midstate[0]);
    CL_SET_VARG(4, &midstate[16]);
    CL_SET_ARG(le_target);

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
    status = clEnqueueWriteBuffer(clState->commandQueue, clState->CLbuffer0, true, 0, 80, clState->cldata, 0, NULL,NULL);

    CL_SET_ARG(clState->CLbuffer0);
    CL_SET_ARG(clState->outputBuffer);
    CL_SET_ARG(le_target);

    return status;
}

typedef struct _algorithm_settings_t {
    const char *name; /* Human-readable identifier */
    double   diff_multiplier1;
    double   diff_multiplier2;
    unsigned long long   diff_nonce;
    unsigned long long   diff_numerator;
    void     (*regenhash)(struct work *);
    cl_int   (*queue_kernel)(struct __clState *, struct _dev_blk_ctx *, cl_uint);
    void     (*gen_hash)(const unsigned char *, unsigned int, unsigned char *);
} algorithm_settings_t;

static algorithm_settings_t algos[] = {
    // kernels starting from this will have difficulty calculated by using litecoin algorithm
#define A_SCRYPT(a) \
    { a, 1, 65536, 0x0000ffff00000000ULL, 0xFFFFFFFFULL, scrypt_regenhash, queue_scrypt_kernel, gen_hash}
    A_SCRYPT( "ckolivas" ),
    A_SCRYPT( "alexkarnew" ),
    A_SCRYPT( "alexkarnold" ),
    A_SCRYPT( "bufius" ),
    A_SCRYPT( "psw" ),
    A_SCRYPT( "zuikkis" ),
#undef A_SCRYPT

    // kernels starting from this will have difficulty calculated by using quarkcoin algorithm
#define A_QUARK(a, b) \
    { a, 256, 256, 0x000000ffff000000ULL, 0xFFFFFFULL, b, queue_sph_kernel, gen_hash}
    A_QUARK( "quarkcoin", quarkcoin_regenhash),
    A_QUARK( "qubitcoin", qubitcoin_regenhash),
    A_QUARK( "animecoin", animecoin_regenhash),
    A_QUARK( "sifcoin",   sifcoin_regenhash),
#undef A_QUARK

    // kernels starting from this will have difficulty calculated by using bitcoin algorithm
#define A_DARK(a, b) \
    { a, 1, 1, 0x00000000ffff0000ULL, 0xFFFFULL, b, queue_sph_kernel, gen_hash}
    A_DARK( "darkcoin",           darkcoin_regenhash),
    A_DARK( "inkcoin",            inkcoin_regenhash),
    A_DARK( "myriadcoin-groestl", myriadcoin_groestl_regenhash),
    A_DARK( "marucoin",           marucoin_regenhash),
#undef A_DARK

    { "twecoin", 1, 1, 0x00000000ffff0000ULL, 0xFFFFULL, twecoin_regenhash, queue_sph_kernel, sha256},

    // kernels starting from this will have difficulty calculated by using fuguecoin algorithm
#define A_FUGUE(a, b) \
    { a, 1, 256, 0x00000000ffff0000ULL, 0xFFFFULL, b, queue_sph_kernel, sha256}
    A_FUGUE( "fuguecoin",   fuguecoin_regenhash),
    A_FUGUE( "groestlcoin", groestlcoin_regenhash),
#undef A_FUGUE

    // Terminator (do not remove)
    { NULL, 0, 0, 0, 0, NULL, NULL, NULL}
};

void copy_algorithm_settings(algorithm_t* dest, const char* algo) {
    algorithm_settings_t* src;

    // Find algorithm settings and copy
    for (src = algos; src->name; src++) {
        if (strcmp(src->name, algo) == 0) {
            strcpy(dest->name, src->name);

            dest->diff_multiplier1 = src->diff_multiplier1;
            dest->diff_multiplier2 = src->diff_multiplier2;
            dest->diff_nonce = src->diff_nonce;
            dest->diff_numerator = src->diff_numerator;
            dest->regenhash = src->regenhash;
            dest->queue_kernel = src->queue_kernel;
            dest->gen_hash = src->gen_hash;
            break;
        }
    }

    // if not found
    if (src->name == NULL) {
        applog(LOG_WARNING, "Algorithm %s not found, using %s.", algo, algos->name);
        copy_algorithm_settings(dest, algos->name);
    }
}

void set_algorithm(algorithm_t* algo, const char* newname_alias) {
    const char* newname;
    uint8_t nfactor = 10;

    // scrypt is default ckolivas kernel
    if (strcmp(newname_alias, "scrypt") == 0)
        newname = "ckolivas";
    // Adaptive N-factor Scrypt is default ckolivas kernel with nfactor 11
    else if ((strcmp(newname_alias, "adaptive-n-factor") == 0) ||
        (strcmp(newname_alias, "adaptive-nfactor") == 0) ||
        (strcmp(newname_alias, "nscrypt") == 0) ||
        (strcmp(newname_alias, "adaptive-nscrypt") == 0) ||
        (strcmp(newname_alias, "adaptive-n-scrypt") == 0)) {
        newname = "ckolivas";
        nfactor = 11;
    // Not an alias
    } else
        newname = newname_alias;

    copy_algorithm_settings(algo, newname);

    // Doesn't matter for non-scrypt algorithms
    set_algorithm_nfactor(algo, nfactor);
}

void set_algorithm_nfactor(algorithm_t* algo, const uint8_t nfactor) {
    algo->nfactor = nfactor;
    algo->n = (1 << nfactor);
}

bool cmp_algorithm(algorithm_t* algo1, algorithm_t* algo2) {
    return (strcmp(algo1->name, algo2->name) == 0) &&
          (algo1->nfactor == algo2->nfactor);
}
