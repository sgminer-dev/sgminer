#ifndef GROESTLCOIN_H
#define GROESTLCOIN_H

#include "miner.h"

extern int groestlcoin_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void groestlcoin_regenhash(struct work *work);

#endif /* GROESTLCOIN_H */
