#ifndef ANIMECOIN_H
#define ANIMECOIN_H

#include "miner.h"

extern int animecoin_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void animecoin_regenhash(struct work *work);

#endif /* ANIMECOIN_H */
