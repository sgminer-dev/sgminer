/*-
 * Copyright 2009 Colin Percival, 2011 ArtForz
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * This file was originally written by Colin Percival as part of the Tarsnap
 * online backup system.
 */

#include "config.h"
#include "miner.h"

#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include "sph/sph_whirlpool.h"

/*
 * Encode a length len/4 vector of (uint32_t) into a length len vector of
 * (unsigned char) in big-endian form.  Assumes len is a multiple of 4.
 */
static inline void
be32enc_vect(uint32_t *dst, const uint32_t *src, uint32_t len)
{
	uint32_t i;

	for (i = 0; i < len; i++)
		dst[i] = htobe32(src[i]);
}

inline void whirlpoolx_hash(void *state, const void *input)
{
	sph_whirlpool1_context ctx;
    
	sph_whirlpool1_init(&ctx);

    uint8_t digest[64];  

	sph_whirlpool(&ctx, input, 80);
	sph_whirlpool_close(&ctx, digest);

	((uint8_t *)state)[0] = digest[0] ^ digest[16];
	((uint8_t *)state)[1] = digest[1] ^ digest[17];
	((uint8_t *)state)[2] = digest[2] ^ digest[18];
	((uint8_t *)state)[3] = digest[3] ^ digest[19];
	((uint8_t *)state)[4] = digest[4] ^ digest[20];
	((uint8_t *)state)[5] = digest[5] ^ digest[21];
	((uint8_t *)state)[6] = digest[6] ^ digest[22];
	((uint8_t *)state)[7] = digest[7] ^ digest[23];
	((uint8_t *)state)[8] = digest[8] ^ digest[24];
	((uint8_t *)state)[9] = digest[9] ^ digest[25];
	((uint8_t *)state)[10] = digest[10] ^ digest[26];
	((uint8_t *)state)[11] = digest[11] ^ digest[27];
	((uint8_t *)state)[12] = digest[12] ^ digest[28];
	((uint8_t *)state)[13] = digest[13] ^ digest[29];
	((uint8_t *)state)[14] = digest[14] ^ digest[30];
	((uint8_t *)state)[15] = digest[15] ^ digest[31];
	((uint8_t *)state)[16] = digest[16] ^ digest[32];
	((uint8_t *)state)[17] = digest[17] ^ digest[33];
	((uint8_t *)state)[18] = digest[18] ^ digest[34];
	((uint8_t *)state)[19] = digest[19] ^ digest[35];
	((uint8_t *)state)[20] = digest[20] ^ digest[36];
	((uint8_t *)state)[21] = digest[21] ^ digest[37];
	((uint8_t *)state)[22] = digest[22] ^ digest[38];
	((uint8_t *)state)[23] = digest[23] ^ digest[39];
	((uint8_t *)state)[24] = digest[24] ^ digest[40];
	((uint8_t *)state)[25] = digest[25] ^ digest[41];
	((uint8_t *)state)[26] = digest[26] ^ digest[42];
	((uint8_t *)state)[27] = digest[27] ^ digest[43];
	((uint8_t *)state)[28] = digest[28] ^ digest[44];
	((uint8_t *)state)[29] = digest[29] ^ digest[45];
	((uint8_t *)state)[30] = digest[30] ^ digest[46];
	((uint8_t *)state)[31] = digest[31] ^ digest[47];
}

static const uint32_t diff1targ = 0x0000ffff;


/* Used externally as confirmation of correct OCL code */
int whirlpoolx_test(unsigned char *pdata, const unsigned char *ptarget, uint32_t nonce)
{
	uint32_t tmp_hash7, Htarg = le32toh(((const uint32_t *)ptarget)[7]);
	uint32_t data[20], ohash[8];

	be32enc_vect(data, (const uint32_t *)pdata, 19);
	data[19] = htobe32(nonce);

	whirlpoolx_hash(ohash, data);
	tmp_hash7 = be32toh(ohash[7]);

	applog(LOG_DEBUG, "htarget %08lx diff1 %08lx hash %08lx",
				(long unsigned int)Htarg,
				(long unsigned int)diff1targ,
				(long unsigned int)tmp_hash7);
	if (tmp_hash7 > diff1targ)
		return -1;
	if (tmp_hash7 > Htarg)
		return 0;
	return 1;
}

void whirlpoolx_regenhash(struct work *work)
{
    uint32_t data[20];
    uint32_t *nonce = (uint32_t *)(work->data + 76);
    uint32_t *ohash = (uint32_t *)(work->hash);

    be32enc_vect(data, (const uint32_t *)work->data, 19);
    data[19] = htobe32(*nonce);
    whirlpoolx_hash(ohash, data);
}

bool scanhash_whirlpoolx(struct thr_info *thr, const unsigned char __maybe_unused *pmidstate,
		     unsigned char *pdata, unsigned char __maybe_unused *phash1,
		     unsigned char __maybe_unused *phash, const unsigned char *ptarget,
		     uint32_t max_nonce, uint32_t *last_nonce, uint32_t n)
{
	uint32_t *nonce = (uint32_t *)(pdata + 76);
	uint32_t data[20];
	uint32_t tmp_hash7;
	uint32_t Htarg = le32toh(((const uint32_t *)ptarget)[7]);
	bool ret = false;

	be32enc_vect(data, (const uint32_t *)pdata, 19);

	while(1) {
		uint32_t ostate[8];

		*nonce = ++n;
		data[19] = (n);
		whirlpoolx_hash(ostate, data);
		tmp_hash7 = (ostate[7]);

		applog(LOG_INFO, "data7 %08lx",
					(long unsigned int)data[7]);

		if (unlikely(tmp_hash7 <= Htarg)) {
			((uint32_t *)pdata)[19] = htobe32(n);
			*last_nonce = n;
			ret = true;
			break;
		}

		if (unlikely((n >= max_nonce) || thr->work_restart)) {
			*last_nonce = n;
			break;
		}
	}

	return ret;
}
