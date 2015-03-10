#ifndef PLUCK_H
#define PLUCK_H

#include "miner.h"
#define PLUCK_SCRATCHBUF_SIZE (128 * 1024)
extern int pluck_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void pluck_regenhash(struct work *work);

#endif /* PLUCK_H */
