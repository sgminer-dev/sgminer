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

#include "whirlpoolx.h"

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


void whirlpool_compress(uint8_t state[64], const uint8_t block[64])
{
	const int NUM_ROUNDS = 10;
	uint64_t tempState[8];
	uint64_t tempBlock[8];
	int i;
	
	// Initialization
	for (i = 0; i < 8; i++) {
		tempState[i] = 
			  (uint64_t)state[i << 3]
			| (uint64_t)state[(i << 3) + 1] <<  8
			| (uint64_t)state[(i << 3) + 2] << 16
			| (uint64_t)state[(i << 3) + 3] << 24
			| (uint64_t)state[(i << 3) + 4] << 32
			| (uint64_t)state[(i << 3) + 5] << 40
			| (uint64_t)state[(i << 3) + 6] << 48
			| (uint64_t)state[(i << 3) + 7] << 56;
		tempBlock[i] = (
			  (uint64_t)block[i << 3]
			| (uint64_t)block[(i << 3) + 1] <<  8
			| (uint64_t)block[(i << 3) + 2] << 16
			| (uint64_t)block[(i << 3) + 3] << 24
			| (uint64_t)block[(i << 3) + 4] << 32
			| (uint64_t)block[(i << 3) + 5] << 40
			| (uint64_t)block[(i << 3) + 6] << 48
			| (uint64_t)block[(i << 3) + 7] << 56) ^ tempState[i];
	}
	
	// Hashing rounds
	uint64_t rcon[8];
	memset(rcon + 1, 0, sizeof(rcon[0]) * 7);
	for (i = 0; i < NUM_ROUNDS; i++) {
		rcon[0] = WHIRLPOOL_ROUND_CONSTANTS[i];
		whirlpool_round(tempState, rcon);
		whirlpool_round(tempBlock, tempState);
	}
	
	// Final combining
	for (i = 0; i < 64; i++)
		state[i] ^= block[i] ^ (uint8_t)(tempBlock[i >> 3] >> ((i & 7) << 3));
}





void whirlpool_round(uint64_t block[8], const uint64_t key[8]) {
	uint64_t a = block[0];
	uint64_t b = block[1];
	uint64_t c = block[2];
	uint64_t d = block[3];
	uint64_t e = block[4];
	uint64_t f = block[5];
	uint64_t g = block[6];
	uint64_t h = block[7];
	
	uint64_t r;
	#define DOROW(i, s, t, u, v, w, x, y, z)  \
		r = MAGIC_TABLE[(uint8_t)s];  r = (r << 56) | (r >> 8);  \
		r ^= MAGIC_TABLE[(uint8_t)(t >>  8)];  r = (r << 56) | (r >> 8);  \
		r ^= MAGIC_TABLE[(uint8_t)(u >> 16)];  r = (r << 56) | (r >> 8);  \
		r ^= MAGIC_TABLE[(uint8_t)(v >> 24)];  r = (r << 56) | (r >> 8);  \
		r ^= MAGIC_TABLE[(uint8_t)(w >> 32)];  r = (r << 56) | (r >> 8);  \
		r ^= MAGIC_TABLE[(uint8_t)(x >> 40)];  r = (r << 56) | (r >> 8);  \
		r ^= MAGIC_TABLE[(uint8_t)(y >> 48)];  r = (r << 56) | (r >> 8);  \
		r ^= MAGIC_TABLE[(uint8_t)(z >> 56)];  r = (r << 56) | (r >> 8);  \
		block[i] = r ^ key[i];
	
	DOROW(0, a, h, g, f, e, d, c, b)
	DOROW(1, b, a, h, g, f, e, d, c)
	DOROW(2, c, b, a, h, g, f, e, d)
	DOROW(3, d, c, b, a, h, g, f, e)
	DOROW(4, e, d, c, b, a, h, g, f)
	DOROW(5, f, e, d, c, b, a, h, g)
	DOROW(6, g, f, e, d, c, b, a, h)
	DOROW(7, h, g, f, e, d, c, b, a)
}

void whirlpool_hash(const uint8_t *message, uint32_t len, uint8_t hash[64]) {
	memset(hash, 0, 64);
	
	uint32_t i;
	for (i = 0; len - i >= 64; i += 64)
		whirlpool_compress(hash, message + i);
	
	uint8_t block[64];
	uint32_t rem = len - i;
	memcpy(block, message + i, rem);
	
	block[rem] = 0x80;
	rem++;
	if (64 - rem >= 32)
		memset(block + rem, 0, 56 - rem);
	else {
		memset(block + rem, 0, 64 - rem);
		whirlpool_compress(hash, block);
		memset(block, 0, 56);
	}
	
	uint64_t longLen = ((uint64_t)len) << 3;
	for (i = 0; i < 8; i++)
		block[64 - 1 - i] = (uint8_t)(longLen >> (i * 8));
	whirlpool_compress(hash, block);
}

void whirlpoolx_hash(void *state, const void *input)
{
	//sph_whirlpool1_context ctx;
    
	//sph_whirlpool1_init(&ctx);

    uint8_t digest[64];  

	//sph_whirlpool(&ctx, input, 80);
	//sph_whirlpool_close(&ctx, digest);
	
	whirlpool_hash((uint8_t *)input, 80, digest);
	
	uint8_t digest_xored[32]; 

	for (uint32_t i = 0; i < (64 / 2); i++)
	{
		digest_xored[i] =
			digest[i] ^ digest[i + ((64 / 2) / 2)]
		;
	}

    memcpy(state, digest_xored, sizeof(digest_xored));
}

static const uint32_t diff1targ = 0x0000ffff;


/* Used externally as confirmation of correct OCL code */
int whirlcoin_test(unsigned char *pdata, const unsigned char *ptarget, uint32_t nonce)
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

bool scanhash_whirlcoin(struct thr_info *thr, const unsigned char __maybe_unused *pmidstate,
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