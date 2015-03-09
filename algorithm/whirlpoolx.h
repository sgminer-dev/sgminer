#ifndef WHIRLPOOLX_H
#define WHIRLPOOLX_H

#include "miner.h"

extern int whirlpoolx_test(unsigned char *pdata, const unsigned char *ptarget, uint32_t nonce);
extern void whirlpoolx_regenhash(struct work *work);

#endif /* W_H */