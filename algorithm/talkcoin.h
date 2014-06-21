#ifndef TALKCOIN_H
#define TALKCOIN_H

#include "miner.h"

extern int talkcoin_test(unsigned char *pdata, const unsigned char *ptarget, uint32_t nonce);
extern void talkcoin_regenhash(struct work *work);

#endif /* TALKCOIN_H */
