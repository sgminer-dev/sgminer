#ifndef WHIRLCOIN_H
#define WHIRLCOIN_H

#include "miner.h"

extern int whirlcoin_test(unsigned char *pdata, const unsigned char *ptarget, uint32_t nonce);
extern void whirlcoin_regenhash(struct work *work);

#endif /* W_H */