#ifndef INKCOIN_H
#define INKCOIN_H

#include "miner.h"

extern int inkcoin_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void inkcoin_regenhash(struct work *work);

#endif /* INKCOIN_H */
