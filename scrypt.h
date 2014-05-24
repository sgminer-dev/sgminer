#ifndef SCRYPT_H
#define SCRYPT_H

#include "miner.h"

/* extern int scrypt_test(unsigned char *pdata, const unsigned char *ptarget, */
/* 			uint32_t nonce); */
extern void scrypt_regenhash(struct work *work);

#endif /* SCRYPT_H */
