#ifndef NEOSCRYPT_H
#define NEOSCRYPT_H

#include "miner.h"

/* The neoscrypt scratch buffer needs 32kBytes memory. */
#define NEOSCRYPT_SCRATCHBUF_SIZE (32 * 1024)
/* These routines are always available. */
extern void neoscrypt_regenhash(struct work *work);
extern void neoscrypt(const unsigned char *input, unsigned char *output, unsigned int profile);

#endif /* NEOSCRYPT_H */