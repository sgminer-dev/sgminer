#ifndef QUARKCOIN_H
#define QUARKCOIN_H

#include "miner.h"

extern int quarkcoin_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void quarkcoin_regenhash(struct work *work);

#endif /* QUARKCOIN_H */
