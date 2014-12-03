/* NeoScrypt(128, 2, 1) with Salsa20/20 and ChaCha20/20 */
/* Adapted and improved for 14.x drivers by Wolf9466 (Wolf`) */

#define rotl(x,y) rotate(x,y)
#define Ch(x,y,z) bitselect(z,y,x)
#define Maj(x,y,z) Ch((x^z),y,z)
#define ROTR32(a,b) (((a) >> (b)) | ((a) << (32 - b)))
#define ROTL32(a,b) rotate(a,as_uint(b))

__constant uint ES[2] = { 0x00FF00FF, 0xFF00FF00 };
#define EndianSwap(n) (rotate(n & ES[0], 24U)|rotate(n & ES[1], 8U))

#define BLOCK_SIZE           64U
#define FASTKDF_BUFFER_SIZE 256U
#ifndef PASSWORD_LEN
#define PASSWORD_LEN         80U
#endif

#ifdef TEST
__constant uchar testsalt[]= {
135, 99, 188, 101, 252, 81, 54, 91, 243, 212, 78, 99, 46, 1, 113, 232, 9, 208, 203, 88, 25, 93, 218, 215, 53, 112, 105, 136, 238, 114, 242, 24, 194, 144, 239, 172, 37, 158, 113, 15, 116, 114, 47, 53, 51, 167, 178, 107, 192, 90, 92, 37, 59, 116, 234, 107, 80, 251, 2, 251, 145, 185, 119, 89, 115, 112, 94, 154, 117, 126, 233, 100, 15, 24, 246, 137, 220, 124, 244, 244, 129, 246, 244, 180, 78, 247, 146, 229, 69, 177, 143, 94, 2, 144, 63, 33, 89, 136, 234, 174, 38, 37, 183, 62, 176, 243, 136, 30, 249, 195, 129, 227, 146, 216, 38, 118, 185, 43, 175, 217, 246, 203, 251, 211, 222, 237, 21, 231, 133, 218, 206, 9, 148, 229, 20, 229, 101, 146, 183, 120, 155, 91, 16, 10, 86, 198, 185, 179, 1, 197, 69, 95, 44, 133, 49, 225, 2, 115, 182, 6, 82, 166, 35, 3, 19, 59, 193, 253, 14, 239, 65, 79, 105, 154, 70, 146, 169, 233, 227, 20, 66, 15, 52, 223, 228, 202, 158, 207, 6, 245, 204, 212, 220, 108, 204, 39, 136, 66, 215, 186, 247, 184, 92, 171, 56, 166, 162, 105, 126, 162, 127, 175, 181, 227, 236, 233, 127, 219, 115, 30, 136, 108, 169, 14, 172, 71, 82, 250, 141, 209, 98, 216, 221, 165, 132, 146, 98, 76, 194, 239, 123, 90, 91, 193, 58, 121, 235, 161, 51, 144, 5, 41, 216, 160, 93, 173
};
#endif

/* When changing the optimal type, make sure the loops unrolled
	in _blkcopy, _blkswp and _blkxor are modified accordingly. */
#define OPTIMAL_TYPE uint

/* Fast 32-bit / 64-bit memcpy();
 * len must be a multiple of 32 bytes */
void neoscrypt_blkcpy(void *dstp, const void *srcp, uint len) {
    OPTIMAL_TYPE *dst = (OPTIMAL_TYPE *) dstp;
    OPTIMAL_TYPE *src = (OPTIMAL_TYPE *) srcp;
    uint i;

#ifdef WITH_UNROLL
#pragma unroll(1<< max(0, (32- sizeof(OPTIMAL_TYPE))>> 2))
    for(i = 0; i < (len / sizeof(OPTIMAL_TYPE)); ++i)
        dst[i]     = src[i];
#else
	for(i = 0; i < (len / sizeof(OPTIMAL_TYPE)); i += 4) {
        dst[i]     = src[i];
        dst[i + 1] = src[i + 1];
        dst[i + 2] = src[i + 2];
        dst[i + 3] = src[i + 3];
    }
#endif
}
void neoscrypt_gl_blkcpy(__global void *dstp, const void *srcp, uint len) {
    __global OPTIMAL_TYPE *dst = (__global OPTIMAL_TYPE *) dstp;
    OPTIMAL_TYPE *src = (OPTIMAL_TYPE *) srcp;
    uint i;

    for(i = 0; i < (len / sizeof(OPTIMAL_TYPE)); i += 4) {
        dst[i]     = src[i];
        dst[i + 1] = src[i + 1];
        dst[i + 2] = src[i + 2];
        dst[i + 3] = src[i + 3];
    }
}

/* Fast 32-bit / 64-bit block swapper;
 * len must be a multiple of 32 bytes */
void neoscrypt_blkswp(void *blkAp, void *blkBp, uint len) {
    OPTIMAL_TYPE *blkA = (OPTIMAL_TYPE *) blkAp;
    OPTIMAL_TYPE *blkB = (OPTIMAL_TYPE *) blkBp;
    OPTIMAL_TYPE t0, t1, t2, t3;
    uint i;

    for(i = 0; i < (len / sizeof(OPTIMAL_TYPE)); i += 4) {
        t0          = blkA[i];
        t1          = blkA[i + 1];
        t2          = blkA[i + 2];
        t3          = blkA[i + 3];
        blkA[i]     = blkB[i];
        blkA[i + 1] = blkB[i + 1];
        blkA[i + 2] = blkB[i + 2];
        blkA[i + 3] = blkB[i + 3];
        blkB[i]     = t0;
        blkB[i + 1] = t1;
        blkB[i + 2] = t2;
        blkB[i + 3] = t3;
    }
}

/* Fast 32-bit / 64-bit block XOR engine;
 * len must be a multiple of 32 bytes */
void neoscrypt_blkxor(void *dstp, const void *srcp, uint len) {
    OPTIMAL_TYPE *dst = (OPTIMAL_TYPE *) dstp;
    OPTIMAL_TYPE *src = (OPTIMAL_TYPE *) srcp;
    uint i;

    for(i = 0; i < (len / sizeof(OPTIMAL_TYPE)); i += 4) {
        dst[i]     ^= src[i];
        dst[i + 1] ^= src[i + 1];
        dst[i + 2] ^= src[i + 2];
        dst[i + 3] ^= src[i + 3];
    }
}

void neoscrypt_gl_blkxor(void *dstp, __global void *srcp, uint len) {
    OPTIMAL_TYPE *dst = (OPTIMAL_TYPE *) dstp;
    __global OPTIMAL_TYPE *src = (__global OPTIMAL_TYPE *) srcp;
    uint i;

    for(i = 0; i < (len / sizeof(OPTIMAL_TYPE)); i += 4) {
        dst[i]     ^= src[i];
        dst[i + 1] ^= src[i + 1];
        dst[i + 2] ^= src[i + 2];
        dst[i + 3] ^= src[i + 3];
    }
}

/* 32-bit / 64-bit / 128-bit optimised memcpy() */
void neoscrypt_copy(void *dstp, const void *srcp, uint len) {
    OPTIMAL_TYPE *dst = (OPTIMAL_TYPE *) dstp;
    OPTIMAL_TYPE *src = (OPTIMAL_TYPE *) srcp;
    uint i, tail;
	const uint c_len= len/ sizeof(OPTIMAL_TYPE);

    for(i= 0; i< c_len; ++i)
		dst[i] = src[i];

    tail= len- c_len* sizeof(OPTIMAL_TYPE);
    if(tail) {
#if defined(cl_khr_byte_addressable_store) && !defined(FORCE_BYTE_COPY)
		uchar *dstb = (uchar *) dstp;
        uchar *srcb = (uchar *) srcp;

        for(i= len- tail; i< len; i++)
			dstb[i] = srcb[i];
#else
		uint *dsti = (uint *) dstp;
		uint *srci = (uint *) srcp;

		for(i*= (sizeof(OPTIMAL_TYPE)/ sizeof(uint)); i< (len>> 2); ++i)
			dsti[i] = srci[i];
#endif
	}
}

/* 32-bit / 64-bit / 128-bit optimised memcpy() */
void neoscrypt_gl_copy(__global uchar *dstp, const void *srcp, uint len) {
    __global OPTIMAL_TYPE *dst = (__global OPTIMAL_TYPE *) dstp;
    OPTIMAL_TYPE *src = (OPTIMAL_TYPE *) srcp;
    uint i, tail;

    for(i = 0; i < (len / sizeof(OPTIMAL_TYPE)); i++)
      dst[i] = src[i];

    tail = len & (sizeof(OPTIMAL_TYPE) - 1);
    if(tail) {
        uchar *srcb = (uchar *) srcp;

        for(i = len - tail; i < len; i++)
          dstp[i] = srcb[i];
    }
}

/* 32-bit / 64-bit optimised memory erase aka memset() to zero */
void neoscrypt_erase(void *dstp, uint len) {
    const OPTIMAL_TYPE null = 0;
    OPTIMAL_TYPE *dst = (OPTIMAL_TYPE *) dstp;
    uint i, tail;

    for(i = 0; i < (len / sizeof(OPTIMAL_TYPE)); i++)
      dst[i] = null;

    tail = len & (sizeof(OPTIMAL_TYPE) - 1);
    if(tail) {
#if defined(cl_khr_byte_addressable_store) && !defined(FORCE_BYTE_COPY)
        uchar *dstb = (uchar *) dstp;

        for(i = len - tail; i < len; i++)
			dstb[i] = 0u;
#else
		uint *dsti = (uint *) dstp;

		for(i*= sizeof(OPTIMAL_TYPE)/ sizeof(uint); i< (len>> 2); ++i)
			dsti[i] = 0u;
#endif
    }
}

/* 32-bit / 64-bit optimised XOR engine */
void neoscrypt_xor(void *dstp, const void *srcp, uint len) {
    OPTIMAL_TYPE *dst = (OPTIMAL_TYPE *) dstp;
    OPTIMAL_TYPE *src = (OPTIMAL_TYPE *) srcp;
    uint i, tail;
	const unsigned c_len= len/ sizeof(OPTIMAL_TYPE);

    for(i= 0; i< c_len; ++i)
		dst[i]^= src[i];

	//tail = len & (sizeof(OPTIMAL_TYPE) - 1);
    tail= len- c_len* sizeof(OPTIMAL_TYPE);
    if(tail) {
#if defined(cl_khr_byte_addressable_store) && !defined(FORCE_BYTE_COPY)
        uchar *dstb = (uchar *) dstp;
        uchar *srcb = (uchar *) srcp;

        for(i = len - tail; i < len; i++)
          dstb[i] ^= srcb[i];
#else
		uint *dsti = (uint *) dstp;
		uint *srci = (uint *) srcp;

		for(i*= (sizeof(OPTIMAL_TYPE)/ sizeof(uint)); i < (len>> 2); ++i)
			dsti[i]^= srci[i];
#endif
    }
}

/* BLAKE2s */

#define BLAKE2S_BLOCK_SIZE    64U
#define BLAKE2S_OUT_SIZE      32U
#define BLAKE2S_KEY_SIZE      32U

/* Parameter block of 32 bytes */
typedef struct blake2s_param_t {
    uchar digest_length;
    uchar key_length;
    uchar fanout;
    uchar depth;
    uint  leaf_length;
    uchar node_offset[6];
    uchar node_depth;
    uchar inner_length;
    uchar salt[8];
    uchar personal[8];
} blake2s_param;

/* State block of 180 bytes */
typedef struct blake2s_state_t {
    uint  h[8];
    uint  t[2];
    uint  f[2];
    uchar buf[2 * BLAKE2S_BLOCK_SIZE];
    uint  buflen;
} blake2s_state;

__constant uint blake2s_IV[8] = {
    0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
    0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19
};

__constant uchar blake2s_sigma[10][16] = {
    {  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15 } ,
    { 14, 10,  4,  8,  9, 15, 13,  6,  1, 12,  0,  2, 11,  7,  5,  3 } ,
    { 11,  8, 12,  0,  5,  2, 15, 13, 10, 14,  3,  6,  7,  1,  9,  4 } ,
    {  7,  9,  3,  1, 13, 12, 11, 14,  2,  6,  5, 10,  4,  0, 15,  8 } ,
    {  9,  0,  5,  7,  2,  4, 10, 15, 14,  1, 11, 12,  6,  8,  3, 13 } ,
    {  2, 12,  6, 10,  0, 11,  8,  3,  4, 13,  7,  5, 15, 14,  1,  9 } ,
    { 12,  5,  1, 15, 14, 13,  4, 10,  0,  7,  6,  3,  9,  2,  8, 11 } ,
    { 13, 11,  7, 14, 12,  1,  3,  9,  5,  0, 15,  4,  8,  6,  2, 10 } ,
    {  6, 15, 14,  9, 11,  3,  0,  8, 12,  2, 13,  7,  1,  4, 10,  5 } ,
    { 10,  2,  8,  4,  7,  6,  1,  5, 15, 11,  9, 14,  3, 12, 13 , 0 } ,
};

void blake2s_compress(blake2s_state *S, const uint *buf) {
    uint i;
    uint m[16];
    uint v[16];

    neoscrypt_copy(m, buf, 64);
    neoscrypt_copy(v, S->h, 32);

    v[ 8] = blake2s_IV[0];
    v[ 9] = blake2s_IV[1];
    v[10] = blake2s_IV[2];
    v[11] = blake2s_IV[3];
    v[12] = S->t[0] ^ blake2s_IV[4];
    v[13] = S->t[1] ^ blake2s_IV[5];
    v[14] = S->f[0] ^ blake2s_IV[6];
    v[15] = S->f[1] ^ blake2s_IV[7];
#define G(r,i,a,b,c,d) \
  do { \
    a = a + b + m[blake2s_sigma[r][2*i+0]]; \
    d = ROTR32(d ^ a, 16); \
    c = c + d; \
    b = ROTR32(b ^ c, 12); \
    a = a + b + m[blake2s_sigma[r][2*i+1]]; \
    d = ROTR32(d ^ a, 8); \
    c = c + d; \
    b = ROTR32(b ^ c, 7); \
  } while(0)
#define ROUND(r) \
  do { \
    G(r, 0, v[ 0], v[ 4], v[ 8], v[12]); \
    G(r, 1, v[ 1], v[ 5], v[ 9], v[13]); \
    G(r, 2, v[ 2], v[ 6], v[10], v[14]); \
    G(r, 3, v[ 3], v[ 7], v[11], v[15]); \
    G(r, 4, v[ 0], v[ 5], v[10], v[15]); \
    G(r, 5, v[ 1], v[ 6], v[11], v[12]); \
    G(r, 6, v[ 2], v[ 7], v[ 8], v[13]); \
    G(r, 7, v[ 3], v[ 4], v[ 9], v[14]); \
  } while(0)
    ROUND(0);
    ROUND(1);
    ROUND(2);
    ROUND(3);
    ROUND(4);
    ROUND(5);
    ROUND(6);
    ROUND(7);
    ROUND(8);
    ROUND(9);

  for(i = 0; i < 8; i++)
    S->h[i] = S->h[i] ^ v[i] ^ v[i + 8];

#undef G
#undef ROUND
}

void blake2s_update(blake2s_state *S, const uchar *input, uint input_size) {
    uint left, fill;

    while(input_size > 0) {
        left = S->buflen;
        fill = 2 * BLAKE2S_BLOCK_SIZE - left;
        if(input_size > fill) {
            /* Buffer fill */
            neoscrypt_copy(&S->buf[left], input, fill);
            S->buflen += fill;
            /* Counter increment */
            S->t[0] += BLAKE2S_BLOCK_SIZE;
            /* Compress */
            blake2s_compress(S, (uint *) S->buf);
            /* Shift buffer left */
			neoscrypt_copy(S->buf, &S->buf[BLAKE2S_BLOCK_SIZE], BLAKE2S_BLOCK_SIZE);
            S->buflen -= BLAKE2S_BLOCK_SIZE;
            input += fill;
            input_size -= fill;
        } else {
            neoscrypt_copy(&S->buf[left], input, input_size);
            S->buflen += input_size;
            /* Do not compress */
            //input += input_size;
            input_size = 0;
        }
    }
}

void blake2s(const void *input, const uint input_size,
					   const void *key, const uchar key_size,
					   void *output, const uchar output_size) {
    uchar block[BLAKE2S_BLOCK_SIZE];
    blake2s_param P;
    blake2s_state S;

    /* Initialise */
    neoscrypt_erase(&P, sizeof(blake2s_param));
    P.digest_length = output_size;
    P.key_length    = key_size;
    P.fanout        = 1;
    P.depth         = 1;

    neoscrypt_erase(&S, sizeof(blake2s_state));
	// Initialize the state
	for(int i= 0; i< 8; ++i)
		S.h[i]= blake2s_IV[i];
	// neoscrypt_xor(&S, &P, 32);
	S.h[0]^= ((uint)output_size)| (((uint)key_size)<< 8)| (1U<< 16)| (1U<< 24);
	// All other values of P are unset yet.

    neoscrypt_erase(block, BLAKE2S_BLOCK_SIZE);
    neoscrypt_copy(block, key, key_size);
    blake2s_update(&S, block, BLAKE2S_BLOCK_SIZE);
    /* Update */
    blake2s_update(&S, (uchar *) input, input_size);

    /* Finish */
    if(S.buflen > BLAKE2S_BLOCK_SIZE) {
        S.t[0] += BLAKE2S_BLOCK_SIZE;
        blake2s_compress(&S, (uint *) S.buf);
        S.buflen -= BLAKE2S_BLOCK_SIZE;
        neoscrypt_copy(S.buf, &S.buf[BLAKE2S_BLOCK_SIZE], S.buflen);
    }
    S.t[0] += S.buflen;
    S.f[0] = ~0U;
    neoscrypt_erase(&S.buf[S.buflen], 2 * BLAKE2S_BLOCK_SIZE - S.buflen);
    blake2s_compress(&S, (uint *) S.buf);
    /* Write back */
    neoscrypt_copy(output, S.h, output_size);
}

/* FastKDF, a fast buffered key derivation function:
 * FASTKDF_BUFFER_SIZE must be a power of 2;
 * password_len, salt_len and output_len should not exceed FASTKDF_BUFFER_SIZE;
 * prf_output_size must be <= prf_key_size; */
void fastkdf(const uchar *password, const uchar *salt, const uint salt_len,
			 uint N, uchar *output, uint output_len) {

	/*                    WARNING!
	 * This algorithm uses byte-wise addressing for memory blocks.
	 * Or in other words, trying to copy an unaligned memory region
	 * will significantly slow down the algorithm, when copying uses
	 * words or bigger entities. It even may corrupt the data, when
	 * the device does not support it properly.
	 * Therefore use byte copying, which will not the fastest but at
	 * least get reliable results. */

	// BLOCK_SIZE            64U
	// FASTKDF_BUFFER_SIZE  256U
	// BLAKE2S_BLOCK_SIZE    64U
	// BLAKE2S_KEY_SIZE      32U
	// BLAKE2S_OUT_SIZE      32U
	uchar A[FASTKDF_BUFFER_SIZE + BLAKE2S_BLOCK_SIZE];
	uchar B[FASTKDF_BUFFER_SIZE + BLAKE2S_KEY_SIZE];
	uchar prf_output[BLAKE2S_OUT_SIZE], prf_input[BLAKE2S_BLOCK_SIZE],
		prf_key[BLAKE2S_KEY_SIZE];
	uint bufidx, a, b, i, j;

	/* Initialise the password buffer */
	a = FASTKDF_BUFFER_SIZE / PASSWORD_LEN;
	for(i = 0, j= 0; i < a; ++i, j+= PASSWORD_LEN)
		neoscrypt_copy(&A[j], (uchar *)password, PASSWORD_LEN);
	b= FASTKDF_BUFFER_SIZE- j;
	if(b)
		neoscrypt_copy(&A[j], (uchar *)password, b);
#if (PASSWORD_LEN< BLAKE2S_BLOCK_SIZE)
	/* Initialise the password buffer */
	a = BLAKE2S_BLOCK_SIZE / PASSWORD_LEN;
	for(i = 0, j= 0; i < a; ++i, j+= PASSWORD_LEN)
		neoscrypt_copy(&A[j], (uchar *)password, PASSWORD_LEN);
	b= BLAKE2S_BLOCK_SIZE- j;
	if(b)
		neoscrypt_copy(&A[j], (uchar *)password, b);
	//neoscrypt_copy(&A[FASTKDF_BUFFER_SIZE], (uchar *)password, PASSWORD_LEN);
	//// Erase the remainder of the blake-block, when the password length is smaller
	//neoscrypt_erase(&A[FASTKDF_BUFFER_SIZE+ PASSWORD_LEN], BLAKE2S_BLOCK_SIZE- PASSWORD_LEN);
#else
	neoscrypt_copy(&A[FASTKDF_BUFFER_SIZE], (uchar *)password, BLAKE2S_BLOCK_SIZE);
#endif

	/* Initialise the salt buffer */
	a = FASTKDF_BUFFER_SIZE/ salt_len;
	for(i = 0, j= 0; i< a; ++i, j+= salt_len)
		neoscrypt_copy(&B[j], salt, salt_len);
	b= FASTKDF_BUFFER_SIZE- j;
	if(b)
		neoscrypt_copy(&B[j], (uchar *)salt, b);
	if(salt_len< BLAKE2S_BLOCK_SIZE) {
		neoscrypt_copy(&B[FASTKDF_BUFFER_SIZE], (uchar *)salt, salt_len);
		// Erase the remainder of the blake-block, when the password length is smaller
		neoscrypt_erase(&B[FASTKDF_BUFFER_SIZE+ salt_len], BLAKE2S_BLOCK_SIZE- salt_len);
	} else
		neoscrypt_copy(&B[FASTKDF_BUFFER_SIZE], salt, BLAKE2S_KEY_SIZE);

    /* The primary iteration */
    for(i = 0, bufidx = 0; i < N; ++i) {
		/* Copy the PRF input buffer byte by byte to make sure prf_input
			starts at a well aligned address. Missing to do so may slow down
			computation. */
		for(j= 0, a= bufidx; j< BLAKE2S_BLOCK_SIZE; ++j, ++a)
			prf_input[j]= A[a];

		/* Copy the PRF key buffer */
		for(j= 0, a= bufidx; j< BLAKE2S_KEY_SIZE; ++j, ++a)
			prf_key[j]= B[a];

        /* PRF */
        blake2s(prf_input, BLAKE2S_BLOCK_SIZE,
			prf_key, BLAKE2S_KEY_SIZE,
			prf_output, BLAKE2S_OUT_SIZE);

        /* Calculate the next buffer pointer */
        for(j = 0, bufidx = 0; j < BLAKE2S_OUT_SIZE; j++)
			bufidx += prf_output[j];
        bufidx &= (FASTKDF_BUFFER_SIZE - 1);

        /* Modify the salt buffer */
        //neoscrypt_xor(&B[bufidx], &prf_output[0], BLAKE2S_OUT_SIZE);
		for(j= 0, a= bufidx; j< BLAKE2S_OUT_SIZE; ++j, ++a)
			B[a]^= prf_output[j];

        /* Head modified, tail updated */
        if(bufidx < BLAKE2S_KEY_SIZE)
			//neoscrypt_copy(&B[FASTKDF_BUFFER_SIZE + bufidx], &B[bufidx],
			//	min(BLAKE2S_OUT_SIZE, BLAKE2S_KEY_SIZE - bufidx));
			for(j= 0, a= FASTKDF_BUFFER_SIZE + bufidx, b= bufidx;
					j< min(BLAKE2S_OUT_SIZE, BLAKE2S_KEY_SIZE- bufidx); ++j, ++a, ++b)
				B[a]= B[b];

        /* Tail modified, head updated */
        if((FASTKDF_BUFFER_SIZE - bufidx) < BLAKE2S_OUT_SIZE)
			neoscrypt_copy(B, &B[FASTKDF_BUFFER_SIZE],
				BLAKE2S_OUT_SIZE - (FASTKDF_BUFFER_SIZE - bufidx));

    }

    /* Modify and copy into the output buffer */
    if(output_len > FASTKDF_BUFFER_SIZE)
		output_len = FASTKDF_BUFFER_SIZE;

    a = FASTKDF_BUFFER_SIZE - bufidx;
	if(a >= output_len) {
		for(j= 0, i= bufidx; j< output_len; ++j, ++i)
			output[j]= B[i]^ A[j];
    } else {
		for(j= 0, i= bufidx; j< a; ++j, ++i)
			output[j]= B[i]^ A[j];
		for(j= a, i= 0; i< output_len- a; ++j, ++i)
			output[j]= B[i]^ A[j];
    }
}

uint16 neoscrypt_salsa(uint16 X)
{
	uint16 tmp = X;

	for(int i = 0; i < 10; ++i)
	{
		tmp.s4 ^= rotate(tmp.s0 + tmp.sc, 7U); tmp.s8 ^= rotate(tmp.s4 + tmp.s0, 9U); tmp.sc ^= rotate(tmp.s8 + tmp.s4, 13U); tmp.s0 ^= rotate(tmp.sc + tmp.s8, 18U);
		tmp.s9 ^= rotate(tmp.s5 + tmp.s1, 7U); tmp.sd ^= rotate(tmp.s9 + tmp.s5, 9U); tmp.s1 ^= rotate(tmp.sd + tmp.s9, 13U); tmp.s5 ^= rotate(tmp.s1 + tmp.sd, 18U);
		tmp.se ^= rotate(tmp.sa + tmp.s6, 7U); tmp.s2 ^= rotate(tmp.se + tmp.sa, 9U); tmp.s6 ^= rotate(tmp.s2 + tmp.se, 13U); tmp.sa ^= rotate(tmp.s6 + tmp.s2, 18U);
		tmp.s3 ^= rotate(tmp.sf + tmp.sb, 7U); tmp.s7 ^= rotate(tmp.s3 + tmp.sf, 9U); tmp.sb ^= rotate(tmp.s7 + tmp.s3, 13U); tmp.sf ^= rotate(tmp.sb + tmp.s7, 18U);
		tmp.s1 ^= rotate(tmp.s0 + tmp.s3, 7U); tmp.s2 ^= rotate(tmp.s1 + tmp.s0, 9U); tmp.s3 ^= rotate(tmp.s2 + tmp.s1, 13U); tmp.s0 ^= rotate(tmp.s3 + tmp.s2, 18U);
		tmp.s6 ^= rotate(tmp.s5 + tmp.s4, 7U); tmp.s7 ^= rotate(tmp.s6 + tmp.s5, 9U); tmp.s4 ^= rotate(tmp.s7 + tmp.s6, 13U); tmp.s5 ^= rotate(tmp.s4 + tmp.s7, 18U);
		tmp.sb ^= rotate(tmp.sa + tmp.s9, 7U); tmp.s8 ^= rotate(tmp.sb + tmp.sa, 9U); tmp.s9 ^= rotate(tmp.s8 + tmp.sb, 13U); tmp.sa ^= rotate(tmp.s9 + tmp.s8, 18U);
		tmp.sc ^= rotate(tmp.sf + tmp.se, 7U); tmp.sd ^= rotate(tmp.sc + tmp.sf, 9U); tmp.se ^= rotate(tmp.sd + tmp.sc, 13U); tmp.sf ^= rotate(tmp.se + tmp.sd, 18U);
	}

	return(X + tmp);
}

uint16 neoscrypt_chacha(uint16 X)
{
   uint16 tmp = X;

	for(int i = 0; i < 10; ++i)
	{
		tmp.s0 += tmp.s4; tmp.sc = rotate(tmp.sc ^ tmp.s0, 16U); tmp.s8 += tmp.sc; tmp.s4 = rotate(tmp.s4 ^ tmp.s8, 12U); tmp.s0 += tmp.s4; tmp.sc = rotate(tmp.sc ^ tmp.s0, 8U); tmp.s8 += tmp.sc; tmp.s4 = rotate(tmp.s4 ^ tmp.s8, 7U);
		tmp.s1 += tmp.s5; tmp.sd = rotate(tmp.sd ^ tmp.s1, 16U); tmp.s9 += tmp.sd; tmp.s5 = rotate(tmp.s5 ^ tmp.s9, 12U); tmp.s1 += tmp.s5; tmp.sd = rotate(tmp.sd ^ tmp.s1, 8U); tmp.s9 += tmp.sd; tmp.s5 = rotate(tmp.s5 ^ tmp.s9, 7U);
		tmp.s2 += tmp.s6; tmp.se = rotate(tmp.se ^ tmp.s2, 16U); tmp.sa += tmp.se; tmp.s6 = rotate(tmp.s6 ^ tmp.sa, 12U); tmp.s2 += tmp.s6; tmp.se = rotate(tmp.se ^ tmp.s2, 8U); tmp.sa += tmp.se; tmp.s6 = rotate(tmp.s6 ^ tmp.sa, 7U);
		tmp.s3 += tmp.s7; tmp.sf = rotate(tmp.sf ^ tmp.s3, 16U); tmp.sb += tmp.sf; tmp.s7 = rotate(tmp.s7 ^ tmp.sb, 12U); tmp.s3 += tmp.s7; tmp.sf = rotate(tmp.sf ^ tmp.s3, 8U); tmp.sb += tmp.sf; tmp.s7 = rotate(tmp.s7 ^ tmp.sb, 7U);
		tmp.s0 += tmp.s5; tmp.sf = rotate(tmp.sf ^ tmp.s0, 16U); tmp.sa += tmp.sf; tmp.s5 = rotate(tmp.s5 ^ tmp.sa, 12U); tmp.s0 += tmp.s5; tmp.sf = rotate(tmp.sf ^ tmp.s0, 8U); tmp.sa += tmp.sf; tmp.s5 = rotate(tmp.s5 ^ tmp.sa, 7U);
		tmp.s1 += tmp.s6; tmp.sc = rotate(tmp.sc ^ tmp.s1, 16U); tmp.sb += tmp.sc; tmp.s6 = rotate(tmp.s6 ^ tmp.sb, 12U); tmp.s1 += tmp.s6; tmp.sc = rotate(tmp.sc ^ tmp.s1, 8U); tmp.sb += tmp.sc; tmp.s6 = rotate(tmp.s6 ^ tmp.sb, 7U);
		tmp.s2 += tmp.s7; tmp.sd = rotate(tmp.sd ^ tmp.s2, 16U); tmp.s8 += tmp.sd; tmp.s7 = rotate(tmp.s7 ^ tmp.s8, 12U); tmp.s2 += tmp.s7; tmp.sd = rotate(tmp.sd ^ tmp.s2, 8U); tmp.s8 += tmp.sd; tmp.s7 = rotate(tmp.s7 ^ tmp.s8, 7U);
		tmp.s3 += tmp.s4; tmp.se = rotate(tmp.se ^ tmp.s3, 16U); tmp.s9 += tmp.se; tmp.s4 = rotate(tmp.s4 ^ tmp.s9, 12U); tmp.s3 += tmp.s4; tmp.se = rotate(tmp.se ^ tmp.s3, 8U); tmp.s9 += tmp.se; tmp.s4 = rotate(tmp.s4 ^ tmp.s9, 7U);
	}

    return(X + tmp);
}

void neoscrypt_blkmix(uint16 *XV, uint mixmode)
{

    /* NeoScrypt flow:                   Scrypt flow:
         Xa ^= Xd;  M(Xa'); Ya = Xa";      Xa ^= Xb;  M(Xa'); Ya = Xa";
         Xb ^= Xa"; M(Xb'); Yb = Xb";      Xb ^= Xa"; M(Xb'); Yb = Xb";
         Xc ^= Xb"; M(Xc'); Yc = Xc";      Xa" = Ya;
         Xd ^= Xc"; M(Xd'); Yd = Xd";      Xb" = Yb;
         Xa" = Ya; Xb" = Yc;
         Xc" = Yb; Xd" = Yd; */

	XV[0] ^= XV[3];

	if(!mixmode) XV[0] = neoscrypt_salsa(XV[0]);
	else XV[0] = neoscrypt_chacha(XV[0]);

	XV[1] ^= XV[0];

	if(!mixmode) XV[1] = neoscrypt_salsa(XV[1]);
	else XV[1] = neoscrypt_chacha(XV[1]);

	XV[2] ^= XV[1];

	if(!mixmode) XV[2] = neoscrypt_salsa(XV[2]);
	else XV[2] = neoscrypt_chacha(XV[2]);

	XV[3] ^= XV[2];

	if(!mixmode) XV[3] = neoscrypt_salsa(XV[3]);
	else XV[3] = neoscrypt_chacha(XV[3]);

	neoscrypt_blkswp(&XV[1], &XV[2], BLOCK_SIZE);
}

/* NeoScrypt core engine:
 * p = 1, salt = password;
 * Basic customisation (required):
 *   profile bit 0:
 *     0 = NeoScrypt(128, 2, 1) with Salsa20/20 and ChaCha20/20;
 *     1 = Scrypt(1024, 1, 1) with Salsa20/8;
 *   profile bits 4 to 1:
 *     0000 = FastKDF-BLAKE2s;
 *     0001 = PBKDF2-HMAC-SHA256;
 *     0010 = PBKDF2-HMAC-BLAKE256;
 * Extended customisation (optional):
 *   profile bit 31:
 *     0 = extended customisation absent;
 *     1 = extended customisation present;
 *   profile bits 7 to 5 (rfactor):
 *     000 = r of 1;
 *     001 = r of 2;
 *     010 = r of 4;
 *     ...
 *     111 = r of 128;
 *   profile bits 12 to 8 (Nfactor):
 *     00000 = N of 2;
 *     00001 = N of 4;
 *     00010 = N of 8;
 *     .....
 *     00110 = N of 128;
 *     .....
 *     01001 = N of 1024;
 *     .....
 *     11110 = N of 2147483648;
 *   profile bits 30 to 13 are reserved */
__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search(__global const uchar* restrict input,
#ifdef TEST
		__global uchar* restrict output,
#else
		volatile __global uint* restrict output,
#endif
		__global uchar* padcache,
		const uint target)
{
#define CONSTANT_N 128
#define CONSTANT_r 2
	/* Ensure stack alignment by putting those first. */
	/* X = CONSTANT_r * 2 * BLOCK_SIZE(64)  */
	uchar X[FASTKDF_BUFFER_SIZE];
	/* Z is a copy of X for ChaCha */
	uchar Z[FASTKDF_BUFFER_SIZE];
	/* V = CONSTANT_N * CONSTANT_r * 2 * BLOCK_SIZE */
	__global uchar *V= &padcache[CONSTANT_N * CONSTANT_r * 2 * BLOCK_SIZE*
		(get_global_id(0)% MAX_GLOBAL_THREADS)];
#ifndef TEST
	uchar outbuf[32];
	uchar data[PASSWORD_LEN];
	uint i, j;
	for(i= 0; i< PASSWORD_LEN- 4; ++i)
		data[i]= input[i];
	((uint *)data)[(PASSWORD_LEN- 4)/ sizeof(uint)]= get_global_id(0);
#else
	uchar outbuf[OUTPUT_LEN];
	uchar data[PASSWORD_LEN];
	uint i, j;
	for(i= 0; i< PASSWORD_LEN; ++i)
		data[i]= input[i];
#endif
    const uint mixmode = 0x14;

#ifdef TEST
#ifdef BLAKE2S_TEST
	blake2s(data, 64, data, 32, outbuf, OUTPUT_LEN);
	for(i= 0; i< OUTPUT_LEN; ++i)
		output[i]= outbuf[i];
	return;
#elif defined(FASTKDF_TEST)
	for(i= 0; i< FASTKDF_BUFFER_SIZE; ++i)
		X[i]= testsalt[i];
	fastkdf(data, X, FASTKDF_BUFFER_SIZE, 32, outbuf, 32);
	for(i= 0; i< OUTPUT_LEN; ++i)
		output[i]= outbuf[i];
	return;
#endif
#endif

    /* X = KDF(password, salt) */
	fastkdf(data, data, PASSWORD_LEN, 32, X, CONSTANT_r * 2 * BLOCK_SIZE);

    /* Process ChaCha 1st, Salsa 2nd and XOR them into PBKDF2 */
	neoscrypt_blkcpy(Z, X, CONSTANT_r * 2 * BLOCK_SIZE);

	for(int y = 0; y < 2; ++y)
    {
		for(i = 0; i < 128; ++i)
		{
			neoscrypt_gl_blkcpy(&V[i << 8], &X[0], 256);
			neoscrypt_blkmix((uint16 *)X, y);
		}

		for(i = 0; i < 128; ++i)
		{
			neoscrypt_gl_blkxor(&X[0], &V[(((uint *)X)[48] & 127) << 8], 256);
			neoscrypt_blkmix((uint16 *)X, y);
		}
		if(!y) neoscrypt_blkswp(&X[0], &Z[0], 256);
	}

	/* blkxor(X, Z) */
	neoscrypt_blkxor(&X[0], &Z[0], CONSTANT_r * 2 * BLOCK_SIZE);

#ifdef TEST
	fastkdf(data, X, FASTKDF_BUFFER_SIZE, 32, outbuf, 32);
	//((uint *)outbuf)[8]= target;
	for(i= 0; i< OUTPUT_LEN; ++i)
		output[i]= outbuf[i];
#else
	/* output = KDF(password, X) */
	fastkdf(data, X, FASTKDF_BUFFER_SIZE, 32, outbuf, 32);

#define SCRYPT_FOUND (0xFF)
#ifdef cl_khr_global_int32_base_atomics
	#define SETFOUND(Xnonce) output[atomic_add(&output[SCRYPT_FOUND], 1)]= Xnonce
#else
	#define SETFOUND(Xnonce) output[output[SCRYPT_FOUND]++] = Xnonce
#endif

	if (((uint *)outbuf)[7]<= target)
		SETFOUND(get_global_id(0));
#endif
}