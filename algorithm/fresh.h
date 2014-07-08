#ifndef FRESHH_H
#define FRESHH_H

#include "miner.h"

extern int fresh_test(unsigned char *pdata, const unsigned char *ptarget,	uint32_t nonce);
extern void fresh_regenhash(struct work *work);

#endif /* FRESHH_H */