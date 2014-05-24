#ifndef ALGORITHM_H
#define ALGORITHM_H

#ifdef __APPLE_CC__
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#endif

#include <inttypes.h>
#include <stdbool.h>

extern void gen_hash(const unsigned char *data, unsigned int len, unsigned char *hash);

struct __clState;
struct _dev_blk_ctx;
struct work;

/* Describes the Scrypt parameters and hashing functions used to mine
 * a specific coin.
 */
typedef struct _algorithm_t {
    char     name[20]; /* Human-readable identifier */
    uint32_t n;        /* N (CPU/Memory tradeoff parameter) */
    uint8_t  nfactor;  /* Factor of N above (n = 2^nfactor) */
    double   diff_multiplier1;
    double   diff_multiplier2;
    unsigned long long   diff_nonce;
    unsigned long long   diff_numerator;
    void     (*regenhash)(struct work *);
    cl_int   (*queue_kernel)(struct __clState *, struct _dev_blk_ctx *, cl_uint);
    void     (*gen_hash)(const unsigned char *, unsigned int, unsigned char *);
} algorithm_t;

/* Set default parameters based on name. */
void set_algorithm(algorithm_t* algo, const char* name);

/* Set to specific N factor. */
void set_algorithm_nfactor(algorithm_t* algo, const uint8_t nfactor);

/* Compare two algorithm parameters */
bool cmp_algorithm(algorithm_t* algo1, algorithm_t* algo2);

#endif /* ALGORITHM_H */
