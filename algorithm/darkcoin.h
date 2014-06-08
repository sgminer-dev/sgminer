#ifndef DARKCOIN_H
#define DARKCOIN_H

#include "miner.h"

extern int darkcoin_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void darkcoin_regenhash(struct work *work);

#endif /* DARKCOIN_H */
