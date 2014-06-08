#ifndef MARUCOIN_H
#define MARUCOIN_H

#include "miner.h"

extern int marucoin_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void marucoin_regenhash(struct work *work);

#endif /* MARUCOIN_H */
