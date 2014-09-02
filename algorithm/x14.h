#ifndef X14_H
#define X14_H

#include "miner.h"

extern int x14_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void x14_regenhash(struct work *work);

#endif /* X14_H */