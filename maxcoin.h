#ifndef MAXCOIN_H
#define MAXCOIN_H

#include "miner.h"

// extern int maxcoin_test(unsigned char *pdata, const unsigned char *ptarget, uint32_t nonce);
extern void maxcoin_regenhash(struct work *work);

#endif /* MAXCOIN_H */
