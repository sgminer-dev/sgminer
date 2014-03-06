#ifndef ALGORITHM_H
#define ALGORITHM_H

#include <inttypes.h>

/* Describes the Scrypt parameters and hashing functions used to mine
 * a specific coin.
 */
typedef struct algorithm_t algorithm_t;

/* Set default parameters based on name. */
void set_algorithm(algorithm_t* algo, char* name);

/* Set to specific N factor. */
void set_algorithm_nfactor(algorithm_t* algo, uint8_t nfactor);

#endif /* ALGORITHM_H */
