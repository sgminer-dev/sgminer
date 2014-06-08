#ifndef SIFCOIN_H
#define SIFCOIN_H

#include "miner.h"

extern int sifcoin_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void sifcoin_regenhash(struct work *work);

#endif /* SIFCOIN_H */
