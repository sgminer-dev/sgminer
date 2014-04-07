#ifndef ALGORITHM_H
#define ALGORITHM_H

#include <inttypes.h>
#include <stdbool.h>

/* Describes the Scrypt parameters and hashing functions used to mine
 * a specific coin.
 */
typedef struct _algorithm_t {
    char     name[20]; /* Human-readable identifier */
    uint32_t n;        /* N (CPU/Memory tradeoff parameter) */
    uint8_t  nfactor;  /* Factor of N above (n = 2^nfactor) */
} algorithm_t;

/* Set default parameters based on name. */
void set_algorithm(algorithm_t* algo, const char* name);

/* Set to specific N factor. */
void set_algorithm_nfactor(algorithm_t* algo, const uint8_t nfactor);

/* Compare two algorithm parameters */
bool cmp_algorithm(algorithm_t* algo1, algorithm_t* algo2);

#endif /* ALGORITHM_H */
