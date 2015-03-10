#ifndef LYRA2RE_H
#define LYRA2RE_H

#include "miner.h"

extern int lyra2re_test(unsigned char *pdata, const unsigned char *ptarget,
			uint32_t nonce);
extern void lyra2re_regenhash(struct work *work);

#endif /* LYRA2RE_H */
