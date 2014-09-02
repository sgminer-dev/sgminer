#ifndef QUBITCOIN_H
#define QUBITCOIN_H

#include "miner.h"

extern int qubitcoin_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void qubitcoin_regenhash(struct work *work);

#endif /* QUBITCOIN_H */
