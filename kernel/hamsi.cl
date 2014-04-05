/* $Id: hamsi.c 251 2010-10-19 14:31:51Z tp $ */
/*
 * Hamsi implementation.
 *
 * ==========================(LICENSE BEGIN)============================
 *
 * Copyright (c) 2007-2010  Projet RNRT SAPHIR
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * ===========================(LICENSE END)=============================
 *
 * @author   Thomas Pornin <thomas.pornin@cryptolog.com>
 */

#if SPH_SMALL_FOOTPRINT && !defined SPH_SMALL_FOOTPRINT_HAMSI
#define SPH_SMALL_FOOTPRINT_HAMSI   1
#endif

/*
 * The SPH_HAMSI_EXPAND_* define how many input bits we handle in one
 * table lookup during message expansion (1 to 8, inclusive). If we note
 * w the number of bits per message word (w=32 for Hamsi-224/256, w=64
 * for Hamsi-384/512), r the size of a "row" in 32-bit words (r=8 for
 * Hamsi-224/256, r=16 for Hamsi-384/512), and n the expansion level,
 * then we will get t tables (where t=ceil(w/n)) of individual size
 * 2^n*r*4 (in bytes). The last table may be shorter (e.g. with w=32 and
 * n=5, there are 7 tables, but the last one uses only two bits on
 * input, not five).
 *
 * Also, we read t rows of r words from RAM. Words in a given row are
 * concatenated in RAM in that order, so most of the cost is about
 * reading the first row word; comparatively, cache misses are thus
 * less expensive with Hamsi-512 (r=16) than with Hamsi-256 (r=8).
 *
 * When n=1, tables are "special" in that we omit the first entry of
 * each table (which always contains 0), so that total table size is
 * halved.
 *
 * We thus have the following (size1 is the cumulative table size of
 * Hamsi-224/256; size2 is for Hamsi-384/512; similarly, t1 and t2
 * are for Hamsi-224/256 and Hamsi-384/512, respectively).
 *
 *   n      size1      size2    t1    t2
 * ---------------------------------------
 *   1       1024       4096    32    64
 *   2       2048       8192    16    32
 *   3       2688      10880    11    22
 *   4       4096      16384     8    16
 *   5       6272      25600     7    13
 *   6      10368      41984     6    11
 *   7      16896      73856     5    10
 *   8      32768     131072     4     8
 *
 * So there is a trade-off: a lower n makes the tables fit better in
 * L1 cache, but increases the number of memory accesses. The optimal
 * value depends on the amount of available L1 cache and the relative
 * impact of a cache miss.
 *
 * Experimentally, in ideal benchmark conditions (which are not necessarily
 * realistic with regards to L1 cache contention), it seems that n=8 is
 * the best value on "big" architectures (those with 32 kB or more of L1
 * cache), while n=4 is better on "small" architectures. This was tested
 * on an Intel Core2 Q6600 (both 32-bit and 64-bit mode), a PowerPC G3
 * (32 kB L1 cache, hence "big"), and a MIPS-compatible Broadcom BCM3302
 * (8 kB L1 cache).
 *
 * Note: with n=1, the 32 tables (actually implemented as one big table)
 * are read entirely and sequentially, regardless of the input data,
 * thus avoiding any data-dependent table access pattern.
 */

#if !defined SPH_HAMSI_EXPAND_SMALL
#if SPH_SMALL_FOOTPRINT_HAMSI
#define SPH_HAMSI_EXPAND_SMALL  4
#else
#define SPH_HAMSI_EXPAND_SMALL  8
#endif
#endif

#if !defined SPH_HAMSI_EXPAND_BIG
#define SPH_HAMSI_EXPAND_BIG    8
#endif

#ifdef _MSC_VER
#pragma warning (disable: 4146)
#endif

#include "hamsi_helper.cl"

__constant static const sph_u32 HAMSI_IV224[] = {
	SPH_C32(0xc3967a67), SPH_C32(0xc3bc6c20), SPH_C32(0x4bc3bcc3),
	SPH_C32(0xa7c3bc6b), SPH_C32(0x2c204b61), SPH_C32(0x74686f6c),
	SPH_C32(0x69656b65), SPH_C32(0x20556e69)
};

/*
 * This version is the one used in the Hamsi submission package for
 * round 2 of the SHA-3 competition; the UTF-8 encoding is wrong and
 * shall soon be corrected in the official Hamsi specification.
 *
__constant static const sph_u32 HAMSI_IV224[] = {
	SPH_C32(0x3c967a67), SPH_C32(0x3cbc6c20), SPH_C32(0xb4c343c3),
	SPH_C32(0xa73cbc6b), SPH_C32(0x2c204b61), SPH_C32(0x74686f6c),
	SPH_C32(0x69656b65), SPH_C32(0x20556e69)
};
 */

__constant static const sph_u32 HAMSI_IV256[] = {
	SPH_C32(0x76657273), SPH_C32(0x69746569), SPH_C32(0x74204c65),
	SPH_C32(0x7576656e), SPH_C32(0x2c204465), SPH_C32(0x70617274),
	SPH_C32(0x656d656e), SPH_C32(0x7420456c)
};

__constant static const sph_u32 HAMSI_IV384[] = {
	SPH_C32(0x656b7472), SPH_C32(0x6f746563), SPH_C32(0x686e6965),
	SPH_C32(0x6b2c2043), SPH_C32(0x6f6d7075), SPH_C32(0x74657220),
	SPH_C32(0x53656375), SPH_C32(0x72697479), SPH_C32(0x20616e64),
	SPH_C32(0x20496e64), SPH_C32(0x75737472), SPH_C32(0x69616c20),
	SPH_C32(0x43727970), SPH_C32(0x746f6772), SPH_C32(0x61706879),
	SPH_C32(0x2c204b61)
};

__constant static const sph_u32 HAMSI_IV512[] = {
	SPH_C32(0x73746565), SPH_C32(0x6c706172), SPH_C32(0x6b204172),
	SPH_C32(0x656e6265), SPH_C32(0x72672031), SPH_C32(0x302c2062),
	SPH_C32(0x75732032), SPH_C32(0x3434362c), SPH_C32(0x20422d33),
	SPH_C32(0x30303120), SPH_C32(0x4c657576), SPH_C32(0x656e2d48),
	SPH_C32(0x65766572), SPH_C32(0x6c65652c), SPH_C32(0x2042656c),
	SPH_C32(0x6769756d)
};

__constant static const sph_u32 alpha_n[] = {
	SPH_C32(0xff00f0f0), SPH_C32(0xccccaaaa), SPH_C32(0xf0f0cccc),
	SPH_C32(0xff00aaaa), SPH_C32(0xccccaaaa), SPH_C32(0xf0f0ff00),
	SPH_C32(0xaaaacccc), SPH_C32(0xf0f0ff00), SPH_C32(0xf0f0cccc),
	SPH_C32(0xaaaaff00), SPH_C32(0xccccff00), SPH_C32(0xaaaaf0f0),
	SPH_C32(0xaaaaf0f0), SPH_C32(0xff00cccc), SPH_C32(0xccccf0f0),
	SPH_C32(0xff00aaaa), SPH_C32(0xccccaaaa), SPH_C32(0xff00f0f0),
	SPH_C32(0xff00aaaa), SPH_C32(0xf0f0cccc), SPH_C32(0xf0f0ff00),
	SPH_C32(0xccccaaaa), SPH_C32(0xf0f0ff00), SPH_C32(0xaaaacccc),
	SPH_C32(0xaaaaff00), SPH_C32(0xf0f0cccc), SPH_C32(0xaaaaf0f0),
	SPH_C32(0xccccff00), SPH_C32(0xff00cccc), SPH_C32(0xaaaaf0f0),
	SPH_C32(0xff00aaaa), SPH_C32(0xccccf0f0)
};

__constant static const sph_u32 alpha_f[] = {
	SPH_C32(0xcaf9639c), SPH_C32(0x0ff0f9c0), SPH_C32(0x639c0ff0),
	SPH_C32(0xcaf9f9c0), SPH_C32(0x0ff0f9c0), SPH_C32(0x639ccaf9),
	SPH_C32(0xf9c00ff0), SPH_C32(0x639ccaf9), SPH_C32(0x639c0ff0),
	SPH_C32(0xf9c0caf9), SPH_C32(0x0ff0caf9), SPH_C32(0xf9c0639c),
	SPH_C32(0xf9c0639c), SPH_C32(0xcaf90ff0), SPH_C32(0x0ff0639c),
	SPH_C32(0xcaf9f9c0), SPH_C32(0x0ff0f9c0), SPH_C32(0xcaf9639c),
	SPH_C32(0xcaf9f9c0), SPH_C32(0x639c0ff0), SPH_C32(0x639ccaf9),
	SPH_C32(0x0ff0f9c0), SPH_C32(0x639ccaf9), SPH_C32(0xf9c00ff0),
	SPH_C32(0xf9c0caf9), SPH_C32(0x639c0ff0), SPH_C32(0xf9c0639c),
	SPH_C32(0x0ff0caf9), SPH_C32(0xcaf90ff0), SPH_C32(0xf9c0639c),
	SPH_C32(0xcaf9f9c0), SPH_C32(0x0ff0639c)
};

#define HAMSI_DECL_STATE_SMALL \
	sph_u32 c0, c1, c2, c3, c4, c5, c6, c7;

#define HAMSI_READ_STATE_SMALL(sc)   do { \
		c0 = h[0x0]; \
		c1 = h[0x1]; \
		c2 = h[0x2]; \
		c3 = h[0x3]; \
		c4 = h[0x4]; \
		c5 = h[0x5]; \
		c6 = h[0x6]; \
		c7 = h[0x7]; \
	} while (0)

#define HAMSI_WRITE_STATE_SMALL(sc)   do { \
		h[0x0] = c0; \
		h[0x1] = c1; \
		h[0x2] = c2; \
		h[0x3] = c3; \
		h[0x4] = c4; \
		h[0x5] = c5; \
		h[0x6] = c6; \
		h[0x7] = c7; \
	} while (0)

#define s0   m0
#define s1   m1
#define s2   c0
#define s3   c1
#define s4   c2
#define s5   c3
#define s6   m2
#define s7   m3
#define s8   m4
#define s9   m5
#define sA   c4
#define sB   c5
#define sC   c6
#define sD   c7
#define sE   m6
#define sF   m7

#define SBOX(a, b, c, d)   do { \
		sph_u32 t; \
		t = (a); \
		(a) &= (c); \
		(a) ^= (d); \
		(c) ^= (b); \
		(c) ^= (a); \
		(d) |= t; \
		(d) ^= (b); \
		t ^= (c); \
		(b) = (d); \
		(d) |= t; \
		(d) ^= (a); \
		(a) &= (b); \
		t ^= (a); \
		(b) ^= (d); \
		(b) ^= t; \
		(a) = (c); \
		(c) = (b); \
		(b) = (d); \
		(d) = SPH_T32(~t); \
	} while (0)

#define L(a, b, c, d)   do { \
		(a) = SPH_ROTL32(a, 13); \
		(c) = SPH_ROTL32(c, 3); \
		(b) ^= (a) ^ (c); \
		(d) ^= (c) ^ SPH_T32((a) << 3); \
		(b) = SPH_ROTL32(b, 1); \
		(d) = SPH_ROTL32(d, 7); \
		(a) ^= (b) ^ (d); \
		(c) ^= (d) ^ SPH_T32((b) << 7); \
		(a) = SPH_ROTL32(a, 5); \
		(c) = SPH_ROTL32(c, 22); \
	} while (0)

#define ROUND_SMALL(rc, alpha)   do { \
		s0 ^= alpha[0x00]; \
		s1 ^= alpha[0x01] ^ (sph_u32)(rc); \
		s2 ^= alpha[0x02]; \
		s3 ^= alpha[0x03]; \
		s4 ^= alpha[0x08]; \
		s5 ^= alpha[0x09]; \
		s6 ^= alpha[0x0A]; \
		s7 ^= alpha[0x0B]; \
		s8 ^= alpha[0x10]; \
		s9 ^= alpha[0x11]; \
		sA ^= alpha[0x12]; \
		sB ^= alpha[0x13]; \
		sC ^= alpha[0x18]; \
		sD ^= alpha[0x19]; \
		sE ^= alpha[0x1A]; \
		sF ^= alpha[0x1B]; \
		SBOX(s0, s4, s8, sC); \
		SBOX(s1, s5, s9, sD); \
		SBOX(s2, s6, sA, sE); \
		SBOX(s3, s7, sB, sF); \
		L(s0, s5, sA, sF); \
		L(s1, s6, sB, sC); \
		L(s2, s7, s8, sD); \
		L(s3, s4, s9, sE); \
	} while (0)

#define P_SMALL   do { \
		ROUND_SMALL(0, alpha_n); \
		ROUND_SMALL(1, alpha_n); \
		ROUND_SMALL(2, alpha_n); \
	} while (0)

#define PF_SMALL   do { \
		ROUND_SMALL(0, alpha_f); \
		ROUND_SMALL(1, alpha_f); \
		ROUND_SMALL(2, alpha_f); \
		ROUND_SMALL(3, alpha_f); \
		ROUND_SMALL(4, alpha_f); \
		ROUND_SMALL(5, alpha_f); \
	} while (0)

#define T_SMALL   do { \
		/* order is important */ \
		c7 = (h[7] ^= sB); \
		c6 = (h[6] ^= sA); \
		c5 = (h[5] ^= s9); \
		c4 = (h[4] ^= s8); \
		c3 = (h[3] ^= s3); \
		c2 = (h[2] ^= s2); \
		c1 = (h[1] ^= s1); \
		c0 = (h[0] ^= s0); \
	} while (0)

