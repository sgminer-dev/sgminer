#ifndef FUGUECOIN_H
#define FUGUECOIN_H

#include "miner.h"

extern int fuguecoin_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void fuguecoin_regenhash(struct work *work);

#endif /* FUGUECOIN_H */
