/*
 * Copyright 2011-2013 Con Kolivas
 * Copyright 2011 Nils Schneider
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 3 of the License, or (at your option)
 * any later version.  See COPYING for more details.
 */

#include "config.h"

#include <stdio.h>
#include <pthread.h>
#include <string.h>

#include "findnonce.h"
#include "algorithm/scrypt.h"

const uint32_t SHA256_K[64] = {
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
  0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
  0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
  0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
  0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
  0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

#define rotate(x,y) ((x<<y) | (x>>(sizeof(x)*8-y)))
#define rotr(x,y) ((x>>y) | (x<<(sizeof(x)*8-y)))

#define R(a, b, c, d, e, f, g, h, w, k) \
  h = h + (rotate(e, 26) ^ rotate(e, 21) ^ rotate(e, 7)) + (g ^ (e & (f ^ g))) + k + w; \
  d = d + h; \
  h = h + (rotate(a, 30) ^ rotate(a, 19) ^ rotate(a, 10)) + ((a & b) | (c & (a | b)))

void precalc_hash(dev_blk_ctx *blk, uint32_t *state, uint32_t *data)
{
  cl_uint A, B, C, D, E, F, G, H;

  A = state[0];
  B = state[1];
  C = state[2];
  D = state[3];
  E = state[4];
  F = state[5];
  G = state[6];
  H = state[7];

  R(A, B, C, D, E, F, G, H, data[0], SHA256_K[0]);
  R(H, A, B, C, D, E, F, G, data[1], SHA256_K[1]);
  R(G, H, A, B, C, D, E, F, data[2], SHA256_K[2]);

  blk->cty_a = A;
  blk->cty_b = B;
  blk->cty_c = C;
  blk->cty_d = D;

  blk->D1A = D + 0xb956c25b;

  blk->cty_e = E;
  blk->cty_f = F;
  blk->cty_g = G;
  blk->cty_h = H;

  blk->ctx_a = state[0];
  blk->ctx_b = state[1];
  blk->ctx_c = state[2];
  blk->ctx_d = state[3];
  blk->ctx_e = state[4];
  blk->ctx_f = state[5];
  blk->ctx_g = state[6];
  blk->ctx_h = state[7];

  blk->merkle = data[0];
  blk->ntime = data[1];
  blk->nbits = data[2];

  blk->W16 = blk->fW0 = data[0] + (rotr(data[1], 7) ^ rotr(data[1], 18) ^ (data[1] >> 3));
  blk->W17 = blk->fW1 = data[1] + (rotr(data[2], 7) ^ rotr(data[2], 18) ^ (data[2] >> 3)) + 0x01100000;
  blk->PreVal4 = blk->fcty_e = blk->ctx_e + (rotr(B, 6) ^ rotr(B, 11) ^ rotr(B, 25)) + (D ^ (B & (C ^ D))) + 0xe9b5dba5;
  blk->T1 = blk->fcty_e2 = (rotr(F, 2) ^ rotr(F, 13) ^ rotr(F, 22)) + ((F & G) | (H & (F | G)));
  blk->PreVal4_2 = blk->PreVal4 + blk->T1;
  blk->PreVal0 = blk->PreVal4 + blk->ctx_a;
  blk->PreW31 = 0x00000280 + (rotr(blk->W16, 7) ^ rotr(blk->W16, 18) ^ (blk->W16 >> 3));
  blk->PreW32 = blk->W16 + (rotr(blk->W17, 7) ^ rotr(blk->W17, 18) ^ (blk->W17 >> 3));
  blk->PreW18 = data[2] + (rotr(blk->W16, 17) ^ rotr(blk->W16, 19) ^ (blk->W16 >> 10));
  blk->PreW19 = 0x11002000 + (rotr(blk->W17, 17) ^ rotr(blk->W17, 19) ^ (blk->W17 >> 10));


  blk->W2 = data[2];

  blk->W2A = blk->W2 + (rotr(blk->W16, 19) ^ rotr(blk->W16, 17) ^ (blk->W16 >> 10));
  blk->W17_2 = 0x11002000 + (rotr(blk->W17, 19) ^ rotr(blk->W17, 17) ^ (blk->W17 >> 10));

  blk->fW2 = data[2] + (rotr(blk->fW0, 17) ^ rotr(blk->fW0, 19) ^ (blk->fW0 >> 10));
  blk->fW3 = 0x11002000 + (rotr(blk->fW1, 17) ^ rotr(blk->fW1, 19) ^ (blk->fW1 >> 10));
  blk->fW15 = 0x00000280 + (rotr(blk->fW0, 7) ^ rotr(blk->fW0, 18) ^ (blk->fW0 >> 3));
  blk->fW01r = blk->fW0 + (rotr(blk->fW1, 7) ^ rotr(blk->fW1, 18) ^ (blk->fW1 >> 3));


  blk->PreVal4addT1 = blk->PreVal4 + blk->T1;
  blk->T1substate0 = blk->ctx_a - blk->T1;

  blk->C1addK5 = blk->cty_c + SHA256_K[5];
  blk->B1addK6 = blk->cty_b + SHA256_K[6];
  blk->PreVal0addK7 = blk->PreVal0 + SHA256_K[7];
  blk->W16addK16 = blk->W16 + SHA256_K[16];
  blk->W17addK17 = blk->W17 + SHA256_K[17];

  blk->zeroA = blk->ctx_a + 0x98c7e2a2;
  blk->zeroB = blk->ctx_a + 0xfc08884d;
  blk->oneA = blk->ctx_b + 0x90bb1e3c;
  blk->twoA = blk->ctx_c + 0x50c6645b;
  blk->threeA = blk->ctx_d + 0x3ac42e24;
  blk->fourA = blk->ctx_e + SHA256_K[4];
  blk->fiveA = blk->ctx_f + SHA256_K[5];
  blk->sixA = blk->ctx_g + SHA256_K[6];
  blk->sevenA = blk->ctx_h + SHA256_K[7];
}

#if 0 // not used any more

#define P(t) (W[(t)&0xF] = W[(t-16)&0xF] + (rotate(W[(t-15)&0xF], 25) ^ rotate(W[(t-15)&0xF], 14) ^ (W[(t-15)&0xF] >> 3)) + W[(t-7)&0xF] + (rotate(W[(t-2)&0xF], 15) ^ rotate(W[(t-2)&0xF], 13) ^ (W[(t-2)&0xF] >> 10)))

#define IR(u) \
  R(A, B, C, D, E, F, G, H, W[u+0], SHA256_K[u+0]); \
  R(H, A, B, C, D, E, F, G, W[u+1], SHA256_K[u+1]); \
  R(G, H, A, B, C, D, E, F, W[u+2], SHA256_K[u+2]); \
  R(F, G, H, A, B, C, D, E, W[u+3], SHA256_K[u+3]); \
  R(E, F, G, H, A, B, C, D, W[u+4], SHA256_K[u+4]); \
  R(D, E, F, G, H, A, B, C, W[u+5], SHA256_K[u+5]); \
  R(C, D, E, F, G, H, A, B, W[u+6], SHA256_K[u+6]); \
  R(B, C, D, E, F, G, H, A, W[u+7], SHA256_K[u+7])
#define FR(u) \
  R(A, B, C, D, E, F, G, H, P(u+0), SHA256_K[u+0]); \
  R(H, A, B, C, D, E, F, G, P(u+1), SHA256_K[u+1]); \
  R(G, H, A, B, C, D, E, F, P(u+2), SHA256_K[u+2]); \
  R(F, G, H, A, B, C, D, E, P(u+3), SHA256_K[u+3]); \
  R(E, F, G, H, A, B, C, D, P(u+4), SHA256_K[u+4]); \
  R(D, E, F, G, H, A, B, C, P(u+5), SHA256_K[u+5]); \
  R(C, D, E, F, G, H, A, B, P(u+6), SHA256_K[u+6]); \
  R(B, C, D, E, F, G, H, A, P(u+7), SHA256_K[u+7])

#define PIR(u) \
  R(F, G, H, A, B, C, D, E, W[u+3], SHA256_K[u+3]); \
  R(E, F, G, H, A, B, C, D, W[u+4], SHA256_K[u+4]); \
  R(D, E, F, G, H, A, B, C, W[u+5], SHA256_K[u+5]); \
  R(C, D, E, F, G, H, A, B, W[u+6], SHA256_K[u+6]); \
  R(B, C, D, E, F, G, H, A, W[u+7], SHA256_K[u+7])

#define PFR(u) \
  R(A, B, C, D, E, F, G, H, P(u+0), SHA256_K[u+0]); \
  R(H, A, B, C, D, E, F, G, P(u+1), SHA256_K[u+1]); \
  R(G, H, A, B, C, D, E, F, P(u+2), SHA256_K[u+2]); \
  R(F, G, H, A, B, C, D, E, P(u+3), SHA256_K[u+3]); \
  R(E, F, G, H, A, B, C, D, P(u+4), SHA256_K[u+4]); \
  R(D, E, F, G, H, A, B, C, P(u+5), SHA256_K[u+5])

#endif

struct pc_data {
  struct thr_info *thr;
  struct work *work;
  uint32_t res[MAXBUFFERS];
  pthread_t pth;
  int found;
};

static void *postcalc_hash(void *userdata)
{
  struct pc_data *pcd = (struct pc_data *)userdata;
  struct thr_info *thr = pcd->thr;
  unsigned int entry = 0;

  int found = thr->cgpu->algorithm.found_idx;

  pthread_detach(pthread_self());

  /* To prevent corrupt values in FOUND from trying to read beyond the
   * end of the res[] array */
  if (unlikely(pcd->res[found] & ~found)) {
    applog(LOG_WARNING, "%s%d: invalid nonce count - HW error",
      thr->cgpu->drv->name, thr->cgpu->device_id);
    hw_errors++;
    thr->cgpu->hw_errors++;
    pcd->res[found] &= found;
  }

  for (entry = 0; entry < pcd->res[found]; entry++) {
    uint32_t nonce = pcd->res[entry];
    if (found == 0x0F)
      nonce = swab32(nonce);

    applog(LOG_DEBUG, "[THR%d] OCL NONCE %08x (%lu) found in slot %d (found = %d)", thr->id, nonce, nonce, entry, found);
    submit_nonce(thr, pcd->work, nonce);
  }

  discard_work(pcd->work);
  free(pcd);

  return NULL;
}

void postcalc_hash_async(struct thr_info *thr, struct work *work, uint32_t *res)
{
  struct pc_data *pcd = (struct pc_data *)malloc(sizeof(struct pc_data));
  int buffersize;

  if (unlikely(!pcd)) {
    applog(LOG_ERR, "Failed to malloc pc_data in postcalc_hash_async");
    return;
  }

  pcd->thr = thr;
  pcd->work = copy_work(work);
  buffersize = BUFFERSIZE;

  memcpy(&pcd->res, res, buffersize);

  if (pthread_create(&pcd->pth, NULL, postcalc_hash, (void *)pcd)) {
    applog(LOG_ERR, "Failed to create postcalc_hash thread");
    discard_work(pcd->work);
    free(pcd);
  }
}

// BLAKE 256 14 rounds (standard)

typedef struct
{
  uint32_t h[8];
  uint32_t t;
} blake_state256;

#define NB_ROUNDS32 14

const uint8_t blake_sigma[][16] =
{
  { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
  { 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3 },
  { 11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4 },
  { 7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8 },
  { 9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13 },
  { 2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9 },
  { 12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11 },
  { 13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10 },
  { 6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5 },
  { 10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0 },
  { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
  { 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3 },
  { 11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4 },
  { 7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8 },
  { 9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13 },
  { 2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9 }
};

const uint32_t blake_u256[16] =
{
  0x243f6a88, 0x85a308d3, 0x13198a2e, 0x03707344,
  0xa4093822, 0x299f31d0, 0x082efa98, 0xec4e6c89,
  0x452821e6, 0x38d01377, 0xbe5466cf, 0x34e90c6c,
  0xc0ac29b7, 0xc97c50dd, 0x3f84d5b5, 0xb5470917
};

#define ROT32(x,n) (((x)<<(32-n))|( (x)>>(n)))
//#define ROT32(x,n)   (rotate((uint)x, (uint)32-n))
#define ADD32(x,y)   ((uint32_t)((x) + (y)))
#define XOR32(x,y)   ((uint32_t)((x) ^ (y)))

#define G(a,b,c,d,i) \
do { \
  v[a] += XOR32(m[blake_sigma[r][i]], blake_u256[blake_sigma[r][i + 1]]) + v[b]; \
  v[d] = ROT32(XOR32(v[d], v[a]), 16); \
  v[c] += v[d]; \
  v[b] = ROT32(XOR32(v[b], v[c]), 12); \
  v[a] += XOR32(m[blake_sigma[r][i + 1]], blake_u256[blake_sigma[r][i]]) + v[b]; \
  v[d] = ROT32(XOR32(v[d], v[a]), 8); \
  v[c] += v[d]; \
  v[b] = ROT32(XOR32(v[b], v[c]), 7); \
} while (0)

// compress a block
void blake256_compress_block(blake_state256 *S, uint32_t *m)
{
  uint32_t v[16];
  int i, r;
  for (i = 0; i < 8; ++i)  v[i] = S->h[i];

  v[8] = blake_u256[0];
  v[9] = blake_u256[1];
  v[10] = blake_u256[2];
  v[11] = blake_u256[3];
  v[12] = blake_u256[4];
  v[13] = blake_u256[5];
  v[14] = blake_u256[6];
  v[15] = blake_u256[7];

  v[12] ^= S->t;
  v[13] ^= S->t;

  for (r = 0; r < NB_ROUNDS32; ++r)
  {
    /* column step */
    G(0, 4, 8, 12, 0);
    G(1, 5, 9, 13, 2);
    G(2, 6, 10, 14, 4);
    G(3, 7, 11, 15, 6);
    /* diagonal step */
    G(0, 5, 10, 15, 8);
    G(1, 6, 11, 12, 10);
    G(2, 7, 8, 13, 12);
    G(3, 4, 9, 14, 14);
  }

  for (i = 0; i < 16; ++i)  S->h[i & 7] ^= v[i];
}

void blake256_init(blake_state256 *S)
{
  S->h[0] = 0x6a09e667;
  S->h[1] = 0xbb67ae85;
  S->h[2] = 0x3c6ef372;
  S->h[3] = 0xa54ff53a;
  S->h[4] = 0x510e527f;
  S->h[5] = 0x9b05688c;
  S->h[6] = 0x1f83d9ab;
  S->h[7] = 0x5be0cd19;
  S->t = 0;
}

void blake256_update(blake_state256 *S, const uint32_t *in)
{
  uint32_t m[16];
  int i;
  S->t = 512;
  for (i = 0; i < 16; ++i)  m[i] = in[i];
  blake256_compress_block(S, m);
}

void precalc_hash_blake256(dev_blk_ctx *blk, uint32_t *state, uint32_t *data)
{
  blake_state256 S;
  blake256_init(&S);
  blake256_update(&S, data);

  blk->ctx_a = S.h[0];
  blk->ctx_b = S.h[1];
  blk->ctx_c = S.h[2];
  blk->ctx_d = S.h[3];
  blk->ctx_e = S.h[4];
  blk->ctx_f = S.h[5];
  blk->ctx_g = S.h[6];
  blk->ctx_h = S.h[7];

  blk->cty_a = data[16];
  blk->cty_b = data[17];
  blk->cty_c = data[18];
}