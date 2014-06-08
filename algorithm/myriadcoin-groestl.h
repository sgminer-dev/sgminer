#ifndef MYRIADCOIN_GROESTL_H
#define MYRIADCOIN_GROESTL_H

#include "miner.h"

extern int myriadcoin_groestl_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void myriadcoin_groestl_regenhash(struct work *work);

#endif /* MYRIADCOIN_GROESTL_H */
