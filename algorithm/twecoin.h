#ifndef TWECOIN_H
#define TWECOIN_H

#include "miner.h"

extern int twecoin_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void twecoin_regenhash(struct work *work);

#endif /* TWECOIN_H */
