#ifndef BITBLOCK_H
#define BITBLOCK_H

#include "miner.h"

extern int bitblock_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void bitblock_regenhash(struct work *work);

#endif /* BITBLOCK_H */
