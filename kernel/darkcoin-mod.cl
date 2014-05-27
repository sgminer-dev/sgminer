/* X11 kernel implementation.
 *
 * ==========================(LICENSE BEGIN)============================
 *
 * Copyright (c) 2014  phm
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
 * @author   phm <phm@inbox.com>
 */

#ifdef __ECLIPSE_EDITOR__
#include "OpenCLKernel.hpp"
#endif

#ifndef DARKCOIN_MOD_CL
#define DARKCOIN_MOD_CL

#if __ENDIAN_LITTLE__
#define SPH_LITTLE_ENDIAN 1
#else
#define SPH_BIG_ENDIAN 1
#endif

#define SPH_UPTR sph_u64

typedef unsigned int sph_u32;
typedef int sph_s32;
#ifndef __OPENCL_VERSION__
typedef unsigned long long sph_u64;
typedef long long sph_s64;
#else
typedef unsigned long sph_u64;
typedef long sph_s64;
#endif

#define SPH_64 1
#define SPH_64_TRUE 1

#define SPH_C32(x)    ((sph_u32)(x ## U))
#define SPH_T32(x)    ((x) & SPH_C32(0xFFFFFFFF))
#define SPH_ROTL32(x, n)   SPH_T32(((x) << (n)) | ((x) >> (32 - (n))))
#define SPH_ROTR32(x, n)   SPH_ROTL32(x, (32 - (n)))

#define SPH_C64(x)    ((sph_u64)(x ## UL))
#define SPH_T64(x)    ((x) & SPH_C64(0xFFFFFFFFFFFFFFFF))
#define SPH_ROTL64(x, n)   SPH_T64(((x) << (n)) | ((x) >> (64 - (n))))
#define SPH_ROTR64(x, n)   SPH_ROTL64(x, (64 - (n)))

#define SPH_ECHO_64 1
#define SPH_KECCAK_64 1
#define SPH_JH_64 1
#define SPH_SIMD_NOCOPY 0
#define SPH_KECCAK_NOCOPY 0
#define SPH_COMPACT_BLAKE_64 0
#define SPH_LUFFA_PARALLEL 0
#ifndef SPH_SMALL_FOOTPRINT_GROESTL
#define SPH_SMALL_FOOTPRINT_GROESTL 0
#endif
#define SPH_GROESTL_BIG_ENDIAN 0

#define SPH_CUBEHASH_UNROLL 0
#define SPH_KECCAK_UNROLL   0

#ifndef AES_HELPER_H
#define AES_HELPER_H

/* $Id: aes_helper.c 220 2010-06-09 09:21:50Z tp $ */
/*
 * AES tables. This file is not meant to be compiled by itself; it
 * is included by some hash function implementations. It contains
 * the precomputed tables and helper macros for evaluating an AES
 * round, optionally with a final XOR with a subkey.
 *
 * By default, this file defines the tables and macros for little-endian
 * processing (i.e. it is assumed that the input bytes have been read
 * from memory and assembled with the little-endian convention). If
 * the 'AES_BIG_ENDIAN' macro is defined (to a non-zero integer value)
 * when this file is included, then the tables and macros for big-endian
 * processing are defined instead. The big-endian tables and macros have
 * names distinct from the little-endian tables and macros, hence it is
 * possible to have both simultaneously, by including this file twice
 * (with and without the AES_BIG_ENDIAN macro).
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

#if AES_BIG_ENDIAN

#define AESx(x)   ( ((SPH_C32(x) >> 24) & SPH_C32(0x000000FF)) \
                  | ((SPH_C32(x) >>  8) & SPH_C32(0x0000FF00)) \
                  | ((SPH_C32(x) <<  8) & SPH_C32(0x00FF0000)) \
                  | ((SPH_C32(x) << 24) & SPH_C32(0xFF000000)))

#define AES0      AES0_BE
#define AES1      AES1_BE
#define AES2      AES2_BE
#define AES3      AES3_BE

#define AES_ROUND_BE(X0, X1, X2, X3, K0, K1, K2, K3, Y0, Y1, Y2, Y3)   do { \
    (Y0) = AES0[((X0) >> 24) & 0xFF] \
      ^ AES1[((X1) >> 16) & 0xFF] \
      ^ AES2[((X2) >> 8) & 0xFF] \
      ^ AES3[(X3) & 0xFF] ^ (K0); \
    (Y1) = AES0[((X1) >> 24) & 0xFF] \
      ^ AES1[((X2) >> 16) & 0xFF] \
      ^ AES2[((X3) >> 8) & 0xFF] \
      ^ AES3[(X0) & 0xFF] ^ (K1); \
    (Y2) = AES0[((X2) >> 24) & 0xFF] \
      ^ AES1[((X3) >> 16) & 0xFF] \
      ^ AES2[((X0) >> 8) & 0xFF] \
      ^ AES3[(X1) & 0xFF] ^ (K2); \
    (Y3) = AES0[((X3) >> 24) & 0xFF] \
      ^ AES1[((X0) >> 16) & 0xFF] \
      ^ AES2[((X1) >> 8) & 0xFF] \
      ^ AES3[(X2) & 0xFF] ^ (K3); \
  } while (0)

#define AES_ROUND_NOKEY_BE(X0, X1, X2, X3, Y0, Y1, Y2, Y3) \
  AES_ROUND_BE(X0, X1, X2, X3, 0, 0, 0, 0, Y0, Y1, Y2, Y3)

#else

#define AESx(x)   SPH_C32(x)
#define AES0      AES0_LE
#define AES1      AES1_LE
#define AES2      AES2_LE
#define AES3      AES3_LE

#define AES_ROUND_LE(X0, X1, X2, X3, K0, K1, K2, K3, Y0, Y1, Y2, Y3)   do { \
    (Y0) = AES0[(X0) & 0xFF] \
      ^ AES1[((X1) >> 8) & 0xFF] \
      ^ AES2[((X2) >> 16) & 0xFF] \
      ^ AES3[((X3) >> 24) & 0xFF] ^ (K0); \
    (Y1) = AES0[(X1) & 0xFF] \
      ^ AES1[((X2) >> 8) & 0xFF] \
      ^ AES2[((X3) >> 16) & 0xFF] \
      ^ AES3[((X0) >> 24) & 0xFF] ^ (K1); \
    (Y2) = AES0[(X2) & 0xFF] \
      ^ AES1[((X3) >> 8) & 0xFF] \
      ^ AES2[((X0) >> 16) & 0xFF] \
      ^ AES3[((X1) >> 24) & 0xFF] ^ (K2); \
    (Y3) = AES0[(X3) & 0xFF] \
      ^ AES1[((X0) >> 8) & 0xFF] \
      ^ AES2[((X1) >> 16) & 0xFF] \
      ^ AES3[((X2) >> 24) & 0xFF] ^ (K3); \
  } while (0)

#define AES_ROUND_NOKEY_LE(X0, X1, X2, X3, Y0, Y1, Y2, Y3) \
  AES_ROUND_LE(X0, X1, X2, X3, 0, 0, 0, 0, Y0, Y1, Y2, Y3)

#endif

/*
 * The AES*[] tables allow us to perform a fast evaluation of an AES
 * round; table AESi[] combines SubBytes for a byte at row i, and
 * MixColumns for the column where that byte goes after ShiftRows.
 */

__constant const sph_u32 AES0_C[256] = {
  AESx(0xA56363C6), AESx(0x847C7CF8), AESx(0x997777EE), AESx(0x8D7B7BF6),
  AESx(0x0DF2F2FF), AESx(0xBD6B6BD6), AESx(0xB16F6FDE), AESx(0x54C5C591),
  AESx(0x50303060), AESx(0x03010102), AESx(0xA96767CE), AESx(0x7D2B2B56),
  AESx(0x19FEFEE7), AESx(0x62D7D7B5), AESx(0xE6ABAB4D), AESx(0x9A7676EC),
  AESx(0x45CACA8F), AESx(0x9D82821F), AESx(0x40C9C989), AESx(0x877D7DFA),
  AESx(0x15FAFAEF), AESx(0xEB5959B2), AESx(0xC947478E), AESx(0x0BF0F0FB),
  AESx(0xECADAD41), AESx(0x67D4D4B3), AESx(0xFDA2A25F), AESx(0xEAAFAF45),
  AESx(0xBF9C9C23), AESx(0xF7A4A453), AESx(0x967272E4), AESx(0x5BC0C09B),
  AESx(0xC2B7B775), AESx(0x1CFDFDE1), AESx(0xAE93933D), AESx(0x6A26264C),
  AESx(0x5A36366C), AESx(0x413F3F7E), AESx(0x02F7F7F5), AESx(0x4FCCCC83),
  AESx(0x5C343468), AESx(0xF4A5A551), AESx(0x34E5E5D1), AESx(0x08F1F1F9),
  AESx(0x937171E2), AESx(0x73D8D8AB), AESx(0x53313162), AESx(0x3F15152A),
  AESx(0x0C040408), AESx(0x52C7C795), AESx(0x65232346), AESx(0x5EC3C39D),
  AESx(0x28181830), AESx(0xA1969637), AESx(0x0F05050A), AESx(0xB59A9A2F),
  AESx(0x0907070E), AESx(0x36121224), AESx(0x9B80801B), AESx(0x3DE2E2DF),
  AESx(0x26EBEBCD), AESx(0x6927274E), AESx(0xCDB2B27F), AESx(0x9F7575EA),
  AESx(0x1B090912), AESx(0x9E83831D), AESx(0x742C2C58), AESx(0x2E1A1A34),
  AESx(0x2D1B1B36), AESx(0xB26E6EDC), AESx(0xEE5A5AB4), AESx(0xFBA0A05B),
  AESx(0xF65252A4), AESx(0x4D3B3B76), AESx(0x61D6D6B7), AESx(0xCEB3B37D),
  AESx(0x7B292952), AESx(0x3EE3E3DD), AESx(0x712F2F5E), AESx(0x97848413),
  AESx(0xF55353A6), AESx(0x68D1D1B9), AESx(0x00000000), AESx(0x2CEDEDC1),
  AESx(0x60202040), AESx(0x1FFCFCE3), AESx(0xC8B1B179), AESx(0xED5B5BB6),
  AESx(0xBE6A6AD4), AESx(0x46CBCB8D), AESx(0xD9BEBE67), AESx(0x4B393972),
  AESx(0xDE4A4A94), AESx(0xD44C4C98), AESx(0xE85858B0), AESx(0x4ACFCF85),
  AESx(0x6BD0D0BB), AESx(0x2AEFEFC5), AESx(0xE5AAAA4F), AESx(0x16FBFBED),
  AESx(0xC5434386), AESx(0xD74D4D9A), AESx(0x55333366), AESx(0x94858511),
  AESx(0xCF45458A), AESx(0x10F9F9E9), AESx(0x06020204), AESx(0x817F7FFE),
  AESx(0xF05050A0), AESx(0x443C3C78), AESx(0xBA9F9F25), AESx(0xE3A8A84B),
  AESx(0xF35151A2), AESx(0xFEA3A35D), AESx(0xC0404080), AESx(0x8A8F8F05),
  AESx(0xAD92923F), AESx(0xBC9D9D21), AESx(0x48383870), AESx(0x04F5F5F1),
  AESx(0xDFBCBC63), AESx(0xC1B6B677), AESx(0x75DADAAF), AESx(0x63212142),
  AESx(0x30101020), AESx(0x1AFFFFE5), AESx(0x0EF3F3FD), AESx(0x6DD2D2BF),
  AESx(0x4CCDCD81), AESx(0x140C0C18), AESx(0x35131326), AESx(0x2FECECC3),
  AESx(0xE15F5FBE), AESx(0xA2979735), AESx(0xCC444488), AESx(0x3917172E),
  AESx(0x57C4C493), AESx(0xF2A7A755), AESx(0x827E7EFC), AESx(0x473D3D7A),
  AESx(0xAC6464C8), AESx(0xE75D5DBA), AESx(0x2B191932), AESx(0x957373E6),
  AESx(0xA06060C0), AESx(0x98818119), AESx(0xD14F4F9E), AESx(0x7FDCDCA3),
  AESx(0x66222244), AESx(0x7E2A2A54), AESx(0xAB90903B), AESx(0x8388880B),
  AESx(0xCA46468C), AESx(0x29EEEEC7), AESx(0xD3B8B86B), AESx(0x3C141428),
  AESx(0x79DEDEA7), AESx(0xE25E5EBC), AESx(0x1D0B0B16), AESx(0x76DBDBAD),
  AESx(0x3BE0E0DB), AESx(0x56323264), AESx(0x4E3A3A74), AESx(0x1E0A0A14),
  AESx(0xDB494992), AESx(0x0A06060C), AESx(0x6C242448), AESx(0xE45C5CB8),
  AESx(0x5DC2C29F), AESx(0x6ED3D3BD), AESx(0xEFACAC43), AESx(0xA66262C4),
  AESx(0xA8919139), AESx(0xA4959531), AESx(0x37E4E4D3), AESx(0x8B7979F2),
  AESx(0x32E7E7D5), AESx(0x43C8C88B), AESx(0x5937376E), AESx(0xB76D6DDA),
  AESx(0x8C8D8D01), AESx(0x64D5D5B1), AESx(0xD24E4E9C), AESx(0xE0A9A949),
  AESx(0xB46C6CD8), AESx(0xFA5656AC), AESx(0x07F4F4F3), AESx(0x25EAEACF),
  AESx(0xAF6565CA), AESx(0x8E7A7AF4), AESx(0xE9AEAE47), AESx(0x18080810),
  AESx(0xD5BABA6F), AESx(0x887878F0), AESx(0x6F25254A), AESx(0x722E2E5C),
  AESx(0x241C1C38), AESx(0xF1A6A657), AESx(0xC7B4B473), AESx(0x51C6C697),
  AESx(0x23E8E8CB), AESx(0x7CDDDDA1), AESx(0x9C7474E8), AESx(0x211F1F3E),
  AESx(0xDD4B4B96), AESx(0xDCBDBD61), AESx(0x868B8B0D), AESx(0x858A8A0F),
  AESx(0x907070E0), AESx(0x423E3E7C), AESx(0xC4B5B571), AESx(0xAA6666CC),
  AESx(0xD8484890), AESx(0x05030306), AESx(0x01F6F6F7), AESx(0x120E0E1C),
  AESx(0xA36161C2), AESx(0x5F35356A), AESx(0xF95757AE), AESx(0xD0B9B969),
  AESx(0x91868617), AESx(0x58C1C199), AESx(0x271D1D3A), AESx(0xB99E9E27),
  AESx(0x38E1E1D9), AESx(0x13F8F8EB), AESx(0xB398982B), AESx(0x33111122),
  AESx(0xBB6969D2), AESx(0x70D9D9A9), AESx(0x898E8E07), AESx(0xA7949433),
  AESx(0xB69B9B2D), AESx(0x221E1E3C), AESx(0x92878715), AESx(0x20E9E9C9),
  AESx(0x49CECE87), AESx(0xFF5555AA), AESx(0x78282850), AESx(0x7ADFDFA5),
  AESx(0x8F8C8C03), AESx(0xF8A1A159), AESx(0x80898909), AESx(0x170D0D1A),
  AESx(0xDABFBF65), AESx(0x31E6E6D7), AESx(0xC6424284), AESx(0xB86868D0),
  AESx(0xC3414182), AESx(0xB0999929), AESx(0x772D2D5A), AESx(0x110F0F1E),
  AESx(0xCBB0B07B), AESx(0xFC5454A8), AESx(0xD6BBBB6D), AESx(0x3A16162C)
};

__constant const sph_u32 AES1_C[256] = {
  AESx(0x6363C6A5), AESx(0x7C7CF884), AESx(0x7777EE99), AESx(0x7B7BF68D),
  AESx(0xF2F2FF0D), AESx(0x6B6BD6BD), AESx(0x6F6FDEB1), AESx(0xC5C59154),
  AESx(0x30306050), AESx(0x01010203), AESx(0x6767CEA9), AESx(0x2B2B567D),
  AESx(0xFEFEE719), AESx(0xD7D7B562), AESx(0xABAB4DE6), AESx(0x7676EC9A),
  AESx(0xCACA8F45), AESx(0x82821F9D), AESx(0xC9C98940), AESx(0x7D7DFA87),
  AESx(0xFAFAEF15), AESx(0x5959B2EB), AESx(0x47478EC9), AESx(0xF0F0FB0B),
  AESx(0xADAD41EC), AESx(0xD4D4B367), AESx(0xA2A25FFD), AESx(0xAFAF45EA),
  AESx(0x9C9C23BF), AESx(0xA4A453F7), AESx(0x7272E496), AESx(0xC0C09B5B),
  AESx(0xB7B775C2), AESx(0xFDFDE11C), AESx(0x93933DAE), AESx(0x26264C6A),
  AESx(0x36366C5A), AESx(0x3F3F7E41), AESx(0xF7F7F502), AESx(0xCCCC834F),
  AESx(0x3434685C), AESx(0xA5A551F4), AESx(0xE5E5D134), AESx(0xF1F1F908),
  AESx(0x7171E293), AESx(0xD8D8AB73), AESx(0x31316253), AESx(0x15152A3F),
  AESx(0x0404080C), AESx(0xC7C79552), AESx(0x23234665), AESx(0xC3C39D5E),
  AESx(0x18183028), AESx(0x969637A1), AESx(0x05050A0F), AESx(0x9A9A2FB5),
  AESx(0x07070E09), AESx(0x12122436), AESx(0x80801B9B), AESx(0xE2E2DF3D),
  AESx(0xEBEBCD26), AESx(0x27274E69), AESx(0xB2B27FCD), AESx(0x7575EA9F),
  AESx(0x0909121B), AESx(0x83831D9E), AESx(0x2C2C5874), AESx(0x1A1A342E),
  AESx(0x1B1B362D), AESx(0x6E6EDCB2), AESx(0x5A5AB4EE), AESx(0xA0A05BFB),
  AESx(0x5252A4F6), AESx(0x3B3B764D), AESx(0xD6D6B761), AESx(0xB3B37DCE),
  AESx(0x2929527B), AESx(0xE3E3DD3E), AESx(0x2F2F5E71), AESx(0x84841397),
  AESx(0x5353A6F5), AESx(0xD1D1B968), AESx(0x00000000), AESx(0xEDEDC12C),
  AESx(0x20204060), AESx(0xFCFCE31F), AESx(0xB1B179C8), AESx(0x5B5BB6ED),
  AESx(0x6A6AD4BE), AESx(0xCBCB8D46), AESx(0xBEBE67D9), AESx(0x3939724B),
  AESx(0x4A4A94DE), AESx(0x4C4C98D4), AESx(0x5858B0E8), AESx(0xCFCF854A),
  AESx(0xD0D0BB6B), AESx(0xEFEFC52A), AESx(0xAAAA4FE5), AESx(0xFBFBED16),
  AESx(0x434386C5), AESx(0x4D4D9AD7), AESx(0x33336655), AESx(0x85851194),
  AESx(0x45458ACF), AESx(0xF9F9E910), AESx(0x02020406), AESx(0x7F7FFE81),
  AESx(0x5050A0F0), AESx(0x3C3C7844), AESx(0x9F9F25BA), AESx(0xA8A84BE3),
  AESx(0x5151A2F3), AESx(0xA3A35DFE), AESx(0x404080C0), AESx(0x8F8F058A),
  AESx(0x92923FAD), AESx(0x9D9D21BC), AESx(0x38387048), AESx(0xF5F5F104),
  AESx(0xBCBC63DF), AESx(0xB6B677C1), AESx(0xDADAAF75), AESx(0x21214263),
  AESx(0x10102030), AESx(0xFFFFE51A), AESx(0xF3F3FD0E), AESx(0xD2D2BF6D),
  AESx(0xCDCD814C), AESx(0x0C0C1814), AESx(0x13132635), AESx(0xECECC32F),
  AESx(0x5F5FBEE1), AESx(0x979735A2), AESx(0x444488CC), AESx(0x17172E39),
  AESx(0xC4C49357), AESx(0xA7A755F2), AESx(0x7E7EFC82), AESx(0x3D3D7A47),
  AESx(0x6464C8AC), AESx(0x5D5DBAE7), AESx(0x1919322B), AESx(0x7373E695),
  AESx(0x6060C0A0), AESx(0x81811998), AESx(0x4F4F9ED1), AESx(0xDCDCA37F),
  AESx(0x22224466), AESx(0x2A2A547E), AESx(0x90903BAB), AESx(0x88880B83),
  AESx(0x46468CCA), AESx(0xEEEEC729), AESx(0xB8B86BD3), AESx(0x1414283C),
  AESx(0xDEDEA779), AESx(0x5E5EBCE2), AESx(0x0B0B161D), AESx(0xDBDBAD76),
  AESx(0xE0E0DB3B), AESx(0x32326456), AESx(0x3A3A744E), AESx(0x0A0A141E),
  AESx(0x494992DB), AESx(0x06060C0A), AESx(0x2424486C), AESx(0x5C5CB8E4),
  AESx(0xC2C29F5D), AESx(0xD3D3BD6E), AESx(0xACAC43EF), AESx(0x6262C4A6),
  AESx(0x919139A8), AESx(0x959531A4), AESx(0xE4E4D337), AESx(0x7979F28B),
  AESx(0xE7E7D532), AESx(0xC8C88B43), AESx(0x37376E59), AESx(0x6D6DDAB7),
  AESx(0x8D8D018C), AESx(0xD5D5B164), AESx(0x4E4E9CD2), AESx(0xA9A949E0),
  AESx(0x6C6CD8B4), AESx(0x5656ACFA), AESx(0xF4F4F307), AESx(0xEAEACF25),
  AESx(0x6565CAAF), AESx(0x7A7AF48E), AESx(0xAEAE47E9), AESx(0x08081018),
  AESx(0xBABA6FD5), AESx(0x7878F088), AESx(0x25254A6F), AESx(0x2E2E5C72),
  AESx(0x1C1C3824), AESx(0xA6A657F1), AESx(0xB4B473C7), AESx(0xC6C69751),
  AESx(0xE8E8CB23), AESx(0xDDDDA17C), AESx(0x7474E89C), AESx(0x1F1F3E21),
  AESx(0x4B4B96DD), AESx(0xBDBD61DC), AESx(0x8B8B0D86), AESx(0x8A8A0F85),
  AESx(0x7070E090), AESx(0x3E3E7C42), AESx(0xB5B571C4), AESx(0x6666CCAA),
  AESx(0x484890D8), AESx(0x03030605), AESx(0xF6F6F701), AESx(0x0E0E1C12),
  AESx(0x6161C2A3), AESx(0x35356A5F), AESx(0x5757AEF9), AESx(0xB9B969D0),
  AESx(0x86861791), AESx(0xC1C19958), AESx(0x1D1D3A27), AESx(0x9E9E27B9),
  AESx(0xE1E1D938), AESx(0xF8F8EB13), AESx(0x98982BB3), AESx(0x11112233),
  AESx(0x6969D2BB), AESx(0xD9D9A970), AESx(0x8E8E0789), AESx(0x949433A7),
  AESx(0x9B9B2DB6), AESx(0x1E1E3C22), AESx(0x87871592), AESx(0xE9E9C920),
  AESx(0xCECE8749), AESx(0x5555AAFF), AESx(0x28285078), AESx(0xDFDFA57A),
  AESx(0x8C8C038F), AESx(0xA1A159F8), AESx(0x89890980), AESx(0x0D0D1A17),
  AESx(0xBFBF65DA), AESx(0xE6E6D731), AESx(0x424284C6), AESx(0x6868D0B8),
  AESx(0x414182C3), AESx(0x999929B0), AESx(0x2D2D5A77), AESx(0x0F0F1E11),
  AESx(0xB0B07BCB), AESx(0x5454A8FC), AESx(0xBBBB6DD6), AESx(0x16162C3A)
};

__constant const sph_u32 AES2_C[256] = {
  AESx(0x63C6A563), AESx(0x7CF8847C), AESx(0x77EE9977), AESx(0x7BF68D7B),
  AESx(0xF2FF0DF2), AESx(0x6BD6BD6B), AESx(0x6FDEB16F), AESx(0xC59154C5),
  AESx(0x30605030), AESx(0x01020301), AESx(0x67CEA967), AESx(0x2B567D2B),
  AESx(0xFEE719FE), AESx(0xD7B562D7), AESx(0xAB4DE6AB), AESx(0x76EC9A76),
  AESx(0xCA8F45CA), AESx(0x821F9D82), AESx(0xC98940C9), AESx(0x7DFA877D),
  AESx(0xFAEF15FA), AESx(0x59B2EB59), AESx(0x478EC947), AESx(0xF0FB0BF0),
  AESx(0xAD41ECAD), AESx(0xD4B367D4), AESx(0xA25FFDA2), AESx(0xAF45EAAF),
  AESx(0x9C23BF9C), AESx(0xA453F7A4), AESx(0x72E49672), AESx(0xC09B5BC0),
  AESx(0xB775C2B7), AESx(0xFDE11CFD), AESx(0x933DAE93), AESx(0x264C6A26),
  AESx(0x366C5A36), AESx(0x3F7E413F), AESx(0xF7F502F7), AESx(0xCC834FCC),
  AESx(0x34685C34), AESx(0xA551F4A5), AESx(0xE5D134E5), AESx(0xF1F908F1),
  AESx(0x71E29371), AESx(0xD8AB73D8), AESx(0x31625331), AESx(0x152A3F15),
  AESx(0x04080C04), AESx(0xC79552C7), AESx(0x23466523), AESx(0xC39D5EC3),
  AESx(0x18302818), AESx(0x9637A196), AESx(0x050A0F05), AESx(0x9A2FB59A),
  AESx(0x070E0907), AESx(0x12243612), AESx(0x801B9B80), AESx(0xE2DF3DE2),
  AESx(0xEBCD26EB), AESx(0x274E6927), AESx(0xB27FCDB2), AESx(0x75EA9F75),
  AESx(0x09121B09), AESx(0x831D9E83), AESx(0x2C58742C), AESx(0x1A342E1A),
  AESx(0x1B362D1B), AESx(0x6EDCB26E), AESx(0x5AB4EE5A), AESx(0xA05BFBA0),
  AESx(0x52A4F652), AESx(0x3B764D3B), AESx(0xD6B761D6), AESx(0xB37DCEB3),
  AESx(0x29527B29), AESx(0xE3DD3EE3), AESx(0x2F5E712F), AESx(0x84139784),
  AESx(0x53A6F553), AESx(0xD1B968D1), AESx(0x00000000), AESx(0xEDC12CED),
  AESx(0x20406020), AESx(0xFCE31FFC), AESx(0xB179C8B1), AESx(0x5BB6ED5B),
  AESx(0x6AD4BE6A), AESx(0xCB8D46CB), AESx(0xBE67D9BE), AESx(0x39724B39),
  AESx(0x4A94DE4A), AESx(0x4C98D44C), AESx(0x58B0E858), AESx(0xCF854ACF),
  AESx(0xD0BB6BD0), AESx(0xEFC52AEF), AESx(0xAA4FE5AA), AESx(0xFBED16FB),
  AESx(0x4386C543), AESx(0x4D9AD74D), AESx(0x33665533), AESx(0x85119485),
  AESx(0x458ACF45), AESx(0xF9E910F9), AESx(0x02040602), AESx(0x7FFE817F),
  AESx(0x50A0F050), AESx(0x3C78443C), AESx(0x9F25BA9F), AESx(0xA84BE3A8),
  AESx(0x51A2F351), AESx(0xA35DFEA3), AESx(0x4080C040), AESx(0x8F058A8F),
  AESx(0x923FAD92), AESx(0x9D21BC9D), AESx(0x38704838), AESx(0xF5F104F5),
  AESx(0xBC63DFBC), AESx(0xB677C1B6), AESx(0xDAAF75DA), AESx(0x21426321),
  AESx(0x10203010), AESx(0xFFE51AFF), AESx(0xF3FD0EF3), AESx(0xD2BF6DD2),
  AESx(0xCD814CCD), AESx(0x0C18140C), AESx(0x13263513), AESx(0xECC32FEC),
  AESx(0x5FBEE15F), AESx(0x9735A297), AESx(0x4488CC44), AESx(0x172E3917),
  AESx(0xC49357C4), AESx(0xA755F2A7), AESx(0x7EFC827E), AESx(0x3D7A473D),
  AESx(0x64C8AC64), AESx(0x5DBAE75D), AESx(0x19322B19), AESx(0x73E69573),
  AESx(0x60C0A060), AESx(0x81199881), AESx(0x4F9ED14F), AESx(0xDCA37FDC),
  AESx(0x22446622), AESx(0x2A547E2A), AESx(0x903BAB90), AESx(0x880B8388),
  AESx(0x468CCA46), AESx(0xEEC729EE), AESx(0xB86BD3B8), AESx(0x14283C14),
  AESx(0xDEA779DE), AESx(0x5EBCE25E), AESx(0x0B161D0B), AESx(0xDBAD76DB),
  AESx(0xE0DB3BE0), AESx(0x32645632), AESx(0x3A744E3A), AESx(0x0A141E0A),
  AESx(0x4992DB49), AESx(0x060C0A06), AESx(0x24486C24), AESx(0x5CB8E45C),
  AESx(0xC29F5DC2), AESx(0xD3BD6ED3), AESx(0xAC43EFAC), AESx(0x62C4A662),
  AESx(0x9139A891), AESx(0x9531A495), AESx(0xE4D337E4), AESx(0x79F28B79),
  AESx(0xE7D532E7), AESx(0xC88B43C8), AESx(0x376E5937), AESx(0x6DDAB76D),
  AESx(0x8D018C8D), AESx(0xD5B164D5), AESx(0x4E9CD24E), AESx(0xA949E0A9),
  AESx(0x6CD8B46C), AESx(0x56ACFA56), AESx(0xF4F307F4), AESx(0xEACF25EA),
  AESx(0x65CAAF65), AESx(0x7AF48E7A), AESx(0xAE47E9AE), AESx(0x08101808),
  AESx(0xBA6FD5BA), AESx(0x78F08878), AESx(0x254A6F25), AESx(0x2E5C722E),
  AESx(0x1C38241C), AESx(0xA657F1A6), AESx(0xB473C7B4), AESx(0xC69751C6),
  AESx(0xE8CB23E8), AESx(0xDDA17CDD), AESx(0x74E89C74), AESx(0x1F3E211F),
  AESx(0x4B96DD4B), AESx(0xBD61DCBD), AESx(0x8B0D868B), AESx(0x8A0F858A),
  AESx(0x70E09070), AESx(0x3E7C423E), AESx(0xB571C4B5), AESx(0x66CCAA66),
  AESx(0x4890D848), AESx(0x03060503), AESx(0xF6F701F6), AESx(0x0E1C120E),
  AESx(0x61C2A361), AESx(0x356A5F35), AESx(0x57AEF957), AESx(0xB969D0B9),
  AESx(0x86179186), AESx(0xC19958C1), AESx(0x1D3A271D), AESx(0x9E27B99E),
  AESx(0xE1D938E1), AESx(0xF8EB13F8), AESx(0x982BB398), AESx(0x11223311),
  AESx(0x69D2BB69), AESx(0xD9A970D9), AESx(0x8E07898E), AESx(0x9433A794),
  AESx(0x9B2DB69B), AESx(0x1E3C221E), AESx(0x87159287), AESx(0xE9C920E9),
  AESx(0xCE8749CE), AESx(0x55AAFF55), AESx(0x28507828), AESx(0xDFA57ADF),
  AESx(0x8C038F8C), AESx(0xA159F8A1), AESx(0x89098089), AESx(0x0D1A170D),
  AESx(0xBF65DABF), AESx(0xE6D731E6), AESx(0x4284C642), AESx(0x68D0B868),
  AESx(0x4182C341), AESx(0x9929B099), AESx(0x2D5A772D), AESx(0x0F1E110F),
  AESx(0xB07BCBB0), AESx(0x54A8FC54), AESx(0xBB6DD6BB), AESx(0x162C3A16)
};

__constant const sph_u32 AES3_C[256] = {
  AESx(0xC6A56363), AESx(0xF8847C7C), AESx(0xEE997777), AESx(0xF68D7B7B),
  AESx(0xFF0DF2F2), AESx(0xD6BD6B6B), AESx(0xDEB16F6F), AESx(0x9154C5C5),
  AESx(0x60503030), AESx(0x02030101), AESx(0xCEA96767), AESx(0x567D2B2B),
  AESx(0xE719FEFE), AESx(0xB562D7D7), AESx(0x4DE6ABAB), AESx(0xEC9A7676),
  AESx(0x8F45CACA), AESx(0x1F9D8282), AESx(0x8940C9C9), AESx(0xFA877D7D),
  AESx(0xEF15FAFA), AESx(0xB2EB5959), AESx(0x8EC94747), AESx(0xFB0BF0F0),
  AESx(0x41ECADAD), AESx(0xB367D4D4), AESx(0x5FFDA2A2), AESx(0x45EAAFAF),
  AESx(0x23BF9C9C), AESx(0x53F7A4A4), AESx(0xE4967272), AESx(0x9B5BC0C0),
  AESx(0x75C2B7B7), AESx(0xE11CFDFD), AESx(0x3DAE9393), AESx(0x4C6A2626),
  AESx(0x6C5A3636), AESx(0x7E413F3F), AESx(0xF502F7F7), AESx(0x834FCCCC),
  AESx(0x685C3434), AESx(0x51F4A5A5), AESx(0xD134E5E5), AESx(0xF908F1F1),
  AESx(0xE2937171), AESx(0xAB73D8D8), AESx(0x62533131), AESx(0x2A3F1515),
  AESx(0x080C0404), AESx(0x9552C7C7), AESx(0x46652323), AESx(0x9D5EC3C3),
  AESx(0x30281818), AESx(0x37A19696), AESx(0x0A0F0505), AESx(0x2FB59A9A),
  AESx(0x0E090707), AESx(0x24361212), AESx(0x1B9B8080), AESx(0xDF3DE2E2),
  AESx(0xCD26EBEB), AESx(0x4E692727), AESx(0x7FCDB2B2), AESx(0xEA9F7575),
  AESx(0x121B0909), AESx(0x1D9E8383), AESx(0x58742C2C), AESx(0x342E1A1A),
  AESx(0x362D1B1B), AESx(0xDCB26E6E), AESx(0xB4EE5A5A), AESx(0x5BFBA0A0),
  AESx(0xA4F65252), AESx(0x764D3B3B), AESx(0xB761D6D6), AESx(0x7DCEB3B3),
  AESx(0x527B2929), AESx(0xDD3EE3E3), AESx(0x5E712F2F), AESx(0x13978484),
  AESx(0xA6F55353), AESx(0xB968D1D1), AESx(0x00000000), AESx(0xC12CEDED),
  AESx(0x40602020), AESx(0xE31FFCFC), AESx(0x79C8B1B1), AESx(0xB6ED5B5B),
  AESx(0xD4BE6A6A), AESx(0x8D46CBCB), AESx(0x67D9BEBE), AESx(0x724B3939),
  AESx(0x94DE4A4A), AESx(0x98D44C4C), AESx(0xB0E85858), AESx(0x854ACFCF),
  AESx(0xBB6BD0D0), AESx(0xC52AEFEF), AESx(0x4FE5AAAA), AESx(0xED16FBFB),
  AESx(0x86C54343), AESx(0x9AD74D4D), AESx(0x66553333), AESx(0x11948585),
  AESx(0x8ACF4545), AESx(0xE910F9F9), AESx(0x04060202), AESx(0xFE817F7F),
  AESx(0xA0F05050), AESx(0x78443C3C), AESx(0x25BA9F9F), AESx(0x4BE3A8A8),
  AESx(0xA2F35151), AESx(0x5DFEA3A3), AESx(0x80C04040), AESx(0x058A8F8F),
  AESx(0x3FAD9292), AESx(0x21BC9D9D), AESx(0x70483838), AESx(0xF104F5F5),
  AESx(0x63DFBCBC), AESx(0x77C1B6B6), AESx(0xAF75DADA), AESx(0x42632121),
  AESx(0x20301010), AESx(0xE51AFFFF), AESx(0xFD0EF3F3), AESx(0xBF6DD2D2),
  AESx(0x814CCDCD), AESx(0x18140C0C), AESx(0x26351313), AESx(0xC32FECEC),
  AESx(0xBEE15F5F), AESx(0x35A29797), AESx(0x88CC4444), AESx(0x2E391717),
  AESx(0x9357C4C4), AESx(0x55F2A7A7), AESx(0xFC827E7E), AESx(0x7A473D3D),
  AESx(0xC8AC6464), AESx(0xBAE75D5D), AESx(0x322B1919), AESx(0xE6957373),
  AESx(0xC0A06060), AESx(0x19988181), AESx(0x9ED14F4F), AESx(0xA37FDCDC),
  AESx(0x44662222), AESx(0x547E2A2A), AESx(0x3BAB9090), AESx(0x0B838888),
  AESx(0x8CCA4646), AESx(0xC729EEEE), AESx(0x6BD3B8B8), AESx(0x283C1414),
  AESx(0xA779DEDE), AESx(0xBCE25E5E), AESx(0x161D0B0B), AESx(0xAD76DBDB),
  AESx(0xDB3BE0E0), AESx(0x64563232), AESx(0x744E3A3A), AESx(0x141E0A0A),
  AESx(0x92DB4949), AESx(0x0C0A0606), AESx(0x486C2424), AESx(0xB8E45C5C),
  AESx(0x9F5DC2C2), AESx(0xBD6ED3D3), AESx(0x43EFACAC), AESx(0xC4A66262),
  AESx(0x39A89191), AESx(0x31A49595), AESx(0xD337E4E4), AESx(0xF28B7979),
  AESx(0xD532E7E7), AESx(0x8B43C8C8), AESx(0x6E593737), AESx(0xDAB76D6D),
  AESx(0x018C8D8D), AESx(0xB164D5D5), AESx(0x9CD24E4E), AESx(0x49E0A9A9),
  AESx(0xD8B46C6C), AESx(0xACFA5656), AESx(0xF307F4F4), AESx(0xCF25EAEA),
  AESx(0xCAAF6565), AESx(0xF48E7A7A), AESx(0x47E9AEAE), AESx(0x10180808),
  AESx(0x6FD5BABA), AESx(0xF0887878), AESx(0x4A6F2525), AESx(0x5C722E2E),
  AESx(0x38241C1C), AESx(0x57F1A6A6), AESx(0x73C7B4B4), AESx(0x9751C6C6),
  AESx(0xCB23E8E8), AESx(0xA17CDDDD), AESx(0xE89C7474), AESx(0x3E211F1F),
  AESx(0x96DD4B4B), AESx(0x61DCBDBD), AESx(0x0D868B8B), AESx(0x0F858A8A),
  AESx(0xE0907070), AESx(0x7C423E3E), AESx(0x71C4B5B5), AESx(0xCCAA6666),
  AESx(0x90D84848), AESx(0x06050303), AESx(0xF701F6F6), AESx(0x1C120E0E),
  AESx(0xC2A36161), AESx(0x6A5F3535), AESx(0xAEF95757), AESx(0x69D0B9B9),
  AESx(0x17918686), AESx(0x9958C1C1), AESx(0x3A271D1D), AESx(0x27B99E9E),
  AESx(0xD938E1E1), AESx(0xEB13F8F8), AESx(0x2BB39898), AESx(0x22331111),
  AESx(0xD2BB6969), AESx(0xA970D9D9), AESx(0x07898E8E), AESx(0x33A79494),
  AESx(0x2DB69B9B), AESx(0x3C221E1E), AESx(0x15928787), AESx(0xC920E9E9),
  AESx(0x8749CECE), AESx(0xAAFF5555), AESx(0x50782828), AESx(0xA57ADFDF),
  AESx(0x038F8C8C), AESx(0x59F8A1A1), AESx(0x09808989), AESx(0x1A170D0D),
  AESx(0x65DABFBF), AESx(0xD731E6E6), AESx(0x84C64242), AESx(0xD0B86868),
  AESx(0x82C34141), AESx(0x29B09999), AESx(0x5A772D2D), AESx(0x1E110F0F),
  AESx(0x7BCBB0B0), AESx(0xA8FC5454), AESx(0x6DD6BBBB), AESx(0x2C3A1616)
};

#endif
/* $Id: blake.c 252 2011-06-07 17:55:14Z tp $ */
/*
 * BLAKE implementation.
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

__constant const sph_u64 BLAKE_IV512[8] = {
  SPH_C64(0x6A09E667F3BCC908), SPH_C64(0xBB67AE8584CAA73B),
  SPH_C64(0x3C6EF372FE94F82B), SPH_C64(0xA54FF53A5F1D36F1),
  SPH_C64(0x510E527FADE682D1), SPH_C64(0x9B05688C2B3E6C1F),
  SPH_C64(0x1F83D9ABFB41BD6B), SPH_C64(0x5BE0CD19137E2179)
};

#define Z00   0
#define Z01   1
#define Z02   2
#define Z03   3
#define Z04   4
#define Z05   5
#define Z06   6
#define Z07   7
#define Z08   8
#define Z09   9
#define Z0A   A
#define Z0B   B
#define Z0C   C
#define Z0D   D
#define Z0E   E
#define Z0F   F

#define Z10   E
#define Z11   A
#define Z12   4
#define Z13   8
#define Z14   9
#define Z15   F
#define Z16   D
#define Z17   6
#define Z18   1
#define Z19   C
#define Z1A   0
#define Z1B   2
#define Z1C   B
#define Z1D   7
#define Z1E   5
#define Z1F   3

#define Z20   B
#define Z21   8
#define Z22   C
#define Z23   0
#define Z24   5
#define Z25   2
#define Z26   F
#define Z27   D
#define Z28   A
#define Z29   E
#define Z2A   3
#define Z2B   6
#define Z2C   7
#define Z2D   1
#define Z2E   9
#define Z2F   4

#define Z30   7
#define Z31   9
#define Z32   3
#define Z33   1
#define Z34   D
#define Z35   C
#define Z36   B
#define Z37   E
#define Z38   2
#define Z39   6
#define Z3A   5
#define Z3B   A
#define Z3C   4
#define Z3D   0
#define Z3E   F
#define Z3F   8

#define Z40   9
#define Z41   0
#define Z42   5
#define Z43   7
#define Z44   2
#define Z45   4
#define Z46   A
#define Z47   F
#define Z48   E
#define Z49   1
#define Z4A   B
#define Z4B   C
#define Z4C   6
#define Z4D   8
#define Z4E   3
#define Z4F   D

#define Z50   2
#define Z51   C
#define Z52   6
#define Z53   A
#define Z54   0
#define Z55   B
#define Z56   8
#define Z57   3
#define Z58   4
#define Z59   D
#define Z5A   7
#define Z5B   5
#define Z5C   F
#define Z5D   E
#define Z5E   1
#define Z5F   9

#define Z60   C
#define Z61   5
#define Z62   1
#define Z63   F
#define Z64   E
#define Z65   D
#define Z66   4
#define Z67   A
#define Z68   0
#define Z69   7
#define Z6A   6
#define Z6B   3
#define Z6C   9
#define Z6D   2
#define Z6E   8
#define Z6F   B

#define Z70   D
#define Z71   B
#define Z72   7
#define Z73   E
#define Z74   C
#define Z75   1
#define Z76   3
#define Z77   9
#define Z78   5
#define Z79   0
#define Z7A   F
#define Z7B   4
#define Z7C   8
#define Z7D   6
#define Z7E   2
#define Z7F   A

#define Z80   6
#define Z81   F
#define Z82   E
#define Z83   9
#define Z84   B
#define Z85   3
#define Z86   0
#define Z87   8
#define Z88   C
#define Z89   2
#define Z8A   D
#define Z8B   7
#define Z8C   1
#define Z8D   4
#define Z8E   A
#define Z8F   5

#define Z90   A
#define Z91   2
#define Z92   8
#define Z93   4
#define Z94   7
#define Z95   6
#define Z96   1
#define Z97   5
#define Z98   F
#define Z99   B
#define Z9A   9
#define Z9B   E
#define Z9C   3
#define Z9D   C
#define Z9E   D
#define Z9F   0

#define Mx(r, i)    Mx_(Z ## r ## i)
#define Mx_(n)      Mx__(n)
#define Mx__(n)     M ## n

#define CSx(r, i)   CSx_(Z ## r ## i)
#define CSx_(n)     CSx__(n)
#define CSx__(n)    CS ## n

#define CS0   SPH_C32(0x243F6A88)
#define CS1   SPH_C32(0x85A308D3)
#define CS2   SPH_C32(0x13198A2E)
#define CS3   SPH_C32(0x03707344)
#define CS4   SPH_C32(0xA4093822)
#define CS5   SPH_C32(0x299F31D0)
#define CS6   SPH_C32(0x082EFA98)
#define CS7   SPH_C32(0xEC4E6C89)
#define CS8   SPH_C32(0x452821E6)
#define CS9   SPH_C32(0x38D01377)
#define CSA   SPH_C32(0xBE5466CF)
#define CSB   SPH_C32(0x34E90C6C)
#define CSC   SPH_C32(0xC0AC29B7)
#define CSD   SPH_C32(0xC97C50DD)
#define CSE   SPH_C32(0x3F84D5B5)
#define CSF   SPH_C32(0xB5470917)

#if SPH_64

#define CBx(r, i)   CBx_(Z ## r ## i)
#define CBx_(n)     CBx__(n)
#define CBx__(n)    CB ## n

#define CB0   SPH_C64(0x243F6A8885A308D3)
#define CB1   SPH_C64(0x13198A2E03707344)
#define CB2   SPH_C64(0xA4093822299F31D0)
#define CB3   SPH_C64(0x082EFA98EC4E6C89)
#define CB4   SPH_C64(0x452821E638D01377)
#define CB5   SPH_C64(0xBE5466CF34E90C6C)
#define CB6   SPH_C64(0xC0AC29B7C97C50DD)
#define CB7   SPH_C64(0x3F84D5B5B5470917)
#define CB8   SPH_C64(0x9216D5D98979FB1B)
#define CB9   SPH_C64(0xD1310BA698DFB5AC)
#define CBA   SPH_C64(0x2FFD72DBD01ADFB7)
#define CBB   SPH_C64(0xB8E1AFED6A267E96)
#define CBC   SPH_C64(0xBA7C9045F12C7F99)
#define CBD   SPH_C64(0x24A19947B3916CF7)
#define CBE   SPH_C64(0x0801F2E2858EFC16)
#define CBF   SPH_C64(0x636920D871574E69)

#endif

#if SPH_64

#define GB(m0, m1, c0, c1, a, b, c, d)   do { \
    a = SPH_T64(a + b + (m0 ^ c1)); \
    d = SPH_ROTR64(d ^ a, 32); \
    c = SPH_T64(c + d); \
    b = SPH_ROTR64(b ^ c, 25); \
    a = SPH_T64(a + b + (m1 ^ c0)); \
    d = SPH_ROTR64(d ^ a, 16); \
    c = SPH_T64(c + d); \
    b = SPH_ROTR64(b ^ c, 11); \
  } while (0)

#define ROUND_B(r)   do { \
    GB(Mx(r, 0), Mx(r, 1), CBx(r, 0), CBx(r, 1), V0, V4, V8, VC); \
    GB(Mx(r, 2), Mx(r, 3), CBx(r, 2), CBx(r, 3), V1, V5, V9, VD); \
    GB(Mx(r, 4), Mx(r, 5), CBx(r, 4), CBx(r, 5), V2, V6, VA, VE); \
    GB(Mx(r, 6), Mx(r, 7), CBx(r, 6), CBx(r, 7), V3, V7, VB, VF); \
    GB(Mx(r, 8), Mx(r, 9), CBx(r, 8), CBx(r, 9), V0, V5, VA, VF); \
    GB(Mx(r, A), Mx(r, B), CBx(r, A), CBx(r, B), V1, V6, VB, VC); \
    GB(Mx(r, C), Mx(r, D), CBx(r, C), CBx(r, D), V2, V7, V8, VD); \
    GB(Mx(r, E), Mx(r, F), CBx(r, E), CBx(r, F), V3, V4, V9, VE); \
  } while (0)

#endif

#if SPH_64

#define BLAKE_DECL_STATE64 \
  sph_u64 H0, H1, H2, H3, H4, H5, H6, H7; \
  sph_u64 S0, S1, S2, S3, T0, T1;

#define BLAKE_READ_STATE64(state)   do { \
    H0 = (state)->H[0]; \
    H1 = (state)->H[1]; \
    H2 = (state)->H[2]; \
    H3 = (state)->H[3]; \
    H4 = (state)->H[4]; \
    H5 = (state)->H[5]; \
    H6 = (state)->H[6]; \
    H7 = (state)->H[7]; \
    S0 = (state)->S[0]; \
    S1 = (state)->S[1]; \
    S2 = (state)->S[2]; \
    S3 = (state)->S[3]; \
    T0 = (state)->T0; \
    T1 = (state)->T1; \
  } while (0)

#define BLAKE_WRITE_STATE64(state)   do { \
    (state)->H[0] = H0; \
    (state)->H[1] = H1; \
    (state)->H[2] = H2; \
    (state)->H[3] = H3; \
    (state)->H[4] = H4; \
    (state)->H[5] = H5; \
    (state)->H[6] = H6; \
    (state)->H[7] = H7; \
    (state)->S[0] = S0; \
    (state)->S[1] = S1; \
    (state)->S[2] = S2; \
    (state)->S[3] = S3; \
    (state)->T0 = T0; \
    (state)->T1 = T1; \
  } while (0)

#define COMPRESS64   do { \
    V0 = H0; \
    V1 = H1; \
    V2 = H2; \
    V3 = H3; \
    V4 = H4; \
    V5 = H5; \
    V6 = H6; \
    V7 = H7; \
    V8 = S0 ^ CB0; \
    V9 = S1 ^ CB1; \
    VA = S2 ^ CB2; \
    VB = S3 ^ CB3; \
    VC = T0 ^ CB4; \
    VD = T0 ^ CB5; \
    VE = T1 ^ CB6; \
    VF = T1 ^ CB7; \
    ROUND_B(0); \
    ROUND_B(1); \
    ROUND_B(2); \
    ROUND_B(3); \
    ROUND_B(4); \
    ROUND_B(5); \
    ROUND_B(6); \
    ROUND_B(7); \
    ROUND_B(8); \
    ROUND_B(9); \
    ROUND_B(0); \
    ROUND_B(1); \
    ROUND_B(2); \
    ROUND_B(3); \
    ROUND_B(4); \
    ROUND_B(5); \
    H0 ^= S0 ^ V0 ^ V8; \
    H1 ^= S1 ^ V1 ^ V9; \
    H2 ^= S2 ^ V2 ^ VA; \
    H3 ^= S3 ^ V3 ^ VB; \
    H4 ^= S0 ^ V4 ^ VC; \
    H5 ^= S1 ^ V5 ^ VD; \
    H6 ^= S2 ^ V6 ^ VE; \
    H7 ^= S3 ^ V7 ^ VF; \
  } while (0)

#endif

__constant const sph_u64 salt_zero_big[4] = { 0, 0, 0, 0 };

#ifdef __cplusplus
}
#endif
/* $Id: bmw.c 227 2010-06-16 17:28:38Z tp $ */
/*
 * BMW implementation.
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

__constant const sph_u64 BMW_IV512[] = {
  SPH_C64(0x8081828384858687), SPH_C64(0x88898A8B8C8D8E8F),
  SPH_C64(0x9091929394959697), SPH_C64(0x98999A9B9C9D9E9F),
  SPH_C64(0xA0A1A2A3A4A5A6A7), SPH_C64(0xA8A9AAABACADAEAF),
  SPH_C64(0xB0B1B2B3B4B5B6B7), SPH_C64(0xB8B9BABBBCBDBEBF),
  SPH_C64(0xC0C1C2C3C4C5C6C7), SPH_C64(0xC8C9CACBCCCDCECF),
  SPH_C64(0xD0D1D2D3D4D5D6D7), SPH_C64(0xD8D9DADBDCDDDEDF),
  SPH_C64(0xE0E1E2E3E4E5E6E7), SPH_C64(0xE8E9EAEBECEDEEEF),
  SPH_C64(0xF0F1F2F3F4F5F6F7), SPH_C64(0xF8F9FAFBFCFDFEFF)
};

#define XCAT(x, y)    XCAT_(x, y)
#define XCAT_(x, y)   x ## y

#define LPAR   (

#define I16_16    0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15
#define I16_17    1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16
#define I16_18    2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17
#define I16_19    3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18
#define I16_20    4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19
#define I16_21    5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
#define I16_22    6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21
#define I16_23    7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22
#define I16_24    8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23
#define I16_25    9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
#define I16_26   10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25
#define I16_27   11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26
#define I16_28   12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27
#define I16_29   13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28
#define I16_30   14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29
#define I16_31   15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30

#define M16_16    0,  1,  3,  4,  7, 10, 11
#define M16_17    1,  2,  4,  5,  8, 11, 12
#define M16_18    2,  3,  5,  6,  9, 12, 13
#define M16_19    3,  4,  6,  7, 10, 13, 14
#define M16_20    4,  5,  7,  8, 11, 14, 15
#define M16_21    5,  6,  8,  9, 12, 15, 16
#define M16_22    6,  7,  9, 10, 13,  0,  1
#define M16_23    7,  8, 10, 11, 14,  1,  2
#define M16_24    8,  9, 11, 12, 15,  2,  3
#define M16_25    9, 10, 12, 13,  0,  3,  4
#define M16_26   10, 11, 13, 14,  1,  4,  5
#define M16_27   11, 12, 14, 15,  2,  5,  6
#define M16_28   12, 13, 15, 16,  3,  6,  7
#define M16_29   13, 14,  0,  1,  4,  7,  8
#define M16_30   14, 15,  1,  2,  5,  8,  9
#define M16_31   15, 16,  2,  3,  6,  9, 10

#define ss0(x)    (((x) >> 1) ^ SPH_T32((x) << 3) \
                  ^ SPH_ROTL32(x,  4) ^ SPH_ROTL32(x, 19))
#define ss1(x)    (((x) >> 1) ^ SPH_T32((x) << 2) \
                  ^ SPH_ROTL32(x,  8) ^ SPH_ROTL32(x, 23))
#define ss2(x)    (((x) >> 2) ^ SPH_T32((x) << 1) \
                  ^ SPH_ROTL32(x, 12) ^ SPH_ROTL32(x, 25))
#define ss3(x)    (((x) >> 2) ^ SPH_T32((x) << 2) \
                  ^ SPH_ROTL32(x, 15) ^ SPH_ROTL32(x, 29))
#define ss4(x)    (((x) >> 1) ^ (x))
#define ss5(x)    (((x) >> 2) ^ (x))
#define rs1(x)    SPH_ROTL32(x,  3)
#define rs2(x)    SPH_ROTL32(x,  7)
#define rs3(x)    SPH_ROTL32(x, 13)
#define rs4(x)    SPH_ROTL32(x, 16)
#define rs5(x)    SPH_ROTL32(x, 19)
#define rs6(x)    SPH_ROTL32(x, 23)
#define rs7(x)    SPH_ROTL32(x, 27)

#define Ks(j)   SPH_T32((sph_u32)(j) * SPH_C32(0x05555555))

#define add_elt_s(mf, hf, j0m, j1m, j3m, j4m, j7m, j10m, j11m, j16) \
  (SPH_T32(SPH_ROTL32(mf(j0m), j1m) + SPH_ROTL32(mf(j3m), j4m) \
    - SPH_ROTL32(mf(j10m), j11m) + Ks(j16)) ^ hf(j7m))

#define expand1s_inner(qf, mf, hf, i16, \
    i0, i1, i2, i3, i4, i5, i6, i7, i8, \
    i9, i10, i11, i12, i13, i14, i15, \
    i0m, i1m, i3m, i4m, i7m, i10m, i11m) \
  SPH_T32(ss1(qf(i0)) + ss2(qf(i1)) + ss3(qf(i2)) + ss0(qf(i3)) \
    + ss1(qf(i4)) + ss2(qf(i5)) + ss3(qf(i6)) + ss0(qf(i7)) \
    + ss1(qf(i8)) + ss2(qf(i9)) + ss3(qf(i10)) + ss0(qf(i11)) \
    + ss1(qf(i12)) + ss2(qf(i13)) + ss3(qf(i14)) + ss0(qf(i15)) \
    + add_elt_s(mf, hf, i0m, i1m, i3m, i4m, i7m, i10m, i11m, i16))

#define expand1s(qf, mf, hf, i16) \
  expand1s_(qf, mf, hf, i16, I16_ ## i16, M16_ ## i16)
#define expand1s_(qf, mf, hf, i16, ix, iy) \
  expand1s_inner LPAR qf, mf, hf, i16, ix, iy)

#define expand2s_inner(qf, mf, hf, i16, \
    i0, i1, i2, i3, i4, i5, i6, i7, i8, \
    i9, i10, i11, i12, i13, i14, i15, \
    i0m, i1m, i3m, i4m, i7m, i10m, i11m) \
  SPH_T32(qf(i0) + rs1(qf(i1)) + qf(i2) + rs2(qf(i3)) \
    + qf(i4) + rs3(qf(i5)) + qf(i6) + rs4(qf(i7)) \
    + qf(i8) + rs5(qf(i9)) + qf(i10) + rs6(qf(i11)) \
    + qf(i12) + rs7(qf(i13)) + ss4(qf(i14)) + ss5(qf(i15)) \
    + add_elt_s(mf, hf, i0m, i1m, i3m, i4m, i7m, i10m, i11m, i16))

#define expand2s(qf, mf, hf, i16) \
  expand2s_(qf, mf, hf, i16, I16_ ## i16, M16_ ## i16)
#define expand2s_(qf, mf, hf, i16, ix, iy) \
  expand2s_inner LPAR qf, mf, hf, i16, ix, iy)

#if SPH_64

#define sb0(x)    (((x) >> 1) ^ SPH_T64((x) << 3) \
                  ^ SPH_ROTL64(x,  4) ^ SPH_ROTL64(x, 37))
#define sb1(x)    (((x) >> 1) ^ SPH_T64((x) << 2) \
                  ^ SPH_ROTL64(x, 13) ^ SPH_ROTL64(x, 43))
#define sb2(x)    (((x) >> 2) ^ SPH_T64((x) << 1) \
                  ^ SPH_ROTL64(x, 19) ^ SPH_ROTL64(x, 53))
#define sb3(x)    (((x) >> 2) ^ SPH_T64((x) << 2) \
                  ^ SPH_ROTL64(x, 28) ^ SPH_ROTL64(x, 59))
#define sb4(x)    (((x) >> 1) ^ (x))
#define sb5(x)    (((x) >> 2) ^ (x))
#define rb1(x)    SPH_ROTL64(x,  5)
#define rb2(x)    SPH_ROTL64(x, 11)
#define rb3(x)    SPH_ROTL64(x, 27)
#define rb4(x)    SPH_ROTL64(x, 32)
#define rb5(x)    SPH_ROTL64(x, 37)
#define rb6(x)    SPH_ROTL64(x, 43)
#define rb7(x)    SPH_ROTL64(x, 53)

#define Kb(j)   SPH_T64((sph_u64)(j) * SPH_C64(0x0555555555555555))

#define add_elt_b(mf, hf, j0m, j1m, j3m, j4m, j7m, j10m, j11m, j16) \
  (SPH_T64(SPH_ROTL64(mf(j0m), j1m) + SPH_ROTL64(mf(j3m), j4m) \
    - SPH_ROTL64(mf(j10m), j11m) + Kb(j16)) ^ hf(j7m))

#define expand1b_inner(qf, mf, hf, i16, \
    i0, i1, i2, i3, i4, i5, i6, i7, i8, \
    i9, i10, i11, i12, i13, i14, i15, \
    i0m, i1m, i3m, i4m, i7m, i10m, i11m) \
  SPH_T64(sb1(qf(i0)) + sb2(qf(i1)) + sb3(qf(i2)) + sb0(qf(i3)) \
    + sb1(qf(i4)) + sb2(qf(i5)) + sb3(qf(i6)) + sb0(qf(i7)) \
    + sb1(qf(i8)) + sb2(qf(i9)) + sb3(qf(i10)) + sb0(qf(i11)) \
    + sb1(qf(i12)) + sb2(qf(i13)) + sb3(qf(i14)) + sb0(qf(i15)) \
    + add_elt_b(mf, hf, i0m, i1m, i3m, i4m, i7m, i10m, i11m, i16))

#define expand1b(qf, mf, hf, i16) \
  expand1b_(qf, mf, hf, i16, I16_ ## i16, M16_ ## i16)
#define expand1b_(qf, mf, hf, i16, ix, iy) \
  expand1b_inner LPAR qf, mf, hf, i16, ix, iy)

#define expand2b_inner(qf, mf, hf, i16, \
    i0, i1, i2, i3, i4, i5, i6, i7, i8, \
    i9, i10, i11, i12, i13, i14, i15, \
    i0m, i1m, i3m, i4m, i7m, i10m, i11m) \
  SPH_T64(qf(i0) + rb1(qf(i1)) + qf(i2) + rb2(qf(i3)) \
    + qf(i4) + rb3(qf(i5)) + qf(i6) + rb4(qf(i7)) \
    + qf(i8) + rb5(qf(i9)) + qf(i10) + rb6(qf(i11)) \
    + qf(i12) + rb7(qf(i13)) + sb4(qf(i14)) + sb5(qf(i15)) \
    + add_elt_b(mf, hf, i0m, i1m, i3m, i4m, i7m, i10m, i11m, i16))

#define expand2b(qf, mf, hf, i16) \
  expand2b_(qf, mf, hf, i16, I16_ ## i16, M16_ ## i16)
#define expand2b_(qf, mf, hf, i16, ix, iy) \
  expand2b_inner LPAR qf, mf, hf, i16, ix, iy)

#endif

#define MAKE_W(tt, i0, op01, i1, op12, i2, op23, i3, op34, i4) \
  tt((M(i0) ^ H(i0)) op01 (M(i1) ^ H(i1)) op12 (M(i2) ^ H(i2)) \
  op23 (M(i3) ^ H(i3)) op34 (M(i4) ^ H(i4)))

#define Ws0    MAKE_W(SPH_T32,  5, -,  7, +, 10, +, 13, +, 14)
#define Ws1    MAKE_W(SPH_T32,  6, -,  8, +, 11, +, 14, -, 15)
#define Ws2    MAKE_W(SPH_T32,  0, +,  7, +,  9, -, 12, +, 15)
#define Ws3    MAKE_W(SPH_T32,  0, -,  1, +,  8, -, 10, +, 13)
#define Ws4    MAKE_W(SPH_T32,  1, +,  2, +,  9, -, 11, -, 14)
#define Ws5    MAKE_W(SPH_T32,  3, -,  2, +, 10, -, 12, +, 15)
#define Ws6    MAKE_W(SPH_T32,  4, -,  0, -,  3, -, 11, +, 13)
#define Ws7    MAKE_W(SPH_T32,  1, -,  4, -,  5, -, 12, -, 14)
#define Ws8    MAKE_W(SPH_T32,  2, -,  5, -,  6, +, 13, -, 15)
#define Ws9    MAKE_W(SPH_T32,  0, -,  3, +,  6, -,  7, +, 14)
#define Ws10   MAKE_W(SPH_T32,  8, -,  1, -,  4, -,  7, +, 15)
#define Ws11   MAKE_W(SPH_T32,  8, -,  0, -,  2, -,  5, +,  9)
#define Ws12   MAKE_W(SPH_T32,  1, +,  3, -,  6, -,  9, +, 10)
#define Ws13   MAKE_W(SPH_T32,  2, +,  4, +,  7, +, 10, +, 11)
#define Ws14   MAKE_W(SPH_T32,  3, -,  5, +,  8, -, 11, -, 12)
#define Ws15   MAKE_W(SPH_T32, 12, -,  4, -,  6, -,  9, +, 13)

#define MAKE_Qas   do { \
    qt[ 0] = SPH_T32(ss0(Ws0 ) + H( 1)); \
    qt[ 1] = SPH_T32(ss1(Ws1 ) + H( 2)); \
    qt[ 2] = SPH_T32(ss2(Ws2 ) + H( 3)); \
    qt[ 3] = SPH_T32(ss3(Ws3 ) + H( 4)); \
    qt[ 4] = SPH_T32(ss4(Ws4 ) + H( 5)); \
    qt[ 5] = SPH_T32(ss0(Ws5 ) + H( 6)); \
    qt[ 6] = SPH_T32(ss1(Ws6 ) + H( 7)); \
    qt[ 7] = SPH_T32(ss2(Ws7 ) + H( 8)); \
    qt[ 8] = SPH_T32(ss3(Ws8 ) + H( 9)); \
    qt[ 9] = SPH_T32(ss4(Ws9 ) + H(10)); \
    qt[10] = SPH_T32(ss0(Ws10) + H(11)); \
    qt[11] = SPH_T32(ss1(Ws11) + H(12)); \
    qt[12] = SPH_T32(ss2(Ws12) + H(13)); \
    qt[13] = SPH_T32(ss3(Ws13) + H(14)); \
    qt[14] = SPH_T32(ss4(Ws14) + H(15)); \
    qt[15] = SPH_T32(ss0(Ws15) + H( 0)); \
  } while (0)

#define MAKE_Qbs   do { \
    qt[16] = expand1s(Qs, M, H, 16); \
    qt[17] = expand1s(Qs, M, H, 17); \
    qt[18] = expand2s(Qs, M, H, 18); \
    qt[19] = expand2s(Qs, M, H, 19); \
    qt[20] = expand2s(Qs, M, H, 20); \
    qt[21] = expand2s(Qs, M, H, 21); \
    qt[22] = expand2s(Qs, M, H, 22); \
    qt[23] = expand2s(Qs, M, H, 23); \
    qt[24] = expand2s(Qs, M, H, 24); \
    qt[25] = expand2s(Qs, M, H, 25); \
    qt[26] = expand2s(Qs, M, H, 26); \
    qt[27] = expand2s(Qs, M, H, 27); \
    qt[28] = expand2s(Qs, M, H, 28); \
    qt[29] = expand2s(Qs, M, H, 29); \
    qt[30] = expand2s(Qs, M, H, 30); \
    qt[31] = expand2s(Qs, M, H, 31); \
  } while (0)

#define MAKE_Qs   do { \
    MAKE_Qas; \
    MAKE_Qbs; \
  } while (0)

#define Qs(j)   (qt[j])

#if SPH_64

#define Wb0    MAKE_W(SPH_T64,  5, -,  7, +, 10, +, 13, +, 14)
#define Wb1    MAKE_W(SPH_T64,  6, -,  8, +, 11, +, 14, -, 15)
#define Wb2    MAKE_W(SPH_T64,  0, +,  7, +,  9, -, 12, +, 15)
#define Wb3    MAKE_W(SPH_T64,  0, -,  1, +,  8, -, 10, +, 13)
#define Wb4    MAKE_W(SPH_T64,  1, +,  2, +,  9, -, 11, -, 14)
#define Wb5    MAKE_W(SPH_T64,  3, -,  2, +, 10, -, 12, +, 15)
#define Wb6    MAKE_W(SPH_T64,  4, -,  0, -,  3, -, 11, +, 13)
#define Wb7    MAKE_W(SPH_T64,  1, -,  4, -,  5, -, 12, -, 14)
#define Wb8    MAKE_W(SPH_T64,  2, -,  5, -,  6, +, 13, -, 15)
#define Wb9    MAKE_W(SPH_T64,  0, -,  3, +,  6, -,  7, +, 14)
#define Wb10   MAKE_W(SPH_T64,  8, -,  1, -,  4, -,  7, +, 15)
#define Wb11   MAKE_W(SPH_T64,  8, -,  0, -,  2, -,  5, +,  9)
#define Wb12   MAKE_W(SPH_T64,  1, +,  3, -,  6, -,  9, +, 10)
#define Wb13   MAKE_W(SPH_T64,  2, +,  4, +,  7, +, 10, +, 11)
#define Wb14   MAKE_W(SPH_T64,  3, -,  5, +,  8, -, 11, -, 12)
#define Wb15   MAKE_W(SPH_T64, 12, -,  4, -,  6, -,  9, +, 13)

#define MAKE_Qab   do { \
    qt[ 0] = SPH_T64(sb0(Wb0 ) + H( 1)); \
    qt[ 1] = SPH_T64(sb1(Wb1 ) + H( 2)); \
    qt[ 2] = SPH_T64(sb2(Wb2 ) + H( 3)); \
    qt[ 3] = SPH_T64(sb3(Wb3 ) + H( 4)); \
    qt[ 4] = SPH_T64(sb4(Wb4 ) + H( 5)); \
    qt[ 5] = SPH_T64(sb0(Wb5 ) + H( 6)); \
    qt[ 6] = SPH_T64(sb1(Wb6 ) + H( 7)); \
    qt[ 7] = SPH_T64(sb2(Wb7 ) + H( 8)); \
    qt[ 8] = SPH_T64(sb3(Wb8 ) + H( 9)); \
    qt[ 9] = SPH_T64(sb4(Wb9 ) + H(10)); \
    qt[10] = SPH_T64(sb0(Wb10) + H(11)); \
    qt[11] = SPH_T64(sb1(Wb11) + H(12)); \
    qt[12] = SPH_T64(sb2(Wb12) + H(13)); \
    qt[13] = SPH_T64(sb3(Wb13) + H(14)); \
    qt[14] = SPH_T64(sb4(Wb14) + H(15)); \
    qt[15] = SPH_T64(sb0(Wb15) + H( 0)); \
  } while (0)

#define MAKE_Qbb   do { \
    qt[16] = expand1b(Qb, M, H, 16); \
    qt[17] = expand1b(Qb, M, H, 17); \
    qt[18] = expand2b(Qb, M, H, 18); \
    qt[19] = expand2b(Qb, M, H, 19); \
    qt[20] = expand2b(Qb, M, H, 20); \
    qt[21] = expand2b(Qb, M, H, 21); \
    qt[22] = expand2b(Qb, M, H, 22); \
    qt[23] = expand2b(Qb, M, H, 23); \
    qt[24] = expand2b(Qb, M, H, 24); \
    qt[25] = expand2b(Qb, M, H, 25); \
    qt[26] = expand2b(Qb, M, H, 26); \
    qt[27] = expand2b(Qb, M, H, 27); \
    qt[28] = expand2b(Qb, M, H, 28); \
    qt[29] = expand2b(Qb, M, H, 29); \
    qt[30] = expand2b(Qb, M, H, 30); \
    qt[31] = expand2b(Qb, M, H, 31); \
  } while (0)

#define MAKE_Qb   do { \
    MAKE_Qab; \
    MAKE_Qbb; \
  } while (0)

#define Qb(j)   (qt[j])

#endif

#define FOLD(type, mkQ, tt, rol, mf, qf, dhf)   do { \
    type qt[32], xl, xh; \
    mkQ; \
    xl = qf(16) ^ qf(17) ^ qf(18) ^ qf(19) \
      ^ qf(20) ^ qf(21) ^ qf(22) ^ qf(23); \
    xh = xl ^ qf(24) ^ qf(25) ^ qf(26) ^ qf(27) \
      ^ qf(28) ^ qf(29) ^ qf(30) ^ qf(31); \
    dhf( 0) = tt(((xh <<  5) ^ (qf(16) >>  5) ^ mf( 0)) \
      + (xl ^ qf(24) ^ qf( 0))); \
    dhf( 1) = tt(((xh >>  7) ^ (qf(17) <<  8) ^ mf( 1)) \
      + (xl ^ qf(25) ^ qf( 1))); \
    dhf( 2) = tt(((xh >>  5) ^ (qf(18) <<  5) ^ mf( 2)) \
      + (xl ^ qf(26) ^ qf( 2))); \
    dhf( 3) = tt(((xh >>  1) ^ (qf(19) <<  5) ^ mf( 3)) \
      + (xl ^ qf(27) ^ qf( 3))); \
    dhf( 4) = tt(((xh >>  3) ^ (qf(20) <<  0) ^ mf( 4)) \
      + (xl ^ qf(28) ^ qf( 4))); \
    dhf( 5) = tt(((xh <<  6) ^ (qf(21) >>  6) ^ mf( 5)) \
      + (xl ^ qf(29) ^ qf( 5))); \
    dhf( 6) = tt(((xh >>  4) ^ (qf(22) <<  6) ^ mf( 6)) \
      + (xl ^ qf(30) ^ qf( 6))); \
    dhf( 7) = tt(((xh >> 11) ^ (qf(23) <<  2) ^ mf( 7)) \
      + (xl ^ qf(31) ^ qf( 7))); \
    dhf( 8) = tt(rol(dhf(4),  9) + (xh ^ qf(24) ^ mf( 8)) \
      + ((xl << 8) ^ qf(23) ^ qf( 8))); \
    dhf( 9) = tt(rol(dhf(5), 10) + (xh ^ qf(25) ^ mf( 9)) \
      + ((xl >> 6) ^ qf(16) ^ qf( 9))); \
    dhf(10) = tt(rol(dhf(6), 11) + (xh ^ qf(26) ^ mf(10)) \
      + ((xl << 6) ^ qf(17) ^ qf(10))); \
    dhf(11) = tt(rol(dhf(7), 12) + (xh ^ qf(27) ^ mf(11)) \
      + ((xl << 4) ^ qf(18) ^ qf(11))); \
    dhf(12) = tt(rol(dhf(0), 13) + (xh ^ qf(28) ^ mf(12)) \
      + ((xl >> 3) ^ qf(19) ^ qf(12))); \
    dhf(13) = tt(rol(dhf(1), 14) + (xh ^ qf(29) ^ mf(13)) \
      + ((xl >> 4) ^ qf(20) ^ qf(13))); \
    dhf(14) = tt(rol(dhf(2), 15) + (xh ^ qf(30) ^ mf(14)) \
      + ((xl >> 7) ^ qf(21) ^ qf(14))); \
    dhf(15) = tt(rol(dhf(3), 16) + (xh ^ qf(31) ^ mf(15)) \
      + ((xl >> 2) ^ qf(22) ^ qf(15))); \
  } while (0)

#define FOLDb   FOLD(sph_u64, MAKE_Qb, SPH_T64, SPH_ROTL64, M, Qb, dH)

__constant const sph_u64 final_b[16] = {
  SPH_C64(0xaaaaaaaaaaaaaaa0), SPH_C64(0xaaaaaaaaaaaaaaa1),
  SPH_C64(0xaaaaaaaaaaaaaaa2), SPH_C64(0xaaaaaaaaaaaaaaa3),
  SPH_C64(0xaaaaaaaaaaaaaaa4), SPH_C64(0xaaaaaaaaaaaaaaa5),
  SPH_C64(0xaaaaaaaaaaaaaaa6), SPH_C64(0xaaaaaaaaaaaaaaa7),
  SPH_C64(0xaaaaaaaaaaaaaaa8), SPH_C64(0xaaaaaaaaaaaaaaa9),
  SPH_C64(0xaaaaaaaaaaaaaaaa), SPH_C64(0xaaaaaaaaaaaaaaab),
  SPH_C64(0xaaaaaaaaaaaaaaac), SPH_C64(0xaaaaaaaaaaaaaaad),
  SPH_C64(0xaaaaaaaaaaaaaaae), SPH_C64(0xaaaaaaaaaaaaaaaf)
};

/* $Id: groestl.c 260 2011-07-21 01:02:38Z tp $ */
/*
 * Groestl implementation.
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

/*
 * Apparently, the 32-bit-only version is not faster than the 64-bit
 * version unless using the "small footprint" code on a 32-bit machine.
 */
#if !defined SPH_GROESTL_64
#if SPH_SMALL_FOOTPRINT_GROESTL && !SPH_64_TRUE
#define SPH_GROESTL_64   0
#else
#define SPH_GROESTL_64   1
#endif
#endif

/*
 * The internal representation may use either big-endian or
 * little-endian. Using the platform default representation speeds up
 * encoding and decoding between bytes and the matrix columns.
 */

#undef USE_LE
#if SPH_GROESTL_LITTLE_ENDIAN
#define USE_LE   1
#elif SPH_GROESTL_BIG_ENDIAN
#define USE_LE   0
#elif SPH_LITTLE_ENDIAN
#define USE_LE   1
#endif

#if USE_LE

#if SPH_64
#define C64e(x)     ((SPH_C64(x) >> 56) \
                    | ((SPH_C64(x) >> 40) & SPH_C64(0x000000000000FF00)) \
                    | ((SPH_C64(x) >> 24) & SPH_C64(0x0000000000FF0000)) \
                    | ((SPH_C64(x) >>  8) & SPH_C64(0x00000000FF000000)) \
                    | ((SPH_C64(x) <<  8) & SPH_C64(0x000000FF00000000)) \
                    | ((SPH_C64(x) << 24) & SPH_C64(0x0000FF0000000000)) \
                    | ((SPH_C64(x) << 40) & SPH_C64(0x00FF000000000000)) \
                    | ((SPH_C64(x) << 56) & SPH_C64(0xFF00000000000000)))
#define dec64e_aligned   sph_dec64le_aligned
#define enc64e           sph_enc64le
#define B64_0(x)    as_uchar8(x).s0
#define B64_1(x)    as_uchar8(x).s1
#define B64_2(x)    as_uchar8(x).s2
#define B64_3(x)    as_uchar8(x).s3
#define B64_4(x)    as_uchar8(x).s4
#define B64_5(x)    as_uchar8(x).s5
#define B64_6(x)    as_uchar8(x).s6
#define B64_7(x)    as_uchar8(x).s7
#define R64         SPH_ROTL64
#define PC64(j, r)  ((sph_u64)((j) + (r)))
#define QC64(j, r)  (((sph_u64)(r) << 56) ^ SPH_T64(~((sph_u64)(j) << 56)))
#endif

#else

#if SPH_64
#define C64e(x)     SPH_C64(x)
#define dec64e_aligned   sph_dec64be_aligned
#define enc64e           sph_enc64be
#define B64_0(x)    ((x) >> 56)
#define B64_1(x)    (((x) >> 48) & 0xFF)
#define B64_2(x)    (((x) >> 40) & 0xFF)
#define B64_3(x)    (((x) >> 32) & 0xFF)
#define B64_4(x)    (((x) >> 24) & 0xFF)
#define B64_5(x)    (((x) >> 16) & 0xFF)
#define B64_6(x)    (((x) >> 8) & 0xFF)
#define B64_7(x)    ((x) & 0xFF)
#define R64         SPH_ROTR64
#define PC64(j, r)  ((sph_u64)((j) + (r)) << 56)
#define QC64(j, r)  ((sph_u64)(r) ^ SPH_T64(~(sph_u64)(j)))
#endif

#endif

__constant const sph_u64 T0_C[] = {
  C64e(0xc632f4a5f497a5c6), C64e(0xf86f978497eb84f8),
  C64e(0xee5eb099b0c799ee), C64e(0xf67a8c8d8cf78df6),
  C64e(0xffe8170d17e50dff), C64e(0xd60adcbddcb7bdd6),
  C64e(0xde16c8b1c8a7b1de), C64e(0x916dfc54fc395491),
  C64e(0x6090f050f0c05060), C64e(0x0207050305040302),
  C64e(0xce2ee0a9e087a9ce), C64e(0x56d1877d87ac7d56),
  C64e(0xe7cc2b192bd519e7), C64e(0xb513a662a67162b5),
  C64e(0x4d7c31e6319ae64d), C64e(0xec59b59ab5c39aec),
  C64e(0x8f40cf45cf05458f), C64e(0x1fa3bc9dbc3e9d1f),
  C64e(0x8949c040c0094089), C64e(0xfa68928792ef87fa),
  C64e(0xefd03f153fc515ef), C64e(0xb29426eb267febb2),
  C64e(0x8ece40c94007c98e), C64e(0xfbe61d0b1ded0bfb),
  C64e(0x416e2fec2f82ec41), C64e(0xb31aa967a97d67b3),
  C64e(0x5f431cfd1cbefd5f), C64e(0x456025ea258aea45),
  C64e(0x23f9dabfda46bf23), C64e(0x535102f702a6f753),
  C64e(0xe445a196a1d396e4), C64e(0x9b76ed5bed2d5b9b),
  C64e(0x75285dc25deac275), C64e(0xe1c5241c24d91ce1),
  C64e(0x3dd4e9aee97aae3d), C64e(0x4cf2be6abe986a4c),
  C64e(0x6c82ee5aeed85a6c), C64e(0x7ebdc341c3fc417e),
  C64e(0xf5f3060206f102f5), C64e(0x8352d14fd11d4f83),
  C64e(0x688ce45ce4d05c68), C64e(0x515607f407a2f451),
  C64e(0xd18d5c345cb934d1), C64e(0xf9e1180818e908f9),
  C64e(0xe24cae93aedf93e2), C64e(0xab3e9573954d73ab),
  C64e(0x6297f553f5c45362), C64e(0x2a6b413f41543f2a),
  C64e(0x081c140c14100c08), C64e(0x9563f652f6315295),
  C64e(0x46e9af65af8c6546), C64e(0x9d7fe25ee2215e9d),
  C64e(0x3048782878602830), C64e(0x37cff8a1f86ea137),
  C64e(0x0a1b110f11140f0a), C64e(0x2febc4b5c45eb52f),
  C64e(0x0e151b091b1c090e), C64e(0x247e5a365a483624),
  C64e(0x1badb69bb6369b1b), C64e(0xdf98473d47a53ddf),
  C64e(0xcda76a266a8126cd), C64e(0x4ef5bb69bb9c694e),
  C64e(0x7f334ccd4cfecd7f), C64e(0xea50ba9fbacf9fea),
  C64e(0x123f2d1b2d241b12), C64e(0x1da4b99eb93a9e1d),
  C64e(0x58c49c749cb07458), C64e(0x3446722e72682e34),
  C64e(0x3641772d776c2d36), C64e(0xdc11cdb2cda3b2dc),
  C64e(0xb49d29ee2973eeb4), C64e(0x5b4d16fb16b6fb5b),
  C64e(0xa4a501f60153f6a4), C64e(0x76a1d74dd7ec4d76),
  C64e(0xb714a361a37561b7), C64e(0x7d3449ce49face7d),
  C64e(0x52df8d7b8da47b52), C64e(0xdd9f423e42a13edd),
  C64e(0x5ecd937193bc715e), C64e(0x13b1a297a2269713),
  C64e(0xa6a204f50457f5a6), C64e(0xb901b868b86968b9),
  C64e(0x0000000000000000), C64e(0xc1b5742c74992cc1),
  C64e(0x40e0a060a0806040), C64e(0xe3c2211f21dd1fe3),
  C64e(0x793a43c843f2c879), C64e(0xb69a2ced2c77edb6),
  C64e(0xd40dd9bed9b3bed4), C64e(0x8d47ca46ca01468d),
  C64e(0x671770d970ced967), C64e(0x72afdd4bdde44b72),
  C64e(0x94ed79de7933de94), C64e(0x98ff67d4672bd498),
  C64e(0xb09323e8237be8b0), C64e(0x855bde4ade114a85),
  C64e(0xbb06bd6bbd6d6bbb), C64e(0xc5bb7e2a7e912ac5),
  C64e(0x4f7b34e5349ee54f), C64e(0xedd73a163ac116ed),
  C64e(0x86d254c55417c586), C64e(0x9af862d7622fd79a),
  C64e(0x6699ff55ffcc5566), C64e(0x11b6a794a7229411),
  C64e(0x8ac04acf4a0fcf8a), C64e(0xe9d9301030c910e9),
  C64e(0x040e0a060a080604), C64e(0xfe66988198e781fe),
  C64e(0xa0ab0bf00b5bf0a0), C64e(0x78b4cc44ccf04478),
  C64e(0x25f0d5bad54aba25), C64e(0x4b753ee33e96e34b),
  C64e(0xa2ac0ef30e5ff3a2), C64e(0x5d4419fe19bafe5d),
  C64e(0x80db5bc05b1bc080), C64e(0x0580858a850a8a05),
  C64e(0x3fd3ecadec7ead3f), C64e(0x21fedfbcdf42bc21),
  C64e(0x70a8d848d8e04870), C64e(0xf1fd0c040cf904f1),
  C64e(0x63197adf7ac6df63), C64e(0x772f58c158eec177),
  C64e(0xaf309f759f4575af), C64e(0x42e7a563a5846342),
  C64e(0x2070503050403020), C64e(0xe5cb2e1a2ed11ae5),
  C64e(0xfdef120e12e10efd), C64e(0xbf08b76db7656dbf),
  C64e(0x8155d44cd4194c81), C64e(0x18243c143c301418),
  C64e(0x26795f355f4c3526), C64e(0xc3b2712f719d2fc3),
  C64e(0xbe8638e13867e1be), C64e(0x35c8fda2fd6aa235),
  C64e(0x88c74fcc4f0bcc88), C64e(0x2e654b394b5c392e),
  C64e(0x936af957f93d5793), C64e(0x55580df20daaf255),
  C64e(0xfc619d829de382fc), C64e(0x7ab3c947c9f4477a),
  C64e(0xc827efacef8bacc8), C64e(0xba8832e7326fe7ba),
  C64e(0x324f7d2b7d642b32), C64e(0xe642a495a4d795e6),
  C64e(0xc03bfba0fb9ba0c0), C64e(0x19aab398b3329819),
  C64e(0x9ef668d16827d19e), C64e(0xa322817f815d7fa3),
  C64e(0x44eeaa66aa886644), C64e(0x54d6827e82a87e54),
  C64e(0x3bdde6abe676ab3b), C64e(0x0b959e839e16830b),
  C64e(0x8cc945ca4503ca8c), C64e(0xc7bc7b297b9529c7),
  C64e(0x6b056ed36ed6d36b), C64e(0x286c443c44503c28),
  C64e(0xa72c8b798b5579a7), C64e(0xbc813de23d63e2bc),
  C64e(0x1631271d272c1d16), C64e(0xad379a769a4176ad),
  C64e(0xdb964d3b4dad3bdb), C64e(0x649efa56fac85664),
  C64e(0x74a6d24ed2e84e74), C64e(0x1436221e22281e14),
  C64e(0x92e476db763fdb92), C64e(0x0c121e0a1e180a0c),
  C64e(0x48fcb46cb4906c48), C64e(0xb88f37e4376be4b8),
  C64e(0x9f78e75de7255d9f), C64e(0xbd0fb26eb2616ebd),
  C64e(0x43692aef2a86ef43), C64e(0xc435f1a6f193a6c4),
  C64e(0x39dae3a8e372a839), C64e(0x31c6f7a4f762a431),
  C64e(0xd38a593759bd37d3), C64e(0xf274868b86ff8bf2),
  C64e(0xd583563256b132d5), C64e(0x8b4ec543c50d438b),
  C64e(0x6e85eb59ebdc596e), C64e(0xda18c2b7c2afb7da),
  C64e(0x018e8f8c8f028c01), C64e(0xb11dac64ac7964b1),
  C64e(0x9cf16dd26d23d29c), C64e(0x49723be03b92e049),
  C64e(0xd81fc7b4c7abb4d8), C64e(0xacb915fa1543faac),
  C64e(0xf3fa090709fd07f3), C64e(0xcfa06f256f8525cf),
  C64e(0xca20eaafea8fafca), C64e(0xf47d898e89f38ef4),
  C64e(0x476720e9208ee947), C64e(0x1038281828201810),
  C64e(0x6f0b64d564ded56f), C64e(0xf073838883fb88f0),
  C64e(0x4afbb16fb1946f4a), C64e(0x5cca967296b8725c),
  C64e(0x38546c246c702438), C64e(0x575f08f108aef157),
  C64e(0x732152c752e6c773), C64e(0x9764f351f3355197),
  C64e(0xcbae6523658d23cb), C64e(0xa125847c84597ca1),
  C64e(0xe857bf9cbfcb9ce8), C64e(0x3e5d6321637c213e),
  C64e(0x96ea7cdd7c37dd96), C64e(0x611e7fdc7fc2dc61),
  C64e(0x0d9c9186911a860d), C64e(0x0f9b9485941e850f),
  C64e(0xe04bab90abdb90e0), C64e(0x7cbac642c6f8427c),
  C64e(0x712657c457e2c471), C64e(0xcc29e5aae583aacc),
  C64e(0x90e373d8733bd890), C64e(0x06090f050f0c0506),
  C64e(0xf7f4030103f501f7), C64e(0x1c2a36123638121c),
  C64e(0xc23cfea3fe9fa3c2), C64e(0x6a8be15fe1d45f6a),
  C64e(0xaebe10f91047f9ae), C64e(0x69026bd06bd2d069),
  C64e(0x17bfa891a82e9117), C64e(0x9971e858e8295899),
  C64e(0x3a5369276974273a), C64e(0x27f7d0b9d04eb927),
  C64e(0xd991483848a938d9), C64e(0xebde351335cd13eb),
  C64e(0x2be5ceb3ce56b32b), C64e(0x2277553355443322),
  C64e(0xd204d6bbd6bfbbd2), C64e(0xa9399070904970a9),
  C64e(0x07878089800e8907), C64e(0x33c1f2a7f266a733),
  C64e(0x2decc1b6c15ab62d), C64e(0x3c5a66226678223c),
  C64e(0x15b8ad92ad2a9215), C64e(0xc9a96020608920c9),
  C64e(0x875cdb49db154987), C64e(0xaab01aff1a4fffaa),
  C64e(0x50d8887888a07850), C64e(0xa52b8e7a8e517aa5),
  C64e(0x03898a8f8a068f03), C64e(0x594a13f813b2f859),
  C64e(0x09929b809b128009), C64e(0x1a2339173934171a),
  C64e(0x651075da75cada65), C64e(0xd784533153b531d7),
  C64e(0x84d551c65113c684), C64e(0xd003d3b8d3bbb8d0),
  C64e(0x82dc5ec35e1fc382), C64e(0x29e2cbb0cb52b029),
  C64e(0x5ac3997799b4775a), C64e(0x1e2d3311333c111e),
  C64e(0x7b3d46cb46f6cb7b), C64e(0xa8b71ffc1f4bfca8),
  C64e(0x6d0c61d661dad66d), C64e(0x2c624e3a4e583a2c)
};

#if !SPH_SMALL_FOOTPRINT_GROESTL

__constant const sph_u64 T1_C[] = {
  C64e(0xc6c632f4a5f497a5), C64e(0xf8f86f978497eb84),
  C64e(0xeeee5eb099b0c799), C64e(0xf6f67a8c8d8cf78d),
  C64e(0xffffe8170d17e50d), C64e(0xd6d60adcbddcb7bd),
  C64e(0xdede16c8b1c8a7b1), C64e(0x91916dfc54fc3954),
  C64e(0x606090f050f0c050), C64e(0x0202070503050403),
  C64e(0xcece2ee0a9e087a9), C64e(0x5656d1877d87ac7d),
  C64e(0xe7e7cc2b192bd519), C64e(0xb5b513a662a67162),
  C64e(0x4d4d7c31e6319ae6), C64e(0xecec59b59ab5c39a),
  C64e(0x8f8f40cf45cf0545), C64e(0x1f1fa3bc9dbc3e9d),
  C64e(0x898949c040c00940), C64e(0xfafa68928792ef87),
  C64e(0xefefd03f153fc515), C64e(0xb2b29426eb267feb),
  C64e(0x8e8ece40c94007c9), C64e(0xfbfbe61d0b1ded0b),
  C64e(0x41416e2fec2f82ec), C64e(0xb3b31aa967a97d67),
  C64e(0x5f5f431cfd1cbefd), C64e(0x45456025ea258aea),
  C64e(0x2323f9dabfda46bf), C64e(0x53535102f702a6f7),
  C64e(0xe4e445a196a1d396), C64e(0x9b9b76ed5bed2d5b),
  C64e(0x7575285dc25deac2), C64e(0xe1e1c5241c24d91c),
  C64e(0x3d3dd4e9aee97aae), C64e(0x4c4cf2be6abe986a),
  C64e(0x6c6c82ee5aeed85a), C64e(0x7e7ebdc341c3fc41),
  C64e(0xf5f5f3060206f102), C64e(0x838352d14fd11d4f),
  C64e(0x68688ce45ce4d05c), C64e(0x51515607f407a2f4),
  C64e(0xd1d18d5c345cb934), C64e(0xf9f9e1180818e908),
  C64e(0xe2e24cae93aedf93), C64e(0xabab3e9573954d73),
  C64e(0x626297f553f5c453), C64e(0x2a2a6b413f41543f),
  C64e(0x08081c140c14100c), C64e(0x959563f652f63152),
  C64e(0x4646e9af65af8c65), C64e(0x9d9d7fe25ee2215e),
  C64e(0x3030487828786028), C64e(0x3737cff8a1f86ea1),
  C64e(0x0a0a1b110f11140f), C64e(0x2f2febc4b5c45eb5),
  C64e(0x0e0e151b091b1c09), C64e(0x24247e5a365a4836),
  C64e(0x1b1badb69bb6369b), C64e(0xdfdf98473d47a53d),
  C64e(0xcdcda76a266a8126), C64e(0x4e4ef5bb69bb9c69),
  C64e(0x7f7f334ccd4cfecd), C64e(0xeaea50ba9fbacf9f),
  C64e(0x12123f2d1b2d241b), C64e(0x1d1da4b99eb93a9e),
  C64e(0x5858c49c749cb074), C64e(0x343446722e72682e),
  C64e(0x363641772d776c2d), C64e(0xdcdc11cdb2cda3b2),
  C64e(0xb4b49d29ee2973ee), C64e(0x5b5b4d16fb16b6fb),
  C64e(0xa4a4a501f60153f6), C64e(0x7676a1d74dd7ec4d),
  C64e(0xb7b714a361a37561), C64e(0x7d7d3449ce49face),
  C64e(0x5252df8d7b8da47b), C64e(0xdddd9f423e42a13e),
  C64e(0x5e5ecd937193bc71), C64e(0x1313b1a297a22697),
  C64e(0xa6a6a204f50457f5), C64e(0xb9b901b868b86968),
  C64e(0x0000000000000000), C64e(0xc1c1b5742c74992c),
  C64e(0x4040e0a060a08060), C64e(0xe3e3c2211f21dd1f),
  C64e(0x79793a43c843f2c8), C64e(0xb6b69a2ced2c77ed),
  C64e(0xd4d40dd9bed9b3be), C64e(0x8d8d47ca46ca0146),
  C64e(0x67671770d970ced9), C64e(0x7272afdd4bdde44b),
  C64e(0x9494ed79de7933de), C64e(0x9898ff67d4672bd4),
  C64e(0xb0b09323e8237be8), C64e(0x85855bde4ade114a),
  C64e(0xbbbb06bd6bbd6d6b), C64e(0xc5c5bb7e2a7e912a),
  C64e(0x4f4f7b34e5349ee5), C64e(0xededd73a163ac116),
  C64e(0x8686d254c55417c5), C64e(0x9a9af862d7622fd7),
  C64e(0x666699ff55ffcc55), C64e(0x1111b6a794a72294),
  C64e(0x8a8ac04acf4a0fcf), C64e(0xe9e9d9301030c910),
  C64e(0x04040e0a060a0806), C64e(0xfefe66988198e781),
  C64e(0xa0a0ab0bf00b5bf0), C64e(0x7878b4cc44ccf044),
  C64e(0x2525f0d5bad54aba), C64e(0x4b4b753ee33e96e3),
  C64e(0xa2a2ac0ef30e5ff3), C64e(0x5d5d4419fe19bafe),
  C64e(0x8080db5bc05b1bc0), C64e(0x050580858a850a8a),
  C64e(0x3f3fd3ecadec7ead), C64e(0x2121fedfbcdf42bc),
  C64e(0x7070a8d848d8e048), C64e(0xf1f1fd0c040cf904),
  C64e(0x6363197adf7ac6df), C64e(0x77772f58c158eec1),
  C64e(0xafaf309f759f4575), C64e(0x4242e7a563a58463),
  C64e(0x2020705030504030), C64e(0xe5e5cb2e1a2ed11a),
  C64e(0xfdfdef120e12e10e), C64e(0xbfbf08b76db7656d),
  C64e(0x818155d44cd4194c), C64e(0x1818243c143c3014),
  C64e(0x2626795f355f4c35), C64e(0xc3c3b2712f719d2f),
  C64e(0xbebe8638e13867e1), C64e(0x3535c8fda2fd6aa2),
  C64e(0x8888c74fcc4f0bcc), C64e(0x2e2e654b394b5c39),
  C64e(0x93936af957f93d57), C64e(0x5555580df20daaf2),
  C64e(0xfcfc619d829de382), C64e(0x7a7ab3c947c9f447),
  C64e(0xc8c827efacef8bac), C64e(0xbaba8832e7326fe7),
  C64e(0x32324f7d2b7d642b), C64e(0xe6e642a495a4d795),
  C64e(0xc0c03bfba0fb9ba0), C64e(0x1919aab398b33298),
  C64e(0x9e9ef668d16827d1), C64e(0xa3a322817f815d7f),
  C64e(0x4444eeaa66aa8866), C64e(0x5454d6827e82a87e),
  C64e(0x3b3bdde6abe676ab), C64e(0x0b0b959e839e1683),
  C64e(0x8c8cc945ca4503ca), C64e(0xc7c7bc7b297b9529),
  C64e(0x6b6b056ed36ed6d3), C64e(0x28286c443c44503c),
  C64e(0xa7a72c8b798b5579), C64e(0xbcbc813de23d63e2),
  C64e(0x161631271d272c1d), C64e(0xadad379a769a4176),
  C64e(0xdbdb964d3b4dad3b), C64e(0x64649efa56fac856),
  C64e(0x7474a6d24ed2e84e), C64e(0x141436221e22281e),
  C64e(0x9292e476db763fdb), C64e(0x0c0c121e0a1e180a),
  C64e(0x4848fcb46cb4906c), C64e(0xb8b88f37e4376be4),
  C64e(0x9f9f78e75de7255d), C64e(0xbdbd0fb26eb2616e),
  C64e(0x4343692aef2a86ef), C64e(0xc4c435f1a6f193a6),
  C64e(0x3939dae3a8e372a8), C64e(0x3131c6f7a4f762a4),
  C64e(0xd3d38a593759bd37), C64e(0xf2f274868b86ff8b),
  C64e(0xd5d583563256b132), C64e(0x8b8b4ec543c50d43),
  C64e(0x6e6e85eb59ebdc59), C64e(0xdada18c2b7c2afb7),
  C64e(0x01018e8f8c8f028c), C64e(0xb1b11dac64ac7964),
  C64e(0x9c9cf16dd26d23d2), C64e(0x4949723be03b92e0),
  C64e(0xd8d81fc7b4c7abb4), C64e(0xacacb915fa1543fa),
  C64e(0xf3f3fa090709fd07), C64e(0xcfcfa06f256f8525),
  C64e(0xcaca20eaafea8faf), C64e(0xf4f47d898e89f38e),
  C64e(0x47476720e9208ee9), C64e(0x1010382818282018),
  C64e(0x6f6f0b64d564ded5), C64e(0xf0f073838883fb88),
  C64e(0x4a4afbb16fb1946f), C64e(0x5c5cca967296b872),
  C64e(0x3838546c246c7024), C64e(0x57575f08f108aef1),
  C64e(0x73732152c752e6c7), C64e(0x979764f351f33551),
  C64e(0xcbcbae6523658d23), C64e(0xa1a125847c84597c),
  C64e(0xe8e857bf9cbfcb9c), C64e(0x3e3e5d6321637c21),
  C64e(0x9696ea7cdd7c37dd), C64e(0x61611e7fdc7fc2dc),
  C64e(0x0d0d9c9186911a86), C64e(0x0f0f9b9485941e85),
  C64e(0xe0e04bab90abdb90), C64e(0x7c7cbac642c6f842),
  C64e(0x71712657c457e2c4), C64e(0xcccc29e5aae583aa),
  C64e(0x9090e373d8733bd8), C64e(0x0606090f050f0c05),
  C64e(0xf7f7f4030103f501), C64e(0x1c1c2a3612363812),
  C64e(0xc2c23cfea3fe9fa3), C64e(0x6a6a8be15fe1d45f),
  C64e(0xaeaebe10f91047f9), C64e(0x6969026bd06bd2d0),
  C64e(0x1717bfa891a82e91), C64e(0x999971e858e82958),
  C64e(0x3a3a536927697427), C64e(0x2727f7d0b9d04eb9),
  C64e(0xd9d991483848a938), C64e(0xebebde351335cd13),
  C64e(0x2b2be5ceb3ce56b3), C64e(0x2222775533554433),
  C64e(0xd2d204d6bbd6bfbb), C64e(0xa9a9399070904970),
  C64e(0x0707878089800e89), C64e(0x3333c1f2a7f266a7),
  C64e(0x2d2decc1b6c15ab6), C64e(0x3c3c5a6622667822),
  C64e(0x1515b8ad92ad2a92), C64e(0xc9c9a96020608920),
  C64e(0x87875cdb49db1549), C64e(0xaaaab01aff1a4fff),
  C64e(0x5050d8887888a078), C64e(0xa5a52b8e7a8e517a),
  C64e(0x0303898a8f8a068f), C64e(0x59594a13f813b2f8),
  C64e(0x0909929b809b1280), C64e(0x1a1a233917393417),
  C64e(0x65651075da75cada), C64e(0xd7d784533153b531),
  C64e(0x8484d551c65113c6), C64e(0xd0d003d3b8d3bbb8),
  C64e(0x8282dc5ec35e1fc3), C64e(0x2929e2cbb0cb52b0),
  C64e(0x5a5ac3997799b477), C64e(0x1e1e2d3311333c11),
  C64e(0x7b7b3d46cb46f6cb), C64e(0xa8a8b71ffc1f4bfc),
  C64e(0x6d6d0c61d661dad6), C64e(0x2c2c624e3a4e583a)
};

__constant const sph_u64 T2_C[] = {
  C64e(0xa5c6c632f4a5f497), C64e(0x84f8f86f978497eb),
  C64e(0x99eeee5eb099b0c7), C64e(0x8df6f67a8c8d8cf7),
  C64e(0x0dffffe8170d17e5), C64e(0xbdd6d60adcbddcb7),
  C64e(0xb1dede16c8b1c8a7), C64e(0x5491916dfc54fc39),
  C64e(0x50606090f050f0c0), C64e(0x0302020705030504),
  C64e(0xa9cece2ee0a9e087), C64e(0x7d5656d1877d87ac),
  C64e(0x19e7e7cc2b192bd5), C64e(0x62b5b513a662a671),
  C64e(0xe64d4d7c31e6319a), C64e(0x9aecec59b59ab5c3),
  C64e(0x458f8f40cf45cf05), C64e(0x9d1f1fa3bc9dbc3e),
  C64e(0x40898949c040c009), C64e(0x87fafa68928792ef),
  C64e(0x15efefd03f153fc5), C64e(0xebb2b29426eb267f),
  C64e(0xc98e8ece40c94007), C64e(0x0bfbfbe61d0b1ded),
  C64e(0xec41416e2fec2f82), C64e(0x67b3b31aa967a97d),
  C64e(0xfd5f5f431cfd1cbe), C64e(0xea45456025ea258a),
  C64e(0xbf2323f9dabfda46), C64e(0xf753535102f702a6),
  C64e(0x96e4e445a196a1d3), C64e(0x5b9b9b76ed5bed2d),
  C64e(0xc27575285dc25dea), C64e(0x1ce1e1c5241c24d9),
  C64e(0xae3d3dd4e9aee97a), C64e(0x6a4c4cf2be6abe98),
  C64e(0x5a6c6c82ee5aeed8), C64e(0x417e7ebdc341c3fc),
  C64e(0x02f5f5f3060206f1), C64e(0x4f838352d14fd11d),
  C64e(0x5c68688ce45ce4d0), C64e(0xf451515607f407a2),
  C64e(0x34d1d18d5c345cb9), C64e(0x08f9f9e1180818e9),
  C64e(0x93e2e24cae93aedf), C64e(0x73abab3e9573954d),
  C64e(0x53626297f553f5c4), C64e(0x3f2a2a6b413f4154),
  C64e(0x0c08081c140c1410), C64e(0x52959563f652f631),
  C64e(0x654646e9af65af8c), C64e(0x5e9d9d7fe25ee221),
  C64e(0x2830304878287860), C64e(0xa13737cff8a1f86e),
  C64e(0x0f0a0a1b110f1114), C64e(0xb52f2febc4b5c45e),
  C64e(0x090e0e151b091b1c), C64e(0x3624247e5a365a48),
  C64e(0x9b1b1badb69bb636), C64e(0x3ddfdf98473d47a5),
  C64e(0x26cdcda76a266a81), C64e(0x694e4ef5bb69bb9c),
  C64e(0xcd7f7f334ccd4cfe), C64e(0x9feaea50ba9fbacf),
  C64e(0x1b12123f2d1b2d24), C64e(0x9e1d1da4b99eb93a),
  C64e(0x745858c49c749cb0), C64e(0x2e343446722e7268),
  C64e(0x2d363641772d776c), C64e(0xb2dcdc11cdb2cda3),
  C64e(0xeeb4b49d29ee2973), C64e(0xfb5b5b4d16fb16b6),
  C64e(0xf6a4a4a501f60153), C64e(0x4d7676a1d74dd7ec),
  C64e(0x61b7b714a361a375), C64e(0xce7d7d3449ce49fa),
  C64e(0x7b5252df8d7b8da4), C64e(0x3edddd9f423e42a1),
  C64e(0x715e5ecd937193bc), C64e(0x971313b1a297a226),
  C64e(0xf5a6a6a204f50457), C64e(0x68b9b901b868b869),
  C64e(0x0000000000000000), C64e(0x2cc1c1b5742c7499),
  C64e(0x604040e0a060a080), C64e(0x1fe3e3c2211f21dd),
  C64e(0xc879793a43c843f2), C64e(0xedb6b69a2ced2c77),
  C64e(0xbed4d40dd9bed9b3), C64e(0x468d8d47ca46ca01),
  C64e(0xd967671770d970ce), C64e(0x4b7272afdd4bdde4),
  C64e(0xde9494ed79de7933), C64e(0xd49898ff67d4672b),
  C64e(0xe8b0b09323e8237b), C64e(0x4a85855bde4ade11),
  C64e(0x6bbbbb06bd6bbd6d), C64e(0x2ac5c5bb7e2a7e91),
  C64e(0xe54f4f7b34e5349e), C64e(0x16ededd73a163ac1),
  C64e(0xc58686d254c55417), C64e(0xd79a9af862d7622f),
  C64e(0x55666699ff55ffcc), C64e(0x941111b6a794a722),
  C64e(0xcf8a8ac04acf4a0f), C64e(0x10e9e9d9301030c9),
  C64e(0x0604040e0a060a08), C64e(0x81fefe66988198e7),
  C64e(0xf0a0a0ab0bf00b5b), C64e(0x447878b4cc44ccf0),
  C64e(0xba2525f0d5bad54a), C64e(0xe34b4b753ee33e96),
  C64e(0xf3a2a2ac0ef30e5f), C64e(0xfe5d5d4419fe19ba),
  C64e(0xc08080db5bc05b1b), C64e(0x8a050580858a850a),
  C64e(0xad3f3fd3ecadec7e), C64e(0xbc2121fedfbcdf42),
  C64e(0x487070a8d848d8e0), C64e(0x04f1f1fd0c040cf9),
  C64e(0xdf6363197adf7ac6), C64e(0xc177772f58c158ee),
  C64e(0x75afaf309f759f45), C64e(0x634242e7a563a584),
  C64e(0x3020207050305040), C64e(0x1ae5e5cb2e1a2ed1),
  C64e(0x0efdfdef120e12e1), C64e(0x6dbfbf08b76db765),
  C64e(0x4c818155d44cd419), C64e(0x141818243c143c30),
  C64e(0x352626795f355f4c), C64e(0x2fc3c3b2712f719d),
  C64e(0xe1bebe8638e13867), C64e(0xa23535c8fda2fd6a),
  C64e(0xcc8888c74fcc4f0b), C64e(0x392e2e654b394b5c),
  C64e(0x5793936af957f93d), C64e(0xf25555580df20daa),
  C64e(0x82fcfc619d829de3), C64e(0x477a7ab3c947c9f4),
  C64e(0xacc8c827efacef8b), C64e(0xe7baba8832e7326f),
  C64e(0x2b32324f7d2b7d64), C64e(0x95e6e642a495a4d7),
  C64e(0xa0c0c03bfba0fb9b), C64e(0x981919aab398b332),
  C64e(0xd19e9ef668d16827), C64e(0x7fa3a322817f815d),
  C64e(0x664444eeaa66aa88), C64e(0x7e5454d6827e82a8),
  C64e(0xab3b3bdde6abe676), C64e(0x830b0b959e839e16),
  C64e(0xca8c8cc945ca4503), C64e(0x29c7c7bc7b297b95),
  C64e(0xd36b6b056ed36ed6), C64e(0x3c28286c443c4450),
  C64e(0x79a7a72c8b798b55), C64e(0xe2bcbc813de23d63),
  C64e(0x1d161631271d272c), C64e(0x76adad379a769a41),
  C64e(0x3bdbdb964d3b4dad), C64e(0x5664649efa56fac8),
  C64e(0x4e7474a6d24ed2e8), C64e(0x1e141436221e2228),
  C64e(0xdb9292e476db763f), C64e(0x0a0c0c121e0a1e18),
  C64e(0x6c4848fcb46cb490), C64e(0xe4b8b88f37e4376b),
  C64e(0x5d9f9f78e75de725), C64e(0x6ebdbd0fb26eb261),
  C64e(0xef4343692aef2a86), C64e(0xa6c4c435f1a6f193),
  C64e(0xa83939dae3a8e372), C64e(0xa43131c6f7a4f762),
  C64e(0x37d3d38a593759bd), C64e(0x8bf2f274868b86ff),
  C64e(0x32d5d583563256b1), C64e(0x438b8b4ec543c50d),
  C64e(0x596e6e85eb59ebdc), C64e(0xb7dada18c2b7c2af),
  C64e(0x8c01018e8f8c8f02), C64e(0x64b1b11dac64ac79),
  C64e(0xd29c9cf16dd26d23), C64e(0xe04949723be03b92),
  C64e(0xb4d8d81fc7b4c7ab), C64e(0xfaacacb915fa1543),
  C64e(0x07f3f3fa090709fd), C64e(0x25cfcfa06f256f85),
  C64e(0xafcaca20eaafea8f), C64e(0x8ef4f47d898e89f3),
  C64e(0xe947476720e9208e), C64e(0x1810103828182820),
  C64e(0xd56f6f0b64d564de), C64e(0x88f0f073838883fb),
  C64e(0x6f4a4afbb16fb194), C64e(0x725c5cca967296b8),
  C64e(0x243838546c246c70), C64e(0xf157575f08f108ae),
  C64e(0xc773732152c752e6), C64e(0x51979764f351f335),
  C64e(0x23cbcbae6523658d), C64e(0x7ca1a125847c8459),
  C64e(0x9ce8e857bf9cbfcb), C64e(0x213e3e5d6321637c),
  C64e(0xdd9696ea7cdd7c37), C64e(0xdc61611e7fdc7fc2),
  C64e(0x860d0d9c9186911a), C64e(0x850f0f9b9485941e),
  C64e(0x90e0e04bab90abdb), C64e(0x427c7cbac642c6f8),
  C64e(0xc471712657c457e2), C64e(0xaacccc29e5aae583),
  C64e(0xd89090e373d8733b), C64e(0x050606090f050f0c),
  C64e(0x01f7f7f4030103f5), C64e(0x121c1c2a36123638),
  C64e(0xa3c2c23cfea3fe9f), C64e(0x5f6a6a8be15fe1d4),
  C64e(0xf9aeaebe10f91047), C64e(0xd06969026bd06bd2),
  C64e(0x911717bfa891a82e), C64e(0x58999971e858e829),
  C64e(0x273a3a5369276974), C64e(0xb92727f7d0b9d04e),
  C64e(0x38d9d991483848a9), C64e(0x13ebebde351335cd),
  C64e(0xb32b2be5ceb3ce56), C64e(0x3322227755335544),
  C64e(0xbbd2d204d6bbd6bf), C64e(0x70a9a93990709049),
  C64e(0x890707878089800e), C64e(0xa73333c1f2a7f266),
  C64e(0xb62d2decc1b6c15a), C64e(0x223c3c5a66226678),
  C64e(0x921515b8ad92ad2a), C64e(0x20c9c9a960206089),
  C64e(0x4987875cdb49db15), C64e(0xffaaaab01aff1a4f),
  C64e(0x785050d8887888a0), C64e(0x7aa5a52b8e7a8e51),
  C64e(0x8f0303898a8f8a06), C64e(0xf859594a13f813b2),
  C64e(0x800909929b809b12), C64e(0x171a1a2339173934),
  C64e(0xda65651075da75ca), C64e(0x31d7d784533153b5),
  C64e(0xc68484d551c65113), C64e(0xb8d0d003d3b8d3bb),
  C64e(0xc38282dc5ec35e1f), C64e(0xb02929e2cbb0cb52),
  C64e(0x775a5ac3997799b4), C64e(0x111e1e2d3311333c),
  C64e(0xcb7b7b3d46cb46f6), C64e(0xfca8a8b71ffc1f4b),
  C64e(0xd66d6d0c61d661da), C64e(0x3a2c2c624e3a4e58)
};

__constant const sph_u64 T3_C[] = {
  C64e(0x97a5c6c632f4a5f4), C64e(0xeb84f8f86f978497),
  C64e(0xc799eeee5eb099b0), C64e(0xf78df6f67a8c8d8c),
  C64e(0xe50dffffe8170d17), C64e(0xb7bdd6d60adcbddc),
  C64e(0xa7b1dede16c8b1c8), C64e(0x395491916dfc54fc),
  C64e(0xc050606090f050f0), C64e(0x0403020207050305),
  C64e(0x87a9cece2ee0a9e0), C64e(0xac7d5656d1877d87),
  C64e(0xd519e7e7cc2b192b), C64e(0x7162b5b513a662a6),
  C64e(0x9ae64d4d7c31e631), C64e(0xc39aecec59b59ab5),
  C64e(0x05458f8f40cf45cf), C64e(0x3e9d1f1fa3bc9dbc),
  C64e(0x0940898949c040c0), C64e(0xef87fafa68928792),
  C64e(0xc515efefd03f153f), C64e(0x7febb2b29426eb26),
  C64e(0x07c98e8ece40c940), C64e(0xed0bfbfbe61d0b1d),
  C64e(0x82ec41416e2fec2f), C64e(0x7d67b3b31aa967a9),
  C64e(0xbefd5f5f431cfd1c), C64e(0x8aea45456025ea25),
  C64e(0x46bf2323f9dabfda), C64e(0xa6f753535102f702),
  C64e(0xd396e4e445a196a1), C64e(0x2d5b9b9b76ed5bed),
  C64e(0xeac27575285dc25d), C64e(0xd91ce1e1c5241c24),
  C64e(0x7aae3d3dd4e9aee9), C64e(0x986a4c4cf2be6abe),
  C64e(0xd85a6c6c82ee5aee), C64e(0xfc417e7ebdc341c3),
  C64e(0xf102f5f5f3060206), C64e(0x1d4f838352d14fd1),
  C64e(0xd05c68688ce45ce4), C64e(0xa2f451515607f407),
  C64e(0xb934d1d18d5c345c), C64e(0xe908f9f9e1180818),
  C64e(0xdf93e2e24cae93ae), C64e(0x4d73abab3e957395),
  C64e(0xc453626297f553f5), C64e(0x543f2a2a6b413f41),
  C64e(0x100c08081c140c14), C64e(0x3152959563f652f6),
  C64e(0x8c654646e9af65af), C64e(0x215e9d9d7fe25ee2),
  C64e(0x6028303048782878), C64e(0x6ea13737cff8a1f8),
  C64e(0x140f0a0a1b110f11), C64e(0x5eb52f2febc4b5c4),
  C64e(0x1c090e0e151b091b), C64e(0x483624247e5a365a),
  C64e(0x369b1b1badb69bb6), C64e(0xa53ddfdf98473d47),
  C64e(0x8126cdcda76a266a), C64e(0x9c694e4ef5bb69bb),
  C64e(0xfecd7f7f334ccd4c), C64e(0xcf9feaea50ba9fba),
  C64e(0x241b12123f2d1b2d), C64e(0x3a9e1d1da4b99eb9),
  C64e(0xb0745858c49c749c), C64e(0x682e343446722e72),
  C64e(0x6c2d363641772d77), C64e(0xa3b2dcdc11cdb2cd),
  C64e(0x73eeb4b49d29ee29), C64e(0xb6fb5b5b4d16fb16),
  C64e(0x53f6a4a4a501f601), C64e(0xec4d7676a1d74dd7),
  C64e(0x7561b7b714a361a3), C64e(0xface7d7d3449ce49),
  C64e(0xa47b5252df8d7b8d), C64e(0xa13edddd9f423e42),
  C64e(0xbc715e5ecd937193), C64e(0x26971313b1a297a2),
  C64e(0x57f5a6a6a204f504), C64e(0x6968b9b901b868b8),
  C64e(0x0000000000000000), C64e(0x992cc1c1b5742c74),
  C64e(0x80604040e0a060a0), C64e(0xdd1fe3e3c2211f21),
  C64e(0xf2c879793a43c843), C64e(0x77edb6b69a2ced2c),
  C64e(0xb3bed4d40dd9bed9), C64e(0x01468d8d47ca46ca),
  C64e(0xced967671770d970), C64e(0xe44b7272afdd4bdd),
  C64e(0x33de9494ed79de79), C64e(0x2bd49898ff67d467),
  C64e(0x7be8b0b09323e823), C64e(0x114a85855bde4ade),
  C64e(0x6d6bbbbb06bd6bbd), C64e(0x912ac5c5bb7e2a7e),
  C64e(0x9ee54f4f7b34e534), C64e(0xc116ededd73a163a),
  C64e(0x17c58686d254c554), C64e(0x2fd79a9af862d762),
  C64e(0xcc55666699ff55ff), C64e(0x22941111b6a794a7),
  C64e(0x0fcf8a8ac04acf4a), C64e(0xc910e9e9d9301030),
  C64e(0x080604040e0a060a), C64e(0xe781fefe66988198),
  C64e(0x5bf0a0a0ab0bf00b), C64e(0xf0447878b4cc44cc),
  C64e(0x4aba2525f0d5bad5), C64e(0x96e34b4b753ee33e),
  C64e(0x5ff3a2a2ac0ef30e), C64e(0xbafe5d5d4419fe19),
  C64e(0x1bc08080db5bc05b), C64e(0x0a8a050580858a85),
  C64e(0x7ead3f3fd3ecadec), C64e(0x42bc2121fedfbcdf),
  C64e(0xe0487070a8d848d8), C64e(0xf904f1f1fd0c040c),
  C64e(0xc6df6363197adf7a), C64e(0xeec177772f58c158),
  C64e(0x4575afaf309f759f), C64e(0x84634242e7a563a5),
  C64e(0x4030202070503050), C64e(0xd11ae5e5cb2e1a2e),
  C64e(0xe10efdfdef120e12), C64e(0x656dbfbf08b76db7),
  C64e(0x194c818155d44cd4), C64e(0x30141818243c143c),
  C64e(0x4c352626795f355f), C64e(0x9d2fc3c3b2712f71),
  C64e(0x67e1bebe8638e138), C64e(0x6aa23535c8fda2fd),
  C64e(0x0bcc8888c74fcc4f), C64e(0x5c392e2e654b394b),
  C64e(0x3d5793936af957f9), C64e(0xaaf25555580df20d),
  C64e(0xe382fcfc619d829d), C64e(0xf4477a7ab3c947c9),
  C64e(0x8bacc8c827efacef), C64e(0x6fe7baba8832e732),
  C64e(0x642b32324f7d2b7d), C64e(0xd795e6e642a495a4),
  C64e(0x9ba0c0c03bfba0fb), C64e(0x32981919aab398b3),
  C64e(0x27d19e9ef668d168), C64e(0x5d7fa3a322817f81),
  C64e(0x88664444eeaa66aa), C64e(0xa87e5454d6827e82),
  C64e(0x76ab3b3bdde6abe6), C64e(0x16830b0b959e839e),
  C64e(0x03ca8c8cc945ca45), C64e(0x9529c7c7bc7b297b),
  C64e(0xd6d36b6b056ed36e), C64e(0x503c28286c443c44),
  C64e(0x5579a7a72c8b798b), C64e(0x63e2bcbc813de23d),
  C64e(0x2c1d161631271d27), C64e(0x4176adad379a769a),
  C64e(0xad3bdbdb964d3b4d), C64e(0xc85664649efa56fa),
  C64e(0xe84e7474a6d24ed2), C64e(0x281e141436221e22),
  C64e(0x3fdb9292e476db76), C64e(0x180a0c0c121e0a1e),
  C64e(0x906c4848fcb46cb4), C64e(0x6be4b8b88f37e437),
  C64e(0x255d9f9f78e75de7), C64e(0x616ebdbd0fb26eb2),
  C64e(0x86ef4343692aef2a), C64e(0x93a6c4c435f1a6f1),
  C64e(0x72a83939dae3a8e3), C64e(0x62a43131c6f7a4f7),
  C64e(0xbd37d3d38a593759), C64e(0xff8bf2f274868b86),
  C64e(0xb132d5d583563256), C64e(0x0d438b8b4ec543c5),
  C64e(0xdc596e6e85eb59eb), C64e(0xafb7dada18c2b7c2),
  C64e(0x028c01018e8f8c8f), C64e(0x7964b1b11dac64ac),
  C64e(0x23d29c9cf16dd26d), C64e(0x92e04949723be03b),
  C64e(0xabb4d8d81fc7b4c7), C64e(0x43faacacb915fa15),
  C64e(0xfd07f3f3fa090709), C64e(0x8525cfcfa06f256f),
  C64e(0x8fafcaca20eaafea), C64e(0xf38ef4f47d898e89),
  C64e(0x8ee947476720e920), C64e(0x2018101038281828),
  C64e(0xded56f6f0b64d564), C64e(0xfb88f0f073838883),
  C64e(0x946f4a4afbb16fb1), C64e(0xb8725c5cca967296),
  C64e(0x70243838546c246c), C64e(0xaef157575f08f108),
  C64e(0xe6c773732152c752), C64e(0x3551979764f351f3),
  C64e(0x8d23cbcbae652365), C64e(0x597ca1a125847c84),
  C64e(0xcb9ce8e857bf9cbf), C64e(0x7c213e3e5d632163),
  C64e(0x37dd9696ea7cdd7c), C64e(0xc2dc61611e7fdc7f),
  C64e(0x1a860d0d9c918691), C64e(0x1e850f0f9b948594),
  C64e(0xdb90e0e04bab90ab), C64e(0xf8427c7cbac642c6),
  C64e(0xe2c471712657c457), C64e(0x83aacccc29e5aae5),
  C64e(0x3bd89090e373d873), C64e(0x0c050606090f050f),
  C64e(0xf501f7f7f4030103), C64e(0x38121c1c2a361236),
  C64e(0x9fa3c2c23cfea3fe), C64e(0xd45f6a6a8be15fe1),
  C64e(0x47f9aeaebe10f910), C64e(0xd2d06969026bd06b),
  C64e(0x2e911717bfa891a8), C64e(0x2958999971e858e8),
  C64e(0x74273a3a53692769), C64e(0x4eb92727f7d0b9d0),
  C64e(0xa938d9d991483848), C64e(0xcd13ebebde351335),
  C64e(0x56b32b2be5ceb3ce), C64e(0x4433222277553355),
  C64e(0xbfbbd2d204d6bbd6), C64e(0x4970a9a939907090),
  C64e(0x0e89070787808980), C64e(0x66a73333c1f2a7f2),
  C64e(0x5ab62d2decc1b6c1), C64e(0x78223c3c5a662266),
  C64e(0x2a921515b8ad92ad), C64e(0x8920c9c9a9602060),
  C64e(0x154987875cdb49db), C64e(0x4fffaaaab01aff1a),
  C64e(0xa0785050d8887888), C64e(0x517aa5a52b8e7a8e),
  C64e(0x068f0303898a8f8a), C64e(0xb2f859594a13f813),
  C64e(0x12800909929b809b), C64e(0x34171a1a23391739),
  C64e(0xcada65651075da75), C64e(0xb531d7d784533153),
  C64e(0x13c68484d551c651), C64e(0xbbb8d0d003d3b8d3),
  C64e(0x1fc38282dc5ec35e), C64e(0x52b02929e2cbb0cb),
  C64e(0xb4775a5ac3997799), C64e(0x3c111e1e2d331133),
  C64e(0xf6cb7b7b3d46cb46), C64e(0x4bfca8a8b71ffc1f),
  C64e(0xdad66d6d0c61d661), C64e(0x583a2c2c624e3a4e)
};

#endif

__constant const sph_u64 T4_C[] = {
  C64e(0xf497a5c6c632f4a5), C64e(0x97eb84f8f86f9784),
  C64e(0xb0c799eeee5eb099), C64e(0x8cf78df6f67a8c8d),
  C64e(0x17e50dffffe8170d), C64e(0xdcb7bdd6d60adcbd),
  C64e(0xc8a7b1dede16c8b1), C64e(0xfc395491916dfc54),
  C64e(0xf0c050606090f050), C64e(0x0504030202070503),
  C64e(0xe087a9cece2ee0a9), C64e(0x87ac7d5656d1877d),
  C64e(0x2bd519e7e7cc2b19), C64e(0xa67162b5b513a662),
  C64e(0x319ae64d4d7c31e6), C64e(0xb5c39aecec59b59a),
  C64e(0xcf05458f8f40cf45), C64e(0xbc3e9d1f1fa3bc9d),
  C64e(0xc00940898949c040), C64e(0x92ef87fafa689287),
  C64e(0x3fc515efefd03f15), C64e(0x267febb2b29426eb),
  C64e(0x4007c98e8ece40c9), C64e(0x1ded0bfbfbe61d0b),
  C64e(0x2f82ec41416e2fec), C64e(0xa97d67b3b31aa967),
  C64e(0x1cbefd5f5f431cfd), C64e(0x258aea45456025ea),
  C64e(0xda46bf2323f9dabf), C64e(0x02a6f753535102f7),
  C64e(0xa1d396e4e445a196), C64e(0xed2d5b9b9b76ed5b),
  C64e(0x5deac27575285dc2), C64e(0x24d91ce1e1c5241c),
  C64e(0xe97aae3d3dd4e9ae), C64e(0xbe986a4c4cf2be6a),
  C64e(0xeed85a6c6c82ee5a), C64e(0xc3fc417e7ebdc341),
  C64e(0x06f102f5f5f30602), C64e(0xd11d4f838352d14f),
  C64e(0xe4d05c68688ce45c), C64e(0x07a2f451515607f4),
  C64e(0x5cb934d1d18d5c34), C64e(0x18e908f9f9e11808),
  C64e(0xaedf93e2e24cae93), C64e(0x954d73abab3e9573),
  C64e(0xf5c453626297f553), C64e(0x41543f2a2a6b413f),
  C64e(0x14100c08081c140c), C64e(0xf63152959563f652),
  C64e(0xaf8c654646e9af65), C64e(0xe2215e9d9d7fe25e),
  C64e(0x7860283030487828), C64e(0xf86ea13737cff8a1),
  C64e(0x11140f0a0a1b110f), C64e(0xc45eb52f2febc4b5),
  C64e(0x1b1c090e0e151b09), C64e(0x5a483624247e5a36),
  C64e(0xb6369b1b1badb69b), C64e(0x47a53ddfdf98473d),
  C64e(0x6a8126cdcda76a26), C64e(0xbb9c694e4ef5bb69),
  C64e(0x4cfecd7f7f334ccd), C64e(0xbacf9feaea50ba9f),
  C64e(0x2d241b12123f2d1b), C64e(0xb93a9e1d1da4b99e),
  C64e(0x9cb0745858c49c74), C64e(0x72682e343446722e),
  C64e(0x776c2d363641772d), C64e(0xcda3b2dcdc11cdb2),
  C64e(0x2973eeb4b49d29ee), C64e(0x16b6fb5b5b4d16fb),
  C64e(0x0153f6a4a4a501f6), C64e(0xd7ec4d7676a1d74d),
  C64e(0xa37561b7b714a361), C64e(0x49face7d7d3449ce),
  C64e(0x8da47b5252df8d7b), C64e(0x42a13edddd9f423e),
  C64e(0x93bc715e5ecd9371), C64e(0xa226971313b1a297),
  C64e(0x0457f5a6a6a204f5), C64e(0xb86968b9b901b868),
  C64e(0x0000000000000000), C64e(0x74992cc1c1b5742c),
  C64e(0xa080604040e0a060), C64e(0x21dd1fe3e3c2211f),
  C64e(0x43f2c879793a43c8), C64e(0x2c77edb6b69a2ced),
  C64e(0xd9b3bed4d40dd9be), C64e(0xca01468d8d47ca46),
  C64e(0x70ced967671770d9), C64e(0xdde44b7272afdd4b),
  C64e(0x7933de9494ed79de), C64e(0x672bd49898ff67d4),
  C64e(0x237be8b0b09323e8), C64e(0xde114a85855bde4a),
  C64e(0xbd6d6bbbbb06bd6b), C64e(0x7e912ac5c5bb7e2a),
  C64e(0x349ee54f4f7b34e5), C64e(0x3ac116ededd73a16),
  C64e(0x5417c58686d254c5), C64e(0x622fd79a9af862d7),
  C64e(0xffcc55666699ff55), C64e(0xa722941111b6a794),
  C64e(0x4a0fcf8a8ac04acf), C64e(0x30c910e9e9d93010),
  C64e(0x0a080604040e0a06), C64e(0x98e781fefe669881),
  C64e(0x0b5bf0a0a0ab0bf0), C64e(0xccf0447878b4cc44),
  C64e(0xd54aba2525f0d5ba), C64e(0x3e96e34b4b753ee3),
  C64e(0x0e5ff3a2a2ac0ef3), C64e(0x19bafe5d5d4419fe),
  C64e(0x5b1bc08080db5bc0), C64e(0x850a8a050580858a),
  C64e(0xec7ead3f3fd3ecad), C64e(0xdf42bc2121fedfbc),
  C64e(0xd8e0487070a8d848), C64e(0x0cf904f1f1fd0c04),
  C64e(0x7ac6df6363197adf), C64e(0x58eec177772f58c1),
  C64e(0x9f4575afaf309f75), C64e(0xa584634242e7a563),
  C64e(0x5040302020705030), C64e(0x2ed11ae5e5cb2e1a),
  C64e(0x12e10efdfdef120e), C64e(0xb7656dbfbf08b76d),
  C64e(0xd4194c818155d44c), C64e(0x3c30141818243c14),
  C64e(0x5f4c352626795f35), C64e(0x719d2fc3c3b2712f),
  C64e(0x3867e1bebe8638e1), C64e(0xfd6aa23535c8fda2),
  C64e(0x4f0bcc8888c74fcc), C64e(0x4b5c392e2e654b39),
  C64e(0xf93d5793936af957), C64e(0x0daaf25555580df2),
  C64e(0x9de382fcfc619d82), C64e(0xc9f4477a7ab3c947),
  C64e(0xef8bacc8c827efac), C64e(0x326fe7baba8832e7),
  C64e(0x7d642b32324f7d2b), C64e(0xa4d795e6e642a495),
  C64e(0xfb9ba0c0c03bfba0), C64e(0xb332981919aab398),
  C64e(0x6827d19e9ef668d1), C64e(0x815d7fa3a322817f),
  C64e(0xaa88664444eeaa66), C64e(0x82a87e5454d6827e),
  C64e(0xe676ab3b3bdde6ab), C64e(0x9e16830b0b959e83),
  C64e(0x4503ca8c8cc945ca), C64e(0x7b9529c7c7bc7b29),
  C64e(0x6ed6d36b6b056ed3), C64e(0x44503c28286c443c),
  C64e(0x8b5579a7a72c8b79), C64e(0x3d63e2bcbc813de2),
  C64e(0x272c1d161631271d), C64e(0x9a4176adad379a76),
  C64e(0x4dad3bdbdb964d3b), C64e(0xfac85664649efa56),
  C64e(0xd2e84e7474a6d24e), C64e(0x22281e141436221e),
  C64e(0x763fdb9292e476db), C64e(0x1e180a0c0c121e0a),
  C64e(0xb4906c4848fcb46c), C64e(0x376be4b8b88f37e4),
  C64e(0xe7255d9f9f78e75d), C64e(0xb2616ebdbd0fb26e),
  C64e(0x2a86ef4343692aef), C64e(0xf193a6c4c435f1a6),
  C64e(0xe372a83939dae3a8), C64e(0xf762a43131c6f7a4),
  C64e(0x59bd37d3d38a5937), C64e(0x86ff8bf2f274868b),
  C64e(0x56b132d5d5835632), C64e(0xc50d438b8b4ec543),
  C64e(0xebdc596e6e85eb59), C64e(0xc2afb7dada18c2b7),
  C64e(0x8f028c01018e8f8c), C64e(0xac7964b1b11dac64),
  C64e(0x6d23d29c9cf16dd2), C64e(0x3b92e04949723be0),
  C64e(0xc7abb4d8d81fc7b4), C64e(0x1543faacacb915fa),
  C64e(0x09fd07f3f3fa0907), C64e(0x6f8525cfcfa06f25),
  C64e(0xea8fafcaca20eaaf), C64e(0x89f38ef4f47d898e),
  C64e(0x208ee947476720e9), C64e(0x2820181010382818),
  C64e(0x64ded56f6f0b64d5), C64e(0x83fb88f0f0738388),
  C64e(0xb1946f4a4afbb16f), C64e(0x96b8725c5cca9672),
  C64e(0x6c70243838546c24), C64e(0x08aef157575f08f1),
  C64e(0x52e6c773732152c7), C64e(0xf33551979764f351),
  C64e(0x658d23cbcbae6523), C64e(0x84597ca1a125847c),
  C64e(0xbfcb9ce8e857bf9c), C64e(0x637c213e3e5d6321),
  C64e(0x7c37dd9696ea7cdd), C64e(0x7fc2dc61611e7fdc),
  C64e(0x911a860d0d9c9186), C64e(0x941e850f0f9b9485),
  C64e(0xabdb90e0e04bab90), C64e(0xc6f8427c7cbac642),
  C64e(0x57e2c471712657c4), C64e(0xe583aacccc29e5aa),
  C64e(0x733bd89090e373d8), C64e(0x0f0c050606090f05),
  C64e(0x03f501f7f7f40301), C64e(0x3638121c1c2a3612),
  C64e(0xfe9fa3c2c23cfea3), C64e(0xe1d45f6a6a8be15f),
  C64e(0x1047f9aeaebe10f9), C64e(0x6bd2d06969026bd0),
  C64e(0xa82e911717bfa891), C64e(0xe82958999971e858),
  C64e(0x6974273a3a536927), C64e(0xd04eb92727f7d0b9),
  C64e(0x48a938d9d9914838), C64e(0x35cd13ebebde3513),
  C64e(0xce56b32b2be5ceb3), C64e(0x5544332222775533),
  C64e(0xd6bfbbd2d204d6bb), C64e(0x904970a9a9399070),
  C64e(0x800e890707878089), C64e(0xf266a73333c1f2a7),
  C64e(0xc15ab62d2decc1b6), C64e(0x6678223c3c5a6622),
  C64e(0xad2a921515b8ad92), C64e(0x608920c9c9a96020),
  C64e(0xdb154987875cdb49), C64e(0x1a4fffaaaab01aff),
  C64e(0x88a0785050d88878), C64e(0x8e517aa5a52b8e7a),
  C64e(0x8a068f0303898a8f), C64e(0x13b2f859594a13f8),
  C64e(0x9b12800909929b80), C64e(0x3934171a1a233917),
  C64e(0x75cada65651075da), C64e(0x53b531d7d7845331),
  C64e(0x5113c68484d551c6), C64e(0xd3bbb8d0d003d3b8),
  C64e(0x5e1fc38282dc5ec3), C64e(0xcb52b02929e2cbb0),
  C64e(0x99b4775a5ac39977), C64e(0x333c111e1e2d3311),
  C64e(0x46f6cb7b7b3d46cb), C64e(0x1f4bfca8a8b71ffc),
  C64e(0x61dad66d6d0c61d6), C64e(0x4e583a2c2c624e3a)
};

#if !SPH_SMALL_FOOTPRINT_GROESTL

__constant const sph_u64 T5_C[] = {
  C64e(0xa5f497a5c6c632f4), C64e(0x8497eb84f8f86f97),
  C64e(0x99b0c799eeee5eb0), C64e(0x8d8cf78df6f67a8c),
  C64e(0x0d17e50dffffe817), C64e(0xbddcb7bdd6d60adc),
  C64e(0xb1c8a7b1dede16c8), C64e(0x54fc395491916dfc),
  C64e(0x50f0c050606090f0), C64e(0x0305040302020705),
  C64e(0xa9e087a9cece2ee0), C64e(0x7d87ac7d5656d187),
  C64e(0x192bd519e7e7cc2b), C64e(0x62a67162b5b513a6),
  C64e(0xe6319ae64d4d7c31), C64e(0x9ab5c39aecec59b5),
  C64e(0x45cf05458f8f40cf), C64e(0x9dbc3e9d1f1fa3bc),
  C64e(0x40c00940898949c0), C64e(0x8792ef87fafa6892),
  C64e(0x153fc515efefd03f), C64e(0xeb267febb2b29426),
  C64e(0xc94007c98e8ece40), C64e(0x0b1ded0bfbfbe61d),
  C64e(0xec2f82ec41416e2f), C64e(0x67a97d67b3b31aa9),
  C64e(0xfd1cbefd5f5f431c), C64e(0xea258aea45456025),
  C64e(0xbfda46bf2323f9da), C64e(0xf702a6f753535102),
  C64e(0x96a1d396e4e445a1), C64e(0x5bed2d5b9b9b76ed),
  C64e(0xc25deac27575285d), C64e(0x1c24d91ce1e1c524),
  C64e(0xaee97aae3d3dd4e9), C64e(0x6abe986a4c4cf2be),
  C64e(0x5aeed85a6c6c82ee), C64e(0x41c3fc417e7ebdc3),
  C64e(0x0206f102f5f5f306), C64e(0x4fd11d4f838352d1),
  C64e(0x5ce4d05c68688ce4), C64e(0xf407a2f451515607),
  C64e(0x345cb934d1d18d5c), C64e(0x0818e908f9f9e118),
  C64e(0x93aedf93e2e24cae), C64e(0x73954d73abab3e95),
  C64e(0x53f5c453626297f5), C64e(0x3f41543f2a2a6b41),
  C64e(0x0c14100c08081c14), C64e(0x52f63152959563f6),
  C64e(0x65af8c654646e9af), C64e(0x5ee2215e9d9d7fe2),
  C64e(0x2878602830304878), C64e(0xa1f86ea13737cff8),
  C64e(0x0f11140f0a0a1b11), C64e(0xb5c45eb52f2febc4),
  C64e(0x091b1c090e0e151b), C64e(0x365a483624247e5a),
  C64e(0x9bb6369b1b1badb6), C64e(0x3d47a53ddfdf9847),
  C64e(0x266a8126cdcda76a), C64e(0x69bb9c694e4ef5bb),
  C64e(0xcd4cfecd7f7f334c), C64e(0x9fbacf9feaea50ba),
  C64e(0x1b2d241b12123f2d), C64e(0x9eb93a9e1d1da4b9),
  C64e(0x749cb0745858c49c), C64e(0x2e72682e34344672),
  C64e(0x2d776c2d36364177), C64e(0xb2cda3b2dcdc11cd),
  C64e(0xee2973eeb4b49d29), C64e(0xfb16b6fb5b5b4d16),
  C64e(0xf60153f6a4a4a501), C64e(0x4dd7ec4d7676a1d7),
  C64e(0x61a37561b7b714a3), C64e(0xce49face7d7d3449),
  C64e(0x7b8da47b5252df8d), C64e(0x3e42a13edddd9f42),
  C64e(0x7193bc715e5ecd93), C64e(0x97a226971313b1a2),
  C64e(0xf50457f5a6a6a204), C64e(0x68b86968b9b901b8),
  C64e(0x0000000000000000), C64e(0x2c74992cc1c1b574),
  C64e(0x60a080604040e0a0), C64e(0x1f21dd1fe3e3c221),
  C64e(0xc843f2c879793a43), C64e(0xed2c77edb6b69a2c),
  C64e(0xbed9b3bed4d40dd9), C64e(0x46ca01468d8d47ca),
  C64e(0xd970ced967671770), C64e(0x4bdde44b7272afdd),
  C64e(0xde7933de9494ed79), C64e(0xd4672bd49898ff67),
  C64e(0xe8237be8b0b09323), C64e(0x4ade114a85855bde),
  C64e(0x6bbd6d6bbbbb06bd), C64e(0x2a7e912ac5c5bb7e),
  C64e(0xe5349ee54f4f7b34), C64e(0x163ac116ededd73a),
  C64e(0xc55417c58686d254), C64e(0xd7622fd79a9af862),
  C64e(0x55ffcc55666699ff), C64e(0x94a722941111b6a7),
  C64e(0xcf4a0fcf8a8ac04a), C64e(0x1030c910e9e9d930),
  C64e(0x060a080604040e0a), C64e(0x8198e781fefe6698),
  C64e(0xf00b5bf0a0a0ab0b), C64e(0x44ccf0447878b4cc),
  C64e(0xbad54aba2525f0d5), C64e(0xe33e96e34b4b753e),
  C64e(0xf30e5ff3a2a2ac0e), C64e(0xfe19bafe5d5d4419),
  C64e(0xc05b1bc08080db5b), C64e(0x8a850a8a05058085),
  C64e(0xadec7ead3f3fd3ec), C64e(0xbcdf42bc2121fedf),
  C64e(0x48d8e0487070a8d8), C64e(0x040cf904f1f1fd0c),
  C64e(0xdf7ac6df6363197a), C64e(0xc158eec177772f58),
  C64e(0x759f4575afaf309f), C64e(0x63a584634242e7a5),
  C64e(0x3050403020207050), C64e(0x1a2ed11ae5e5cb2e),
  C64e(0x0e12e10efdfdef12), C64e(0x6db7656dbfbf08b7),
  C64e(0x4cd4194c818155d4), C64e(0x143c30141818243c),
  C64e(0x355f4c352626795f), C64e(0x2f719d2fc3c3b271),
  C64e(0xe13867e1bebe8638), C64e(0xa2fd6aa23535c8fd),
  C64e(0xcc4f0bcc8888c74f), C64e(0x394b5c392e2e654b),
  C64e(0x57f93d5793936af9), C64e(0xf20daaf25555580d),
  C64e(0x829de382fcfc619d), C64e(0x47c9f4477a7ab3c9),
  C64e(0xacef8bacc8c827ef), C64e(0xe7326fe7baba8832),
  C64e(0x2b7d642b32324f7d), C64e(0x95a4d795e6e642a4),
  C64e(0xa0fb9ba0c0c03bfb), C64e(0x98b332981919aab3),
  C64e(0xd16827d19e9ef668), C64e(0x7f815d7fa3a32281),
  C64e(0x66aa88664444eeaa), C64e(0x7e82a87e5454d682),
  C64e(0xabe676ab3b3bdde6), C64e(0x839e16830b0b959e),
  C64e(0xca4503ca8c8cc945), C64e(0x297b9529c7c7bc7b),
  C64e(0xd36ed6d36b6b056e), C64e(0x3c44503c28286c44),
  C64e(0x798b5579a7a72c8b), C64e(0xe23d63e2bcbc813d),
  C64e(0x1d272c1d16163127), C64e(0x769a4176adad379a),
  C64e(0x3b4dad3bdbdb964d), C64e(0x56fac85664649efa),
  C64e(0x4ed2e84e7474a6d2), C64e(0x1e22281e14143622),
  C64e(0xdb763fdb9292e476), C64e(0x0a1e180a0c0c121e),
  C64e(0x6cb4906c4848fcb4), C64e(0xe4376be4b8b88f37),
  C64e(0x5de7255d9f9f78e7), C64e(0x6eb2616ebdbd0fb2),
  C64e(0xef2a86ef4343692a), C64e(0xa6f193a6c4c435f1),
  C64e(0xa8e372a83939dae3), C64e(0xa4f762a43131c6f7),
  C64e(0x3759bd37d3d38a59), C64e(0x8b86ff8bf2f27486),
  C64e(0x3256b132d5d58356), C64e(0x43c50d438b8b4ec5),
  C64e(0x59ebdc596e6e85eb), C64e(0xb7c2afb7dada18c2),
  C64e(0x8c8f028c01018e8f), C64e(0x64ac7964b1b11dac),
  C64e(0xd26d23d29c9cf16d), C64e(0xe03b92e04949723b),
  C64e(0xb4c7abb4d8d81fc7), C64e(0xfa1543faacacb915),
  C64e(0x0709fd07f3f3fa09), C64e(0x256f8525cfcfa06f),
  C64e(0xafea8fafcaca20ea), C64e(0x8e89f38ef4f47d89),
  C64e(0xe9208ee947476720), C64e(0x1828201810103828),
  C64e(0xd564ded56f6f0b64), C64e(0x8883fb88f0f07383),
  C64e(0x6fb1946f4a4afbb1), C64e(0x7296b8725c5cca96),
  C64e(0x246c70243838546c), C64e(0xf108aef157575f08),
  C64e(0xc752e6c773732152), C64e(0x51f33551979764f3),
  C64e(0x23658d23cbcbae65), C64e(0x7c84597ca1a12584),
  C64e(0x9cbfcb9ce8e857bf), C64e(0x21637c213e3e5d63),
  C64e(0xdd7c37dd9696ea7c), C64e(0xdc7fc2dc61611e7f),
  C64e(0x86911a860d0d9c91), C64e(0x85941e850f0f9b94),
  C64e(0x90abdb90e0e04bab), C64e(0x42c6f8427c7cbac6),
  C64e(0xc457e2c471712657), C64e(0xaae583aacccc29e5),
  C64e(0xd8733bd89090e373), C64e(0x050f0c050606090f),
  C64e(0x0103f501f7f7f403), C64e(0x123638121c1c2a36),
  C64e(0xa3fe9fa3c2c23cfe), C64e(0x5fe1d45f6a6a8be1),
  C64e(0xf91047f9aeaebe10), C64e(0xd06bd2d06969026b),
  C64e(0x91a82e911717bfa8), C64e(0x58e82958999971e8),
  C64e(0x276974273a3a5369), C64e(0xb9d04eb92727f7d0),
  C64e(0x3848a938d9d99148), C64e(0x1335cd13ebebde35),
  C64e(0xb3ce56b32b2be5ce), C64e(0x3355443322227755),
  C64e(0xbbd6bfbbd2d204d6), C64e(0x70904970a9a93990),
  C64e(0x89800e8907078780), C64e(0xa7f266a73333c1f2),
  C64e(0xb6c15ab62d2decc1), C64e(0x226678223c3c5a66),
  C64e(0x92ad2a921515b8ad), C64e(0x20608920c9c9a960),
  C64e(0x49db154987875cdb), C64e(0xff1a4fffaaaab01a),
  C64e(0x7888a0785050d888), C64e(0x7a8e517aa5a52b8e),
  C64e(0x8f8a068f0303898a), C64e(0xf813b2f859594a13),
  C64e(0x809b12800909929b), C64e(0x173934171a1a2339),
  C64e(0xda75cada65651075), C64e(0x3153b531d7d78453),
  C64e(0xc65113c68484d551), C64e(0xb8d3bbb8d0d003d3),
  C64e(0xc35e1fc38282dc5e), C64e(0xb0cb52b02929e2cb),
  C64e(0x7799b4775a5ac399), C64e(0x11333c111e1e2d33),
  C64e(0xcb46f6cb7b7b3d46), C64e(0xfc1f4bfca8a8b71f),
  C64e(0xd661dad66d6d0c61), C64e(0x3a4e583a2c2c624e)
};

__constant const sph_u64 T6_C[] = {
  C64e(0xf4a5f497a5c6c632), C64e(0x978497eb84f8f86f),
  C64e(0xb099b0c799eeee5e), C64e(0x8c8d8cf78df6f67a),
  C64e(0x170d17e50dffffe8), C64e(0xdcbddcb7bdd6d60a),
  C64e(0xc8b1c8a7b1dede16), C64e(0xfc54fc395491916d),
  C64e(0xf050f0c050606090), C64e(0x0503050403020207),
  C64e(0xe0a9e087a9cece2e), C64e(0x877d87ac7d5656d1),
  C64e(0x2b192bd519e7e7cc), C64e(0xa662a67162b5b513),
  C64e(0x31e6319ae64d4d7c), C64e(0xb59ab5c39aecec59),
  C64e(0xcf45cf05458f8f40), C64e(0xbc9dbc3e9d1f1fa3),
  C64e(0xc040c00940898949), C64e(0x928792ef87fafa68),
  C64e(0x3f153fc515efefd0), C64e(0x26eb267febb2b294),
  C64e(0x40c94007c98e8ece), C64e(0x1d0b1ded0bfbfbe6),
  C64e(0x2fec2f82ec41416e), C64e(0xa967a97d67b3b31a),
  C64e(0x1cfd1cbefd5f5f43), C64e(0x25ea258aea454560),
  C64e(0xdabfda46bf2323f9), C64e(0x02f702a6f7535351),
  C64e(0xa196a1d396e4e445), C64e(0xed5bed2d5b9b9b76),
  C64e(0x5dc25deac2757528), C64e(0x241c24d91ce1e1c5),
  C64e(0xe9aee97aae3d3dd4), C64e(0xbe6abe986a4c4cf2),
  C64e(0xee5aeed85a6c6c82), C64e(0xc341c3fc417e7ebd),
  C64e(0x060206f102f5f5f3), C64e(0xd14fd11d4f838352),
  C64e(0xe45ce4d05c68688c), C64e(0x07f407a2f4515156),
  C64e(0x5c345cb934d1d18d), C64e(0x180818e908f9f9e1),
  C64e(0xae93aedf93e2e24c), C64e(0x9573954d73abab3e),
  C64e(0xf553f5c453626297), C64e(0x413f41543f2a2a6b),
  C64e(0x140c14100c08081c), C64e(0xf652f63152959563),
  C64e(0xaf65af8c654646e9), C64e(0xe25ee2215e9d9d7f),
  C64e(0x7828786028303048), C64e(0xf8a1f86ea13737cf),
  C64e(0x110f11140f0a0a1b), C64e(0xc4b5c45eb52f2feb),
  C64e(0x1b091b1c090e0e15), C64e(0x5a365a483624247e),
  C64e(0xb69bb6369b1b1bad), C64e(0x473d47a53ddfdf98),
  C64e(0x6a266a8126cdcda7), C64e(0xbb69bb9c694e4ef5),
  C64e(0x4ccd4cfecd7f7f33), C64e(0xba9fbacf9feaea50),
  C64e(0x2d1b2d241b12123f), C64e(0xb99eb93a9e1d1da4),
  C64e(0x9c749cb0745858c4), C64e(0x722e72682e343446),
  C64e(0x772d776c2d363641), C64e(0xcdb2cda3b2dcdc11),
  C64e(0x29ee2973eeb4b49d), C64e(0x16fb16b6fb5b5b4d),
  C64e(0x01f60153f6a4a4a5), C64e(0xd74dd7ec4d7676a1),
  C64e(0xa361a37561b7b714), C64e(0x49ce49face7d7d34),
  C64e(0x8d7b8da47b5252df), C64e(0x423e42a13edddd9f),
  C64e(0x937193bc715e5ecd), C64e(0xa297a226971313b1),
  C64e(0x04f50457f5a6a6a2), C64e(0xb868b86968b9b901),
  C64e(0x0000000000000000), C64e(0x742c74992cc1c1b5),
  C64e(0xa060a080604040e0), C64e(0x211f21dd1fe3e3c2),
  C64e(0x43c843f2c879793a), C64e(0x2ced2c77edb6b69a),
  C64e(0xd9bed9b3bed4d40d), C64e(0xca46ca01468d8d47),
  C64e(0x70d970ced9676717), C64e(0xdd4bdde44b7272af),
  C64e(0x79de7933de9494ed), C64e(0x67d4672bd49898ff),
  C64e(0x23e8237be8b0b093), C64e(0xde4ade114a85855b),
  C64e(0xbd6bbd6d6bbbbb06), C64e(0x7e2a7e912ac5c5bb),
  C64e(0x34e5349ee54f4f7b), C64e(0x3a163ac116ededd7),
  C64e(0x54c55417c58686d2), C64e(0x62d7622fd79a9af8),
  C64e(0xff55ffcc55666699), C64e(0xa794a722941111b6),
  C64e(0x4acf4a0fcf8a8ac0), C64e(0x301030c910e9e9d9),
  C64e(0x0a060a080604040e), C64e(0x988198e781fefe66),
  C64e(0x0bf00b5bf0a0a0ab), C64e(0xcc44ccf0447878b4),
  C64e(0xd5bad54aba2525f0), C64e(0x3ee33e96e34b4b75),
  C64e(0x0ef30e5ff3a2a2ac), C64e(0x19fe19bafe5d5d44),
  C64e(0x5bc05b1bc08080db), C64e(0x858a850a8a050580),
  C64e(0xecadec7ead3f3fd3), C64e(0xdfbcdf42bc2121fe),
  C64e(0xd848d8e0487070a8), C64e(0x0c040cf904f1f1fd),
  C64e(0x7adf7ac6df636319), C64e(0x58c158eec177772f),
  C64e(0x9f759f4575afaf30), C64e(0xa563a584634242e7),
  C64e(0x5030504030202070), C64e(0x2e1a2ed11ae5e5cb),
  C64e(0x120e12e10efdfdef), C64e(0xb76db7656dbfbf08),
  C64e(0xd44cd4194c818155), C64e(0x3c143c3014181824),
  C64e(0x5f355f4c35262679), C64e(0x712f719d2fc3c3b2),
  C64e(0x38e13867e1bebe86), C64e(0xfda2fd6aa23535c8),
  C64e(0x4fcc4f0bcc8888c7), C64e(0x4b394b5c392e2e65),
  C64e(0xf957f93d5793936a), C64e(0x0df20daaf2555558),
  C64e(0x9d829de382fcfc61), C64e(0xc947c9f4477a7ab3),
  C64e(0xefacef8bacc8c827), C64e(0x32e7326fe7baba88),
  C64e(0x7d2b7d642b32324f), C64e(0xa495a4d795e6e642),
  C64e(0xfba0fb9ba0c0c03b), C64e(0xb398b332981919aa),
  C64e(0x68d16827d19e9ef6), C64e(0x817f815d7fa3a322),
  C64e(0xaa66aa88664444ee), C64e(0x827e82a87e5454d6),
  C64e(0xe6abe676ab3b3bdd), C64e(0x9e839e16830b0b95),
  C64e(0x45ca4503ca8c8cc9), C64e(0x7b297b9529c7c7bc),
  C64e(0x6ed36ed6d36b6b05), C64e(0x443c44503c28286c),
  C64e(0x8b798b5579a7a72c), C64e(0x3de23d63e2bcbc81),
  C64e(0x271d272c1d161631), C64e(0x9a769a4176adad37),
  C64e(0x4d3b4dad3bdbdb96), C64e(0xfa56fac85664649e),
  C64e(0xd24ed2e84e7474a6), C64e(0x221e22281e141436),
  C64e(0x76db763fdb9292e4), C64e(0x1e0a1e180a0c0c12),
  C64e(0xb46cb4906c4848fc), C64e(0x37e4376be4b8b88f),
  C64e(0xe75de7255d9f9f78), C64e(0xb26eb2616ebdbd0f),
  C64e(0x2aef2a86ef434369), C64e(0xf1a6f193a6c4c435),
  C64e(0xe3a8e372a83939da), C64e(0xf7a4f762a43131c6),
  C64e(0x593759bd37d3d38a), C64e(0x868b86ff8bf2f274),
  C64e(0x563256b132d5d583), C64e(0xc543c50d438b8b4e),
  C64e(0xeb59ebdc596e6e85), C64e(0xc2b7c2afb7dada18),
  C64e(0x8f8c8f028c01018e), C64e(0xac64ac7964b1b11d),
  C64e(0x6dd26d23d29c9cf1), C64e(0x3be03b92e0494972),
  C64e(0xc7b4c7abb4d8d81f), C64e(0x15fa1543faacacb9),
  C64e(0x090709fd07f3f3fa), C64e(0x6f256f8525cfcfa0),
  C64e(0xeaafea8fafcaca20), C64e(0x898e89f38ef4f47d),
  C64e(0x20e9208ee9474767), C64e(0x2818282018101038),
  C64e(0x64d564ded56f6f0b), C64e(0x838883fb88f0f073),
  C64e(0xb16fb1946f4a4afb), C64e(0x967296b8725c5cca),
  C64e(0x6c246c7024383854), C64e(0x08f108aef157575f),
  C64e(0x52c752e6c7737321), C64e(0xf351f33551979764),
  C64e(0x6523658d23cbcbae), C64e(0x847c84597ca1a125),
  C64e(0xbf9cbfcb9ce8e857), C64e(0x6321637c213e3e5d),
  C64e(0x7cdd7c37dd9696ea), C64e(0x7fdc7fc2dc61611e),
  C64e(0x9186911a860d0d9c), C64e(0x9485941e850f0f9b),
  C64e(0xab90abdb90e0e04b), C64e(0xc642c6f8427c7cba),
  C64e(0x57c457e2c4717126), C64e(0xe5aae583aacccc29),
  C64e(0x73d8733bd89090e3), C64e(0x0f050f0c05060609),
  C64e(0x030103f501f7f7f4), C64e(0x36123638121c1c2a),
  C64e(0xfea3fe9fa3c2c23c), C64e(0xe15fe1d45f6a6a8b),
  C64e(0x10f91047f9aeaebe), C64e(0x6bd06bd2d0696902),
  C64e(0xa891a82e911717bf), C64e(0xe858e82958999971),
  C64e(0x69276974273a3a53), C64e(0xd0b9d04eb92727f7),
  C64e(0x483848a938d9d991), C64e(0x351335cd13ebebde),
  C64e(0xceb3ce56b32b2be5), C64e(0x5533554433222277),
  C64e(0xd6bbd6bfbbd2d204), C64e(0x9070904970a9a939),
  C64e(0x8089800e89070787), C64e(0xf2a7f266a73333c1),
  C64e(0xc1b6c15ab62d2dec), C64e(0x66226678223c3c5a),
  C64e(0xad92ad2a921515b8), C64e(0x6020608920c9c9a9),
  C64e(0xdb49db154987875c), C64e(0x1aff1a4fffaaaab0),
  C64e(0x887888a0785050d8), C64e(0x8e7a8e517aa5a52b),
  C64e(0x8a8f8a068f030389), C64e(0x13f813b2f859594a),
  C64e(0x9b809b1280090992), C64e(0x39173934171a1a23),
  C64e(0x75da75cada656510), C64e(0x533153b531d7d784),
  C64e(0x51c65113c68484d5), C64e(0xd3b8d3bbb8d0d003),
  C64e(0x5ec35e1fc38282dc), C64e(0xcbb0cb52b02929e2),
  C64e(0x997799b4775a5ac3), C64e(0x3311333c111e1e2d),
  C64e(0x46cb46f6cb7b7b3d), C64e(0x1ffc1f4bfca8a8b7),
  C64e(0x61d661dad66d6d0c), C64e(0x4e3a4e583a2c2c62)
};

__constant const sph_u64 T7_C[] = {
  C64e(0x32f4a5f497a5c6c6), C64e(0x6f978497eb84f8f8),
  C64e(0x5eb099b0c799eeee), C64e(0x7a8c8d8cf78df6f6),
  C64e(0xe8170d17e50dffff), C64e(0x0adcbddcb7bdd6d6),
  C64e(0x16c8b1c8a7b1dede), C64e(0x6dfc54fc39549191),
  C64e(0x90f050f0c0506060), C64e(0x0705030504030202),
  C64e(0x2ee0a9e087a9cece), C64e(0xd1877d87ac7d5656),
  C64e(0xcc2b192bd519e7e7), C64e(0x13a662a67162b5b5),
  C64e(0x7c31e6319ae64d4d), C64e(0x59b59ab5c39aecec),
  C64e(0x40cf45cf05458f8f), C64e(0xa3bc9dbc3e9d1f1f),
  C64e(0x49c040c009408989), C64e(0x68928792ef87fafa),
  C64e(0xd03f153fc515efef), C64e(0x9426eb267febb2b2),
  C64e(0xce40c94007c98e8e), C64e(0xe61d0b1ded0bfbfb),
  C64e(0x6e2fec2f82ec4141), C64e(0x1aa967a97d67b3b3),
  C64e(0x431cfd1cbefd5f5f), C64e(0x6025ea258aea4545),
  C64e(0xf9dabfda46bf2323), C64e(0x5102f702a6f75353),
  C64e(0x45a196a1d396e4e4), C64e(0x76ed5bed2d5b9b9b),
  C64e(0x285dc25deac27575), C64e(0xc5241c24d91ce1e1),
  C64e(0xd4e9aee97aae3d3d), C64e(0xf2be6abe986a4c4c),
  C64e(0x82ee5aeed85a6c6c), C64e(0xbdc341c3fc417e7e),
  C64e(0xf3060206f102f5f5), C64e(0x52d14fd11d4f8383),
  C64e(0x8ce45ce4d05c6868), C64e(0x5607f407a2f45151),
  C64e(0x8d5c345cb934d1d1), C64e(0xe1180818e908f9f9),
  C64e(0x4cae93aedf93e2e2), C64e(0x3e9573954d73abab),
  C64e(0x97f553f5c4536262), C64e(0x6b413f41543f2a2a),
  C64e(0x1c140c14100c0808), C64e(0x63f652f631529595),
  C64e(0xe9af65af8c654646), C64e(0x7fe25ee2215e9d9d),
  C64e(0x4878287860283030), C64e(0xcff8a1f86ea13737),
  C64e(0x1b110f11140f0a0a), C64e(0xebc4b5c45eb52f2f),
  C64e(0x151b091b1c090e0e), C64e(0x7e5a365a48362424),
  C64e(0xadb69bb6369b1b1b), C64e(0x98473d47a53ddfdf),
  C64e(0xa76a266a8126cdcd), C64e(0xf5bb69bb9c694e4e),
  C64e(0x334ccd4cfecd7f7f), C64e(0x50ba9fbacf9feaea),
  C64e(0x3f2d1b2d241b1212), C64e(0xa4b99eb93a9e1d1d),
  C64e(0xc49c749cb0745858), C64e(0x46722e72682e3434),
  C64e(0x41772d776c2d3636), C64e(0x11cdb2cda3b2dcdc),
  C64e(0x9d29ee2973eeb4b4), C64e(0x4d16fb16b6fb5b5b),
  C64e(0xa501f60153f6a4a4), C64e(0xa1d74dd7ec4d7676),
  C64e(0x14a361a37561b7b7), C64e(0x3449ce49face7d7d),
  C64e(0xdf8d7b8da47b5252), C64e(0x9f423e42a13edddd),
  C64e(0xcd937193bc715e5e), C64e(0xb1a297a226971313),
  C64e(0xa204f50457f5a6a6), C64e(0x01b868b86968b9b9),
  C64e(0x0000000000000000), C64e(0xb5742c74992cc1c1),
  C64e(0xe0a060a080604040), C64e(0xc2211f21dd1fe3e3),
  C64e(0x3a43c843f2c87979), C64e(0x9a2ced2c77edb6b6),
  C64e(0x0dd9bed9b3bed4d4), C64e(0x47ca46ca01468d8d),
  C64e(0x1770d970ced96767), C64e(0xafdd4bdde44b7272),
  C64e(0xed79de7933de9494), C64e(0xff67d4672bd49898),
  C64e(0x9323e8237be8b0b0), C64e(0x5bde4ade114a8585),
  C64e(0x06bd6bbd6d6bbbbb), C64e(0xbb7e2a7e912ac5c5),
  C64e(0x7b34e5349ee54f4f), C64e(0xd73a163ac116eded),
  C64e(0xd254c55417c58686), C64e(0xf862d7622fd79a9a),
  C64e(0x99ff55ffcc556666), C64e(0xb6a794a722941111),
  C64e(0xc04acf4a0fcf8a8a), C64e(0xd9301030c910e9e9),
  C64e(0x0e0a060a08060404), C64e(0x66988198e781fefe),
  C64e(0xab0bf00b5bf0a0a0), C64e(0xb4cc44ccf0447878),
  C64e(0xf0d5bad54aba2525), C64e(0x753ee33e96e34b4b),
  C64e(0xac0ef30e5ff3a2a2), C64e(0x4419fe19bafe5d5d),
  C64e(0xdb5bc05b1bc08080), C64e(0x80858a850a8a0505),
  C64e(0xd3ecadec7ead3f3f), C64e(0xfedfbcdf42bc2121),
  C64e(0xa8d848d8e0487070), C64e(0xfd0c040cf904f1f1),
  C64e(0x197adf7ac6df6363), C64e(0x2f58c158eec17777),
  C64e(0x309f759f4575afaf), C64e(0xe7a563a584634242),
  C64e(0x7050305040302020), C64e(0xcb2e1a2ed11ae5e5),
  C64e(0xef120e12e10efdfd), C64e(0x08b76db7656dbfbf),
  C64e(0x55d44cd4194c8181), C64e(0x243c143c30141818),
  C64e(0x795f355f4c352626), C64e(0xb2712f719d2fc3c3),
  C64e(0x8638e13867e1bebe), C64e(0xc8fda2fd6aa23535),
  C64e(0xc74fcc4f0bcc8888), C64e(0x654b394b5c392e2e),
  C64e(0x6af957f93d579393), C64e(0x580df20daaf25555),
  C64e(0x619d829de382fcfc), C64e(0xb3c947c9f4477a7a),
  C64e(0x27efacef8bacc8c8), C64e(0x8832e7326fe7baba),
  C64e(0x4f7d2b7d642b3232), C64e(0x42a495a4d795e6e6),
  C64e(0x3bfba0fb9ba0c0c0), C64e(0xaab398b332981919),
  C64e(0xf668d16827d19e9e), C64e(0x22817f815d7fa3a3),
  C64e(0xeeaa66aa88664444), C64e(0xd6827e82a87e5454),
  C64e(0xdde6abe676ab3b3b), C64e(0x959e839e16830b0b),
  C64e(0xc945ca4503ca8c8c), C64e(0xbc7b297b9529c7c7),
  C64e(0x056ed36ed6d36b6b), C64e(0x6c443c44503c2828),
  C64e(0x2c8b798b5579a7a7), C64e(0x813de23d63e2bcbc),
  C64e(0x31271d272c1d1616), C64e(0x379a769a4176adad),
  C64e(0x964d3b4dad3bdbdb), C64e(0x9efa56fac8566464),
  C64e(0xa6d24ed2e84e7474), C64e(0x36221e22281e1414),
  C64e(0xe476db763fdb9292), C64e(0x121e0a1e180a0c0c),
  C64e(0xfcb46cb4906c4848), C64e(0x8f37e4376be4b8b8),
  C64e(0x78e75de7255d9f9f), C64e(0x0fb26eb2616ebdbd),
  C64e(0x692aef2a86ef4343), C64e(0x35f1a6f193a6c4c4),
  C64e(0xdae3a8e372a83939), C64e(0xc6f7a4f762a43131),
  C64e(0x8a593759bd37d3d3), C64e(0x74868b86ff8bf2f2),
  C64e(0x83563256b132d5d5), C64e(0x4ec543c50d438b8b),
  C64e(0x85eb59ebdc596e6e), C64e(0x18c2b7c2afb7dada),
  C64e(0x8e8f8c8f028c0101), C64e(0x1dac64ac7964b1b1),
  C64e(0xf16dd26d23d29c9c), C64e(0x723be03b92e04949),
  C64e(0x1fc7b4c7abb4d8d8), C64e(0xb915fa1543faacac),
  C64e(0xfa090709fd07f3f3), C64e(0xa06f256f8525cfcf),
  C64e(0x20eaafea8fafcaca), C64e(0x7d898e89f38ef4f4),
  C64e(0x6720e9208ee94747), C64e(0x3828182820181010),
  C64e(0x0b64d564ded56f6f), C64e(0x73838883fb88f0f0),
  C64e(0xfbb16fb1946f4a4a), C64e(0xca967296b8725c5c),
  C64e(0x546c246c70243838), C64e(0x5f08f108aef15757),
  C64e(0x2152c752e6c77373), C64e(0x64f351f335519797),
  C64e(0xae6523658d23cbcb), C64e(0x25847c84597ca1a1),
  C64e(0x57bf9cbfcb9ce8e8), C64e(0x5d6321637c213e3e),
  C64e(0xea7cdd7c37dd9696), C64e(0x1e7fdc7fc2dc6161),
  C64e(0x9c9186911a860d0d), C64e(0x9b9485941e850f0f),
  C64e(0x4bab90abdb90e0e0), C64e(0xbac642c6f8427c7c),
  C64e(0x2657c457e2c47171), C64e(0x29e5aae583aacccc),
  C64e(0xe373d8733bd89090), C64e(0x090f050f0c050606),
  C64e(0xf4030103f501f7f7), C64e(0x2a36123638121c1c),
  C64e(0x3cfea3fe9fa3c2c2), C64e(0x8be15fe1d45f6a6a),
  C64e(0xbe10f91047f9aeae), C64e(0x026bd06bd2d06969),
  C64e(0xbfa891a82e911717), C64e(0x71e858e829589999),
  C64e(0x5369276974273a3a), C64e(0xf7d0b9d04eb92727),
  C64e(0x91483848a938d9d9), C64e(0xde351335cd13ebeb),
  C64e(0xe5ceb3ce56b32b2b), C64e(0x7755335544332222),
  C64e(0x04d6bbd6bfbbd2d2), C64e(0x399070904970a9a9),
  C64e(0x878089800e890707), C64e(0xc1f2a7f266a73333),
  C64e(0xecc1b6c15ab62d2d), C64e(0x5a66226678223c3c),
  C64e(0xb8ad92ad2a921515), C64e(0xa96020608920c9c9),
  C64e(0x5cdb49db15498787), C64e(0xb01aff1a4fffaaaa),
  C64e(0xd8887888a0785050), C64e(0x2b8e7a8e517aa5a5),
  C64e(0x898a8f8a068f0303), C64e(0x4a13f813b2f85959),
  C64e(0x929b809b12800909), C64e(0x2339173934171a1a),
  C64e(0x1075da75cada6565), C64e(0x84533153b531d7d7),
  C64e(0xd551c65113c68484), C64e(0x03d3b8d3bbb8d0d0),
  C64e(0xdc5ec35e1fc38282), C64e(0xe2cbb0cb52b02929),
  C64e(0xc3997799b4775a5a), C64e(0x2d3311333c111e1e),
  C64e(0x3d46cb46f6cb7b7b), C64e(0xb71ffc1f4bfca8a8),
  C64e(0x0c61d661dad66d6d), C64e(0x624e3a4e583a2c2c)
};

#endif

#if SPH_SMALL_FOOTPRINT_GROESTL

#define RBTT(d, a, b0, b1, b2, b3, b4, b5, b6, b7)   do { \
    t[d] = T0[B64_0(a[b0])] \
      ^ R64(T0[B64_1(a[b1])],  8) \
      ^ R64(T0[B64_2(a[b2])], 16) \
      ^ R64(T0[B64_3(a[b3])], 24) \
      ^ T4[B64_4(a[b4])] \
      ^ R64(T4[B64_5(a[b5])],  8) \
      ^ R64(T4[B64_6(a[b6])], 16) \
      ^ R64(T4[B64_7(a[b7])], 24); \
  } while (0)

#else

#define RBTT(d, a, b0, b1, b2, b3, b4, b5, b6, b7)   do { \
    t[d] = T0[B64_0(a[b0])] \
      ^ T1[B64_1(a[b1])] \
      ^ T2[B64_2(a[b2])] \
      ^ T3[B64_3(a[b3])] \
      ^ T4[B64_4(a[b4])] \
      ^ T5[B64_5(a[b5])] \
      ^ T6[B64_6(a[b6])] \
      ^ T7[B64_7(a[b7])]; \
  } while (0)

#endif

#if SPH_SMALL_FOOTPRINT_GROESTL

#define ROUND_BIG_P(a, r)   do { \
    sph_u64 t[16]; \
    size_t u; \
    a[0x0] ^= PC64(0x00, r); \
    a[0x1] ^= PC64(0x10, r); \
    a[0x2] ^= PC64(0x20, r); \
    a[0x3] ^= PC64(0x30, r); \
    a[0x4] ^= PC64(0x40, r); \
    a[0x5] ^= PC64(0x50, r); \
    a[0x6] ^= PC64(0x60, r); \
    a[0x7] ^= PC64(0x70, r); \
    a[0x8] ^= PC64(0x80, r); \
    a[0x9] ^= PC64(0x90, r); \
    a[0xA] ^= PC64(0xA0, r); \
    a[0xB] ^= PC64(0xB0, r); \
    a[0xC] ^= PC64(0xC0, r); \
    a[0xD] ^= PC64(0xD0, r); \
    a[0xE] ^= PC64(0xE0, r); \
    a[0xF] ^= PC64(0xF0, r); \
    for (u = 0; u < 16; u += 4) { \
      RBTT(u + 0, a, u + 0, (u + 1) & 0xF, \
        (u + 2) & 0xF, (u + 3) & 0xF, (u + 4) & 0xF, \
        (u + 5) & 0xF, (u + 6) & 0xF, (u + 11) & 0xF); \
      RBTT(u + 1, a, u + 1, (u + 2) & 0xF, \
        (u + 3) & 0xF, (u + 4) & 0xF, (u + 5) & 0xF, \
        (u + 6) & 0xF, (u + 7) & 0xF, (u + 12) & 0xF); \
      RBTT(u + 2, a, u + 2, (u + 3) & 0xF, \
        (u + 4) & 0xF, (u + 5) & 0xF, (u + 6) & 0xF, \
        (u + 7) & 0xF, (u + 8) & 0xF, (u + 13) & 0xF); \
      RBTT(u + 3, a, u + 3, (u + 4) & 0xF, \
        (u + 5) & 0xF, (u + 6) & 0xF, (u + 7) & 0xF, \
        (u + 8) & 0xF, (u + 9) & 0xF, (u + 14) & 0xF); \
    } \
    a[0x0] = t[0x0]; \
    a[0x1] = t[0x1]; \
    a[0x2] = t[0x2]; \
    a[0x3] = t[0x3]; \
    a[0x4] = t[0x4]; \
    a[0x5] = t[0x5]; \
    a[0x6] = t[0x6]; \
    a[0x7] = t[0x7]; \
    a[0x8] = t[0x8]; \
    a[0x9] = t[0x9]; \
    a[0xA] = t[0xA]; \
    a[0xB] = t[0xB]; \
    a[0xC] = t[0xC]; \
    a[0xD] = t[0xD]; \
    a[0xE] = t[0xE]; \
    a[0xF] = t[0xF]; \
  } while (0)

#define ROUND_BIG_Q(a, r)   do { \
    sph_u64 t[16]; \
    size_t u; \
    a[0x0] ^= QC64(0x00, r); \
    a[0x1] ^= QC64(0x10, r); \
    a[0x2] ^= QC64(0x20, r); \
    a[0x3] ^= QC64(0x30, r); \
    a[0x4] ^= QC64(0x40, r); \
    a[0x5] ^= QC64(0x50, r); \
    a[0x6] ^= QC64(0x60, r); \
    a[0x7] ^= QC64(0x70, r); \
    a[0x8] ^= QC64(0x80, r); \
    a[0x9] ^= QC64(0x90, r); \
    a[0xA] ^= QC64(0xA0, r); \
    a[0xB] ^= QC64(0xB0, r); \
    a[0xC] ^= QC64(0xC0, r); \
    a[0xD] ^= QC64(0xD0, r); \
    a[0xE] ^= QC64(0xE0, r); \
    a[0xF] ^= QC64(0xF0, r); \
    for (u = 0; u < 16; u += 4) { \
      RBTT(u + 0, a, (u + 1) & 0xF, (u + 3) & 0xF, \
        (u + 5) & 0xF, (u + 11) & 0xF, (u + 0) & 0xF, \
        (u + 2) & 0xF, (u + 4) & 0xF, (u + 6) & 0xF); \
      RBTT(u + 1, a, (u + 2) & 0xF, (u + 4) & 0xF, \
        (u + 6) & 0xF, (u + 12) & 0xF, (u + 1) & 0xF, \
        (u + 3) & 0xF, (u + 5) & 0xF, (u + 7) & 0xF); \
      RBTT(u + 2, a, (u + 3) & 0xF, (u + 5) & 0xF, \
        (u + 7) & 0xF, (u + 13) & 0xF, (u + 2) & 0xF, \
        (u + 4) & 0xF, (u + 6) & 0xF, (u + 8) & 0xF); \
      RBTT(u + 3, a, (u + 4) & 0xF, (u + 6) & 0xF, \
        (u + 8) & 0xF, (u + 14) & 0xF, (u + 3) & 0xF, \
        (u + 5) & 0xF, (u + 7) & 0xF, (u + 9) & 0xF); \
    } \
    a[0x0] = t[0x0]; \
    a[0x1] = t[0x1]; \
    a[0x2] = t[0x2]; \
    a[0x3] = t[0x3]; \
    a[0x4] = t[0x4]; \
    a[0x5] = t[0x5]; \
    a[0x6] = t[0x6]; \
    a[0x7] = t[0x7]; \
    a[0x8] = t[0x8]; \
    a[0x9] = t[0x9]; \
    a[0xA] = t[0xA]; \
    a[0xB] = t[0xB]; \
    a[0xC] = t[0xC]; \
    a[0xD] = t[0xD]; \
    a[0xE] = t[0xE]; \
    a[0xF] = t[0xF]; \
  } while (0)

#else

#define ROUND_BIG_P(a, r)   do { \
    sph_u64 t[16]; \
    a[0x0] ^= PC64(0x00, r); \
    a[0x1] ^= PC64(0x10, r); \
    a[0x2] ^= PC64(0x20, r); \
    a[0x3] ^= PC64(0x30, r); \
    a[0x4] ^= PC64(0x40, r); \
    a[0x5] ^= PC64(0x50, r); \
    a[0x6] ^= PC64(0x60, r); \
    a[0x7] ^= PC64(0x70, r); \
    a[0x8] ^= PC64(0x80, r); \
    a[0x9] ^= PC64(0x90, r); \
    a[0xA] ^= PC64(0xA0, r); \
    a[0xB] ^= PC64(0xB0, r); \
    a[0xC] ^= PC64(0xC0, r); \
    a[0xD] ^= PC64(0xD0, r); \
    a[0xE] ^= PC64(0xE0, r); \
    a[0xF] ^= PC64(0xF0, r); \
    RBTT(0x0, a, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0xB); \
    RBTT(0x1, a, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0xC); \
    RBTT(0x2, a, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0xD); \
    RBTT(0x3, a, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xE); \
    RBTT(0x4, a, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xF); \
    RBTT(0x5, a, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0x0); \
    RBTT(0x6, a, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0x1); \
    RBTT(0x7, a, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0x2); \
    RBTT(0x8, a, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0x3); \
    RBTT(0x9, a, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x4); \
    RBTT(0xA, a, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x0, 0x5); \
    RBTT(0xB, a, 0xB, 0xC, 0xD, 0xE, 0xF, 0x0, 0x1, 0x6); \
    RBTT(0xC, a, 0xC, 0xD, 0xE, 0xF, 0x0, 0x1, 0x2, 0x7); \
    RBTT(0xD, a, 0xD, 0xE, 0xF, 0x0, 0x1, 0x2, 0x3, 0x8); \
    RBTT(0xE, a, 0xE, 0xF, 0x0, 0x1, 0x2, 0x3, 0x4, 0x9); \
    RBTT(0xF, a, 0xF, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0xA); \
    a[0x0] = t[0x0]; \
    a[0x1] = t[0x1]; \
    a[0x2] = t[0x2]; \
    a[0x3] = t[0x3]; \
    a[0x4] = t[0x4]; \
    a[0x5] = t[0x5]; \
    a[0x6] = t[0x6]; \
    a[0x7] = t[0x7]; \
    a[0x8] = t[0x8]; \
    a[0x9] = t[0x9]; \
    a[0xA] = t[0xA]; \
    a[0xB] = t[0xB]; \
    a[0xC] = t[0xC]; \
    a[0xD] = t[0xD]; \
    a[0xE] = t[0xE]; \
    a[0xF] = t[0xF]; \
  } while (0)

#define ROUND_BIG_Q(a, r)   do { \
    sph_u64 t[16]; \
    a[0x0] ^= QC64(0x00, r); \
    a[0x1] ^= QC64(0x10, r); \
    a[0x2] ^= QC64(0x20, r); \
    a[0x3] ^= QC64(0x30, r); \
    a[0x4] ^= QC64(0x40, r); \
    a[0x5] ^= QC64(0x50, r); \
    a[0x6] ^= QC64(0x60, r); \
    a[0x7] ^= QC64(0x70, r); \
    a[0x8] ^= QC64(0x80, r); \
    a[0x9] ^= QC64(0x90, r); \
    a[0xA] ^= QC64(0xA0, r); \
    a[0xB] ^= QC64(0xB0, r); \
    a[0xC] ^= QC64(0xC0, r); \
    a[0xD] ^= QC64(0xD0, r); \
    a[0xE] ^= QC64(0xE0, r); \
    a[0xF] ^= QC64(0xF0, r); \
    RBTT(0x0, a, 0x1, 0x3, 0x5, 0xB, 0x0, 0x2, 0x4, 0x6); \
    RBTT(0x1, a, 0x2, 0x4, 0x6, 0xC, 0x1, 0x3, 0x5, 0x7); \
    RBTT(0x2, a, 0x3, 0x5, 0x7, 0xD, 0x2, 0x4, 0x6, 0x8); \
    RBTT(0x3, a, 0x4, 0x6, 0x8, 0xE, 0x3, 0x5, 0x7, 0x9); \
    RBTT(0x4, a, 0x5, 0x7, 0x9, 0xF, 0x4, 0x6, 0x8, 0xA); \
    RBTT(0x5, a, 0x6, 0x8, 0xA, 0x0, 0x5, 0x7, 0x9, 0xB); \
    RBTT(0x6, a, 0x7, 0x9, 0xB, 0x1, 0x6, 0x8, 0xA, 0xC); \
    RBTT(0x7, a, 0x8, 0xA, 0xC, 0x2, 0x7, 0x9, 0xB, 0xD); \
    RBTT(0x8, a, 0x9, 0xB, 0xD, 0x3, 0x8, 0xA, 0xC, 0xE); \
    RBTT(0x9, a, 0xA, 0xC, 0xE, 0x4, 0x9, 0xB, 0xD, 0xF); \
    RBTT(0xA, a, 0xB, 0xD, 0xF, 0x5, 0xA, 0xC, 0xE, 0x0); \
    RBTT(0xB, a, 0xC, 0xE, 0x0, 0x6, 0xB, 0xD, 0xF, 0x1); \
    RBTT(0xC, a, 0xD, 0xF, 0x1, 0x7, 0xC, 0xE, 0x0, 0x2); \
    RBTT(0xD, a, 0xE, 0x0, 0x2, 0x8, 0xD, 0xF, 0x1, 0x3); \
    RBTT(0xE, a, 0xF, 0x1, 0x3, 0x9, 0xE, 0x0, 0x2, 0x4); \
    RBTT(0xF, a, 0x0, 0x2, 0x4, 0xA, 0xF, 0x1, 0x3, 0x5); \
    a[0x0] = t[0x0]; \
    a[0x1] = t[0x1]; \
    a[0x2] = t[0x2]; \
    a[0x3] = t[0x3]; \
    a[0x4] = t[0x4]; \
    a[0x5] = t[0x5]; \
    a[0x6] = t[0x6]; \
    a[0x7] = t[0x7]; \
    a[0x8] = t[0x8]; \
    a[0x9] = t[0x9]; \
    a[0xA] = t[0xA]; \
    a[0xB] = t[0xB]; \
    a[0xC] = t[0xC]; \
    a[0xD] = t[0xD]; \
    a[0xE] = t[0xE]; \
    a[0xF] = t[0xF]; \
  } while (0)

#endif

#define PERM_BIG_P(a)   do { \
    int r; \
    for (r = 0; r < 14; r += 2) { \
      ROUND_BIG_P(a, r + 0); \
      ROUND_BIG_P(a, r + 1); \
    } \
  } while (0)

#define PERM_BIG_Q(a)   do { \
    int r; \
    for (r = 0; r < 14; r += 2) { \
      ROUND_BIG_Q(a, r + 0); \
      ROUND_BIG_Q(a, r + 1); \
    } \
  } while (0)

/* $Id: jh.c 255 2011-06-07 19:50:20Z tp $ */
/*
 * JH implementation.
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

#if !defined SPH_JH_64 && SPH_64_TRUE
#define SPH_JH_64   1
#endif

/*
 * The internal bitslice representation may use either big-endian or
 * little-endian (true bitslice operations do not care about the bit
 * ordering, and the bit-swapping linear operations in JH happen to
 * be invariant through endianness-swapping). The constants must be
 * defined according to the chosen endianness; we use some
 * byte-swapping macros for that.
 */

#if SPH_LITTLE_ENDIAN

#define C32e(x)     ((SPH_C32(x) >> 24) \
                    | ((SPH_C32(x) >>  8) & SPH_C32(0x0000FF00)) \
                    | ((SPH_C32(x) <<  8) & SPH_C32(0x00FF0000)) \
                    | ((SPH_C32(x) << 24) & SPH_C32(0xFF000000)))
#define dec32e_aligned   sph_dec32le_aligned
#define enc32e           sph_enc32le

#define C64e(x)     ((SPH_C64(x) >> 56) \
                    | ((SPH_C64(x) >> 40) & SPH_C64(0x000000000000FF00)) \
                    | ((SPH_C64(x) >> 24) & SPH_C64(0x0000000000FF0000)) \
                    | ((SPH_C64(x) >>  8) & SPH_C64(0x00000000FF000000)) \
                    | ((SPH_C64(x) <<  8) & SPH_C64(0x000000FF00000000)) \
                    | ((SPH_C64(x) << 24) & SPH_C64(0x0000FF0000000000)) \
                    | ((SPH_C64(x) << 40) & SPH_C64(0x00FF000000000000)) \
                    | ((SPH_C64(x) << 56) & SPH_C64(0xFF00000000000000)))
#define dec64e_aligned   sph_dec64le_aligned
#define enc64e           sph_enc64le

#else

#define C32e(x)     SPH_C32(x)
#define dec32e_aligned   sph_dec32be_aligned
#define enc32e           sph_enc32be
#define C64e(x)     SPH_C64(x)
#define dec64e_aligned   sph_dec64be_aligned
#define enc64e           sph_enc64be

#endif

#define Sb(x0, x1, x2, x3, c)   do { \
    x3 = ~x3; \
    x0 ^= (c) & ~x2; \
    tmp = (c) ^ (x0 & x1); \
    x0 ^= x2 & x3; \
    x3 ^= ~x1 & x2; \
    x1 ^= x0 & x2; \
    x2 ^= x0 & ~x3; \
    x0 ^= x1 | x3; \
    x3 ^= x1 & x2; \
    x1 ^= tmp & x0; \
    x2 ^= tmp; \
  } while (0)

#define Lb(x0, x1, x2, x3, x4, x5, x6, x7)   do { \
    x4 ^= x1; \
    x5 ^= x2; \
    x6 ^= x3 ^ x0; \
    x7 ^= x0; \
    x0 ^= x5; \
    x1 ^= x6; \
    x2 ^= x7 ^ x4; \
    x3 ^= x4; \
  } while (0)

__constant const sph_u64 C[] = {
  C64e(0x72d5dea2df15f867), C64e(0x7b84150ab7231557),
  C64e(0x81abd6904d5a87f6), C64e(0x4e9f4fc5c3d12b40),
  C64e(0xea983ae05c45fa9c), C64e(0x03c5d29966b2999a),
  C64e(0x660296b4f2bb538a), C64e(0xb556141a88dba231),
  C64e(0x03a35a5c9a190edb), C64e(0x403fb20a87c14410),
  C64e(0x1c051980849e951d), C64e(0x6f33ebad5ee7cddc),
  C64e(0x10ba139202bf6b41), C64e(0xdc786515f7bb27d0),
  C64e(0x0a2c813937aa7850), C64e(0x3f1abfd2410091d3),
  C64e(0x422d5a0df6cc7e90), C64e(0xdd629f9c92c097ce),
  C64e(0x185ca70bc72b44ac), C64e(0xd1df65d663c6fc23),
  C64e(0x976e6c039ee0b81a), C64e(0x2105457e446ceca8),
  C64e(0xeef103bb5d8e61fa), C64e(0xfd9697b294838197),
  C64e(0x4a8e8537db03302f), C64e(0x2a678d2dfb9f6a95),
  C64e(0x8afe7381f8b8696c), C64e(0x8ac77246c07f4214),
  C64e(0xc5f4158fbdc75ec4), C64e(0x75446fa78f11bb80),
  C64e(0x52de75b7aee488bc), C64e(0x82b8001e98a6a3f4),
  C64e(0x8ef48f33a9a36315), C64e(0xaa5f5624d5b7f989),
  C64e(0xb6f1ed207c5ae0fd), C64e(0x36cae95a06422c36),
  C64e(0xce2935434efe983d), C64e(0x533af974739a4ba7),
  C64e(0xd0f51f596f4e8186), C64e(0x0e9dad81afd85a9f),
  C64e(0xa7050667ee34626a), C64e(0x8b0b28be6eb91727),
  C64e(0x47740726c680103f), C64e(0xe0a07e6fc67e487b),
  C64e(0x0d550aa54af8a4c0), C64e(0x91e3e79f978ef19e),
  C64e(0x8676728150608dd4), C64e(0x7e9e5a41f3e5b062),
  C64e(0xfc9f1fec4054207a), C64e(0xe3e41a00cef4c984),
  C64e(0x4fd794f59dfa95d8), C64e(0x552e7e1124c354a5),
  C64e(0x5bdf7228bdfe6e28), C64e(0x78f57fe20fa5c4b2),
  C64e(0x05897cefee49d32e), C64e(0x447e9385eb28597f),
  C64e(0x705f6937b324314a), C64e(0x5e8628f11dd6e465),
  C64e(0xc71b770451b920e7), C64e(0x74fe43e823d4878a),
  C64e(0x7d29e8a3927694f2), C64e(0xddcb7a099b30d9c1),
  C64e(0x1d1b30fb5bdc1be0), C64e(0xda24494ff29c82bf),
  C64e(0xa4e7ba31b470bfff), C64e(0x0d324405def8bc48),
  C64e(0x3baefc3253bbd339), C64e(0x459fc3c1e0298ba0),
  C64e(0xe5c905fdf7ae090f), C64e(0x947034124290f134),
  C64e(0xa271b701e344ed95), C64e(0xe93b8e364f2f984a),
  C64e(0x88401d63a06cf615), C64e(0x47c1444b8752afff),
  C64e(0x7ebb4af1e20ac630), C64e(0x4670b6c5cc6e8ce6),
  C64e(0xa4d5a456bd4fca00), C64e(0xda9d844bc83e18ae),
  C64e(0x7357ce453064d1ad), C64e(0xe8a6ce68145c2567),
  C64e(0xa3da8cf2cb0ee116), C64e(0x33e906589a94999a),
  C64e(0x1f60b220c26f847b), C64e(0xd1ceac7fa0d18518),
  C64e(0x32595ba18ddd19d3), C64e(0x509a1cc0aaa5b446),
  C64e(0x9f3d6367e4046bba), C64e(0xf6ca19ab0b56ee7e),
  C64e(0x1fb179eaa9282174), C64e(0xe9bdf7353b3651ee),
  C64e(0x1d57ac5a7550d376), C64e(0x3a46c2fea37d7001),
  C64e(0xf735c1af98a4d842), C64e(0x78edec209e6b6779),
  C64e(0x41836315ea3adba8), C64e(0xfac33b4d32832c83),
  C64e(0xa7403b1f1c2747f3), C64e(0x5940f034b72d769a),
  C64e(0xe73e4e6cd2214ffd), C64e(0xb8fd8d39dc5759ef),
  C64e(0x8d9b0c492b49ebda), C64e(0x5ba2d74968f3700d),
  C64e(0x7d3baed07a8d5584), C64e(0xf5a5e9f0e4f88e65),
  C64e(0xa0b8a2f436103b53), C64e(0x0ca8079e753eec5a),
  C64e(0x9168949256e8884f), C64e(0x5bb05c55f8babc4c),
  C64e(0xe3bb3b99f387947b), C64e(0x75daf4d6726b1c5d),
  C64e(0x64aeac28dc34b36d), C64e(0x6c34a550b828db71),
  C64e(0xf861e2f2108d512a), C64e(0xe3db643359dd75fc),
  C64e(0x1cacbcf143ce3fa2), C64e(0x67bbd13c02e843b0),
  C64e(0x330a5bca8829a175), C64e(0x7f34194db416535c),
  C64e(0x923b94c30e794d1e), C64e(0x797475d7b6eeaf3f),
  C64e(0xeaa8d4f7be1a3921), C64e(0x5cf47e094c232751),
  C64e(0x26a32453ba323cd2), C64e(0x44a3174a6da6d5ad),
  C64e(0xb51d3ea6aff2c908), C64e(0x83593d98916b3c56),
  C64e(0x4cf87ca17286604d), C64e(0x46e23ecc086ec7f6),
  C64e(0x2f9833b3b1bc765e), C64e(0x2bd666a5efc4e62a),
  C64e(0x06f4b6e8bec1d436), C64e(0x74ee8215bcef2163),
  C64e(0xfdc14e0df453c969), C64e(0xa77d5ac406585826),
  C64e(0x7ec1141606e0fa16), C64e(0x7e90af3d28639d3f),
  C64e(0xd2c9f2e3009bd20c), C64e(0x5faace30b7d40c30),
  C64e(0x742a5116f2e03298), C64e(0x0deb30d8e3cef89a),
  C64e(0x4bc59e7bb5f17992), C64e(0xff51e66e048668d3),
  C64e(0x9b234d57e6966731), C64e(0xcce6a6f3170a7505),
  C64e(0xb17681d913326cce), C64e(0x3c175284f805a262),
  C64e(0xf42bcbb378471547), C64e(0xff46548223936a48),
  C64e(0x38df58074e5e6565), C64e(0xf2fc7c89fc86508e),
  C64e(0x31702e44d00bca86), C64e(0xf04009a23078474e),
  C64e(0x65a0ee39d1f73883), C64e(0xf75ee937e42c3abd),
  C64e(0x2197b2260113f86f), C64e(0xa344edd1ef9fdee7),
  C64e(0x8ba0df15762592d9), C64e(0x3c85f7f612dc42be),
  C64e(0xd8a7ec7cab27b07e), C64e(0x538d7ddaaa3ea8de),
  C64e(0xaa25ce93bd0269d8), C64e(0x5af643fd1a7308f9),
  C64e(0xc05fefda174a19a5), C64e(0x974d66334cfd216a),
  C64e(0x35b49831db411570), C64e(0xea1e0fbbedcd549b),
  C64e(0x9ad063a151974072), C64e(0xf6759dbf91476fe2)
};

#define Ceven_hi(r)   (C[((r) << 2) + 0])
#define Ceven_lo(r)   (C[((r) << 2) + 1])
#define Codd_hi(r)    (C[((r) << 2) + 2])
#define Codd_lo(r)    (C[((r) << 2) + 3])

#define S(x0, x1, x2, x3, cb, r)   do { \
    Sb(x0 ## h, x1 ## h, x2 ## h, x3 ## h, cb ## hi(r)); \
    Sb(x0 ## l, x1 ## l, x2 ## l, x3 ## l, cb ## lo(r)); \
  } while (0)

#define L(x0, x1, x2, x3, x4, x5, x6, x7)   do { \
    Lb(x0 ## h, x1 ## h, x2 ## h, x3 ## h, \
      x4 ## h, x5 ## h, x6 ## h, x7 ## h); \
    Lb(x0 ## l, x1 ## l, x2 ## l, x3 ## l, \
      x4 ## l, x5 ## l, x6 ## l, x7 ## l); \
  } while (0)

#define Wz(x, c, n)   do { \
    sph_u64 t = (x ## h & (c)) << (n); \
    x ## h = ((x ## h >> (n)) & (c)) | t; \
    t = (x ## l & (c)) << (n); \
    x ## l = ((x ## l >> (n)) & (c)) | t; \
  } while (0)

#define W0(x)   Wz(x, SPH_C64(0x5555555555555555),  1)
#define W1(x)   Wz(x, SPH_C64(0x3333333333333333),  2)
#define W2(x)   Wz(x, SPH_C64(0x0F0F0F0F0F0F0F0F),  4)
#define W3(x)   Wz(x, SPH_C64(0x00FF00FF00FF00FF),  8)
#define W4(x)   Wz(x, SPH_C64(0x0000FFFF0000FFFF), 16)
#define W5(x)   Wz(x, SPH_C64(0x00000000FFFFFFFF), 32)
#define W6(x)   do { \
    sph_u64 t = x ## h; \
    x ## h = x ## l; \
    x ## l = t; \
  } while (0)

__constant const sph_u64 JH_IV512[] = {
  C64e(0x6fd14b963e00aa17), C64e(0x636a2e057a15d543),
  C64e(0x8a225e8d0c97ef0b), C64e(0xe9341259f2b3c361),
  C64e(0x891da0c1536f801e), C64e(0x2aa9056bea2b6d80),
  C64e(0x588eccdb2075baa6), C64e(0xa90f3a76baf83bf7),
  C64e(0x0169e60541e34a69), C64e(0x46b58a8e2e6fe65a),
  C64e(0x1047a7d0c1843c24), C64e(0x3b6e71b12d5ac199),
  C64e(0xcf57f6ec9db1f856), C64e(0xa706887c5716b156),
  C64e(0xe3c2fcdfe68517fb), C64e(0x545a4678cc8cdd4b)
};

#define SL(ro)   SLu(r + ro, ro)

#define SLu(r, ro)   do { \
    S(h0, h2, h4, h6, Ceven_, r); \
    S(h1, h3, h5, h7, Codd_, r); \
    L(h0, h2, h4, h6, h1, h3, h5, h7); \
    W ## ro(h1); \
    W ## ro(h3); \
    W ## ro(h5); \
    W ## ro(h7); \
  } while (0)

#if SPH_SMALL_FOOTPRINT_JH

/*
 * The "small footprint" 64-bit version just uses a partially unrolled
 * loop.
 */

#define E8   do { \
    unsigned r; \
    for (r = 0; r < 42; r += 7) { \
      SL(0); \
      SL(1); \
      SL(2); \
      SL(3); \
      SL(4); \
      SL(5); \
      SL(6); \
    } \
  } while (0)

#else

/*
 * On a "true 64-bit" architecture, we can unroll at will.
 */

#define E8   do { \
    SLu( 0, 0); \
    SLu( 1, 1); \
    SLu( 2, 2); \
    SLu( 3, 3); \
    SLu( 4, 4); \
    SLu( 5, 5); \
    SLu( 6, 6); \
    SLu( 7, 0); \
    SLu( 8, 1); \
    SLu( 9, 2); \
    SLu(10, 3); \
    SLu(11, 4); \
    SLu(12, 5); \
    SLu(13, 6); \
    SLu(14, 0); \
    SLu(15, 1); \
    SLu(16, 2); \
    SLu(17, 3); \
    SLu(18, 4); \
    SLu(19, 5); \
    SLu(20, 6); \
    SLu(21, 0); \
    SLu(22, 1); \
    SLu(23, 2); \
    SLu(24, 3); \
    SLu(25, 4); \
    SLu(26, 5); \
    SLu(27, 6); \
    SLu(28, 0); \
    SLu(29, 1); \
    SLu(30, 2); \
    SLu(31, 3); \
    SLu(32, 4); \
    SLu(33, 5); \
    SLu(34, 6); \
    SLu(35, 0); \
    SLu(36, 1); \
    SLu(37, 2); \
    SLu(38, 3); \
    SLu(39, 4); \
    SLu(40, 5); \
    SLu(41, 6); \
  } while (0)

#endif

/* $Id: keccak.c 259 2011-07-19 22:11:27Z tp $ */
/*
 * Keccak implementation.
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

#ifdef __cplusplus
extern "C"{
#endif

/*
 * Parameters:
 *
 *  SPH_KECCAK_64          use a 64-bit type
 *  SPH_KECCAK_UNROLL      number of loops to unroll (0/undef for full unroll)
 *  SPH_KECCAK_INTERLEAVE  use bit-interleaving (32-bit type only)
 *  SPH_KECCAK_NOCOPY      do not copy the state into local variables
 * 
 * If there is no usable 64-bit type, the code automatically switches
 * back to the 32-bit implementation.
 *
 * Some tests on an Intel Core2 Q6600 (both 64-bit and 32-bit, 32 kB L1
 * code cache), a PowerPC (G3, 32 kB L1 code cache), an ARM920T core
 * (16 kB L1 code cache), and a small MIPS-compatible CPU (Broadcom BCM3302,
 * 8 kB L1 code cache), seem to show that the following are optimal:
 *
 * -- x86, 64-bit: use the 64-bit implementation, unroll 8 rounds,
 * do not copy the state; unrolling 2, 6 or all rounds also provides
 * near-optimal performance.
 * -- x86, 32-bit: use the 32-bit implementation, unroll 6 rounds,
 * interleave, do not copy the state. Unrolling 1, 2, 4 or 8 rounds
 * also provides near-optimal performance.
 * -- PowerPC: use the 64-bit implementation, unroll 8 rounds,
 * copy the state. Unrolling 4 or 6 rounds is near-optimal.
 * -- ARM: use the 64-bit implementation, unroll 2 or 4 rounds,
 * copy the state.
 * -- MIPS: use the 64-bit implementation, unroll 2 rounds, copy
 * the state. Unrolling only 1 round is also near-optimal.
 *
 * Also, interleaving does not always yield actual improvements when
 * using a 32-bit implementation; in particular when the architecture
 * does not offer a native rotation opcode (interleaving replaces one
 * 64-bit rotation with two 32-bit rotations, which is a gain only if
 * there is a native 32-bit rotation opcode and not a native 64-bit
 * rotation opcode; also, interleaving implies a small overhead when
 * processing input words).
 *
 * To sum up:
 * -- when possible, use the 64-bit code
 * -- exception: on 32-bit x86, use 32-bit code
 * -- when using 32-bit code, use interleaving
 * -- copy the state, except on x86
 * -- unroll 8 rounds on "big" machine, 2 rounds on "small" machines
 */

/*
 * Unroll 8 rounds on big systems, 2 rounds on small systems.
 */
#ifndef SPH_KECCAK_UNROLL
#if SPH_SMALL_FOOTPRINT_KECCAK
#define SPH_KECCAK_UNROLL   2
#else
#define SPH_KECCAK_UNROLL   8
#endif
#endif

__constant const sph_u64 RC[] = {
  SPH_C64(0x0000000000000001), SPH_C64(0x0000000000008082),
  SPH_C64(0x800000000000808A), SPH_C64(0x8000000080008000),
  SPH_C64(0x000000000000808B), SPH_C64(0x0000000080000001),
  SPH_C64(0x8000000080008081), SPH_C64(0x8000000000008009),
  SPH_C64(0x000000000000008A), SPH_C64(0x0000000000000088),
  SPH_C64(0x0000000080008009), SPH_C64(0x000000008000000A),
  SPH_C64(0x000000008000808B), SPH_C64(0x800000000000008B),
  SPH_C64(0x8000000000008089), SPH_C64(0x8000000000008003),
  SPH_C64(0x8000000000008002), SPH_C64(0x8000000000000080),
  SPH_C64(0x000000000000800A), SPH_C64(0x800000008000000A),
  SPH_C64(0x8000000080008081), SPH_C64(0x8000000000008080),
  SPH_C64(0x0000000080000001), SPH_C64(0x8000000080008008)
};

#define DECL64(x)        sph_u64 x
#define MOV64(d, s)      (d = s)
#define XOR64(d, a, b)   (d = a ^ b)
#define AND64(d, a, b)   (d = a & b)
#define OR64(d, a, b)    (d = a | b)
#define NOT64(d, s)      (d = SPH_T64(~s))
#define ROL64(d, v, n)   (d = SPH_ROTL64(v, n))
#define XOR64_IOTA       XOR64

#define TH_ELT(t, c0, c1, c2, c3, c4, d0, d1, d2, d3, d4)   do { \
    DECL64(tt0); \
    DECL64(tt1); \
    DECL64(tt2); \
    DECL64(tt3); \
    XOR64(tt0, d0, d1); \
    XOR64(tt1, d2, d3); \
    XOR64(tt0, tt0, d4); \
    XOR64(tt0, tt0, tt1); \
    ROL64(tt0, tt0, 1); \
    XOR64(tt2, c0, c1); \
    XOR64(tt3, c2, c3); \
    XOR64(tt0, tt0, c4); \
    XOR64(tt2, tt2, tt3); \
    XOR64(t, tt0, tt2); \
  } while (0)

#define THETA(b00, b01, b02, b03, b04, b10, b11, b12, b13, b14, \
  b20, b21, b22, b23, b24, b30, b31, b32, b33, b34, \
  b40, b41, b42, b43, b44) \
  do { \
    DECL64(t0); \
    DECL64(t1); \
    DECL64(t2); \
    DECL64(t3); \
    DECL64(t4); \
    TH_ELT(t0, b40, b41, b42, b43, b44, b10, b11, b12, b13, b14); \
    TH_ELT(t1, b00, b01, b02, b03, b04, b20, b21, b22, b23, b24); \
    TH_ELT(t2, b10, b11, b12, b13, b14, b30, b31, b32, b33, b34); \
    TH_ELT(t3, b20, b21, b22, b23, b24, b40, b41, b42, b43, b44); \
    TH_ELT(t4, b30, b31, b32, b33, b34, b00, b01, b02, b03, b04); \
    XOR64(b00, b00, t0); \
    XOR64(b01, b01, t0); \
    XOR64(b02, b02, t0); \
    XOR64(b03, b03, t0); \
    XOR64(b04, b04, t0); \
    XOR64(b10, b10, t1); \
    XOR64(b11, b11, t1); \
    XOR64(b12, b12, t1); \
    XOR64(b13, b13, t1); \
    XOR64(b14, b14, t1); \
    XOR64(b20, b20, t2); \
    XOR64(b21, b21, t2); \
    XOR64(b22, b22, t2); \
    XOR64(b23, b23, t2); \
    XOR64(b24, b24, t2); \
    XOR64(b30, b30, t3); \
    XOR64(b31, b31, t3); \
    XOR64(b32, b32, t3); \
    XOR64(b33, b33, t3); \
    XOR64(b34, b34, t3); \
    XOR64(b40, b40, t4); \
    XOR64(b41, b41, t4); \
    XOR64(b42, b42, t4); \
    XOR64(b43, b43, t4); \
    XOR64(b44, b44, t4); \
  } while (0)

#define RHO(b00, b01, b02, b03, b04, b10, b11, b12, b13, b14, \
  b20, b21, b22, b23, b24, b30, b31, b32, b33, b34, \
  b40, b41, b42, b43, b44) \
  do { \
    /* ROL64(b00, b00,  0); */ \
    ROL64(b01, b01, 36); \
    ROL64(b02, b02,  3); \
    ROL64(b03, b03, 41); \
    ROL64(b04, b04, 18); \
    ROL64(b10, b10,  1); \
    ROL64(b11, b11, 44); \
    ROL64(b12, b12, 10); \
    ROL64(b13, b13, 45); \
    ROL64(b14, b14,  2); \
    ROL64(b20, b20, 62); \
    ROL64(b21, b21,  6); \
    ROL64(b22, b22, 43); \
    ROL64(b23, b23, 15); \
    ROL64(b24, b24, 61); \
    ROL64(b30, b30, 28); \
    ROL64(b31, b31, 55); \
    ROL64(b32, b32, 25); \
    ROL64(b33, b33, 21); \
    ROL64(b34, b34, 56); \
    ROL64(b40, b40, 27); \
    ROL64(b41, b41, 20); \
    ROL64(b42, b42, 39); \
    ROL64(b43, b43,  8); \
    ROL64(b44, b44, 14); \
  } while (0)

/*
 * The KHI macro integrates the "lane complement" optimization. On input,
 * some words are complemented:
 *    a00 a01 a02 a04 a13 a20 a21 a22 a30 a33 a34 a43
 * On output, the following words are complemented:
 *    a04 a10 a20 a22 a23 a31
 *
 * The (implicit) permutation and the theta expansion will bring back
 * the input mask for the next round.
 */

#define KHI_XO(d, a, b, c)   do { \
    DECL64(kt); \
    OR64(kt, b, c); \
    XOR64(d, a, kt); \
  } while (0)

#define KHI_XA(d, a, b, c)   do { \
    DECL64(kt); \
    AND64(kt, b, c); \
    XOR64(d, a, kt); \
  } while (0)

#define KHI(b00, b01, b02, b03, b04, b10, b11, b12, b13, b14, \
  b20, b21, b22, b23, b24, b30, b31, b32, b33, b34, \
  b40, b41, b42, b43, b44) \
  do { \
    DECL64(c0); \
    DECL64(c1); \
    DECL64(c2); \
    DECL64(c3); \
    DECL64(c4); \
    DECL64(bnn); \
    NOT64(bnn, b20); \
    KHI_XO(c0, b00, b10, b20); \
    KHI_XO(c1, b10, bnn, b30); \
    KHI_XA(c2, b20, b30, b40); \
    KHI_XO(c3, b30, b40, b00); \
    KHI_XA(c4, b40, b00, b10); \
    MOV64(b00, c0); \
    MOV64(b10, c1); \
    MOV64(b20, c2); \
    MOV64(b30, c3); \
    MOV64(b40, c4); \
    NOT64(bnn, b41); \
    KHI_XO(c0, b01, b11, b21); \
    KHI_XA(c1, b11, b21, b31); \
    KHI_XO(c2, b21, b31, bnn); \
    KHI_XO(c3, b31, b41, b01); \
    KHI_XA(c4, b41, b01, b11); \
    MOV64(b01, c0); \
    MOV64(b11, c1); \
    MOV64(b21, c2); \
    MOV64(b31, c3); \
    MOV64(b41, c4); \
    NOT64(bnn, b32); \
    KHI_XO(c0, b02, b12, b22); \
    KHI_XA(c1, b12, b22, b32); \
    KHI_XA(c2, b22, bnn, b42); \
    KHI_XO(c3, bnn, b42, b02); \
    KHI_XA(c4, b42, b02, b12); \
    MOV64(b02, c0); \
    MOV64(b12, c1); \
    MOV64(b22, c2); \
    MOV64(b32, c3); \
    MOV64(b42, c4); \
    NOT64(bnn, b33); \
    KHI_XA(c0, b03, b13, b23); \
    KHI_XO(c1, b13, b23, b33); \
    KHI_XO(c2, b23, bnn, b43); \
    KHI_XA(c3, bnn, b43, b03); \
    KHI_XO(c4, b43, b03, b13); \
    MOV64(b03, c0); \
    MOV64(b13, c1); \
    MOV64(b23, c2); \
    MOV64(b33, c3); \
    MOV64(b43, c4); \
    NOT64(bnn, b14); \
    KHI_XA(c0, b04, bnn, b24); \
    KHI_XO(c1, bnn, b24, b34); \
    KHI_XA(c2, b24, b34, b44); \
    KHI_XO(c3, b34, b44, b04); \
    KHI_XA(c4, b44, b04, b14); \
    MOV64(b04, c0); \
    MOV64(b14, c1); \
    MOV64(b24, c2); \
    MOV64(b34, c3); \
    MOV64(b44, c4); \
  } while (0)

#define IOTA(r)   XOR64_IOTA(a00, a00, r)

#define P0    a00, a01, a02, a03, a04, a10, a11, a12, a13, a14, a20, a21, \
              a22, a23, a24, a30, a31, a32, a33, a34, a40, a41, a42, a43, a44
#define P1    a00, a30, a10, a40, a20, a11, a41, a21, a01, a31, a22, a02, \
              a32, a12, a42, a33, a13, a43, a23, a03, a44, a24, a04, a34, a14
#define P2    a00, a33, a11, a44, a22, a41, a24, a02, a30, a13, a32, a10, \
              a43, a21, a04, a23, a01, a34, a12, a40, a14, a42, a20, a03, a31
#define P3    a00, a23, a41, a14, a32, a24, a42, a10, a33, a01, a43, a11, \
              a34, a02, a20, a12, a30, a03, a21, a44, a31, a04, a22, a40, a13
#define P4    a00, a12, a24, a31, a43, a42, a04, a11, a23, a30, a34, a41, \
              a03, a10, a22, a21, a33, a40, a02, a14, a13, a20, a32, a44, a01
#define P5    a00, a21, a42, a13, a34, a04, a20, a41, a12, a33, a03, a24, \
              a40, a11, a32, a02, a23, a44, a10, a31, a01, a22, a43, a14, a30
#define P6    a00, a02, a04, a01, a03, a20, a22, a24, a21, a23, a40, a42, \
              a44, a41, a43, a10, a12, a14, a11, a13, a30, a32, a34, a31, a33
#define P7    a00, a10, a20, a30, a40, a22, a32, a42, a02, a12, a44, a04, \
              a14, a24, a34, a11, a21, a31, a41, a01, a33, a43, a03, a13, a23
#define P8    a00, a11, a22, a33, a44, a32, a43, a04, a10, a21, a14, a20, \
              a31, a42, a03, a41, a02, a13, a24, a30, a23, a34, a40, a01, a12
#define P9    a00, a41, a32, a23, a14, a43, a34, a20, a11, a02, a31, a22, \
              a13, a04, a40, a24, a10, a01, a42, a33, a12, a03, a44, a30, a21
#define P10   a00, a24, a43, a12, a31, a34, a03, a22, a41, a10, a13, a32, \
              a01, a20, a44, a42, a11, a30, a04, a23, a21, a40, a14, a33, a02
#define P11   a00, a42, a34, a21, a13, a03, a40, a32, a24, a11, a01, a43, \
              a30, a22, a14, a04, a41, a33, a20, a12, a02, a44, a31, a23, a10
#define P12   a00, a04, a03, a02, a01, a40, a44, a43, a42, a41, a30, a34, \
              a33, a32, a31, a20, a24, a23, a22, a21, a10, a14, a13, a12, a11
#define P13   a00, a20, a40, a10, a30, a44, a14, a34, a04, a24, a33, a03, \
              a23, a43, a13, a22, a42, a12, a32, a02, a11, a31, a01, a21, a41
#define P14   a00, a22, a44, a11, a33, a14, a31, a03, a20, a42, a23, a40, \
              a12, a34, a01, a32, a04, a21, a43, a10, a41, a13, a30, a02, a24
#define P15   a00, a32, a14, a41, a23, a31, a13, a40, a22, a04, a12, a44, \
              a21, a03, a30, a43, a20, a02, a34, a11, a24, a01, a33, a10, a42
#define P16   a00, a43, a31, a24, a12, a13, a01, a44, a32, a20, a21, a14, \
              a02, a40, a33, a34, a22, a10, a03, a41, a42, a30, a23, a11, a04
#define P17   a00, a34, a13, a42, a21, a01, a30, a14, a43, a22, a02, a31, \
              a10, a44, a23, a03, a32, a11, a40, a24, a04, a33, a12, a41, a20
#define P18   a00, a03, a01, a04, a02, a30, a33, a31, a34, a32, a10, a13, \
              a11, a14, a12, a40, a43, a41, a44, a42, a20, a23, a21, a24, a22
#define P19   a00, a40, a30, a20, a10, a33, a23, a13, a03, a43, a11, a01, \
              a41, a31, a21, a44, a34, a24, a14, a04, a22, a12, a02, a42, a32
#define P20   a00, a44, a33, a22, a11, a23, a12, a01, a40, a34, a41, a30, \
              a24, a13, a02, a14, a03, a42, a31, a20, a32, a21, a10, a04, a43
#define P21   a00, a14, a23, a32, a41, a12, a21, a30, a44, a03, a24, a33, \
              a42, a01, a10, a31, a40, a04, a13, a22, a43, a02, a11, a20, a34
#define P22   a00, a31, a12, a43, a24, a21, a02, a33, a14, a40, a42, a23, \
              a04, a30, a11, a13, a44, a20, a01, a32, a34, a10, a41, a22, a03
#define P23   a00, a13, a21, a34, a42, a02, a10, a23, a31, a44, a04, a12, \
              a20, a33, a41, a01, a14, a22, a30, a43, a03, a11, a24, a32, a40

#define P1_TO_P0   do { \
    DECL64(t); \
    MOV64(t, a01); \
    MOV64(a01, a30); \
    MOV64(a30, a33); \
    MOV64(a33, a23); \
    MOV64(a23, a12); \
    MOV64(a12, a21); \
    MOV64(a21, a02); \
    MOV64(a02, a10); \
    MOV64(a10, a11); \
    MOV64(a11, a41); \
    MOV64(a41, a24); \
    MOV64(a24, a42); \
    MOV64(a42, a04); \
    MOV64(a04, a20); \
    MOV64(a20, a22); \
    MOV64(a22, a32); \
    MOV64(a32, a43); \
    MOV64(a43, a34); \
    MOV64(a34, a03); \
    MOV64(a03, a40); \
    MOV64(a40, a44); \
    MOV64(a44, a14); \
    MOV64(a14, a31); \
    MOV64(a31, a13); \
    MOV64(a13, t); \
  } while (0)

#define P2_TO_P0   do { \
    DECL64(t); \
    MOV64(t, a01); \
    MOV64(a01, a33); \
    MOV64(a33, a12); \
    MOV64(a12, a02); \
    MOV64(a02, a11); \
    MOV64(a11, a24); \
    MOV64(a24, a04); \
    MOV64(a04, a22); \
    MOV64(a22, a43); \
    MOV64(a43, a03); \
    MOV64(a03, a44); \
    MOV64(a44, a31); \
    MOV64(a31, t); \
    MOV64(t, a10); \
    MOV64(a10, a41); \
    MOV64(a41, a42); \
    MOV64(a42, a20); \
    MOV64(a20, a32); \
    MOV64(a32, a34); \
    MOV64(a34, a40); \
    MOV64(a40, a14); \
    MOV64(a14, a13); \
    MOV64(a13, a30); \
    MOV64(a30, a23); \
    MOV64(a23, a21); \
    MOV64(a21, t); \
  } while (0)

#define P4_TO_P0   do { \
    DECL64(t); \
    MOV64(t, a01); \
    MOV64(a01, a12); \
    MOV64(a12, a11); \
    MOV64(a11, a04); \
    MOV64(a04, a43); \
    MOV64(a43, a44); \
    MOV64(a44, t); \
    MOV64(t, a02); \
    MOV64(a02, a24); \
    MOV64(a24, a22); \
    MOV64(a22, a03); \
    MOV64(a03, a31); \
    MOV64(a31, a33); \
    MOV64(a33, t); \
    MOV64(t, a10); \
    MOV64(a10, a42); \
    MOV64(a42, a32); \
    MOV64(a32, a40); \
    MOV64(a40, a13); \
    MOV64(a13, a23); \
    MOV64(a23, t); \
    MOV64(t, a14); \
    MOV64(a14, a30); \
    MOV64(a30, a21); \
    MOV64(a21, a41); \
    MOV64(a41, a20); \
    MOV64(a20, a34); \
    MOV64(a34, t); \
  } while (0)

#define P6_TO_P0   do { \
    DECL64(t); \
    MOV64(t, a01); \
    MOV64(a01, a02); \
    MOV64(a02, a04); \
    MOV64(a04, a03); \
    MOV64(a03, t); \
    MOV64(t, a10); \
    MOV64(a10, a20); \
    MOV64(a20, a40); \
    MOV64(a40, a30); \
    MOV64(a30, t); \
    MOV64(t, a11); \
    MOV64(a11, a22); \
    MOV64(a22, a44); \
    MOV64(a44, a33); \
    MOV64(a33, t); \
    MOV64(t, a12); \
    MOV64(a12, a24); \
    MOV64(a24, a43); \
    MOV64(a43, a31); \
    MOV64(a31, t); \
    MOV64(t, a13); \
    MOV64(a13, a21); \
    MOV64(a21, a42); \
    MOV64(a42, a34); \
    MOV64(a34, t); \
    MOV64(t, a14); \
    MOV64(a14, a23); \
    MOV64(a23, a41); \
    MOV64(a41, a32); \
    MOV64(a32, t); \
  } while (0)

#define P8_TO_P0   do { \
    DECL64(t); \
    MOV64(t, a01); \
    MOV64(a01, a11); \
    MOV64(a11, a43); \
    MOV64(a43, t); \
    MOV64(t, a02); \
    MOV64(a02, a22); \
    MOV64(a22, a31); \
    MOV64(a31, t); \
    MOV64(t, a03); \
    MOV64(a03, a33); \
    MOV64(a33, a24); \
    MOV64(a24, t); \
    MOV64(t, a04); \
    MOV64(a04, a44); \
    MOV64(a44, a12); \
    MOV64(a12, t); \
    MOV64(t, a10); \
    MOV64(a10, a32); \
    MOV64(a32, a13); \
    MOV64(a13, t); \
    MOV64(t, a14); \
    MOV64(a14, a21); \
    MOV64(a21, a20); \
    MOV64(a20, t); \
    MOV64(t, a23); \
    MOV64(a23, a42); \
    MOV64(a42, a40); \
    MOV64(a40, t); \
    MOV64(t, a30); \
    MOV64(a30, a41); \
    MOV64(a41, a34); \
    MOV64(a34, t); \
  } while (0)

#define P12_TO_P0   do { \
    DECL64(t); \
    MOV64(t, a01); \
    MOV64(a01, a04); \
    MOV64(a04, t); \
    MOV64(t, a02); \
    MOV64(a02, a03); \
    MOV64(a03, t); \
    MOV64(t, a10); \
    MOV64(a10, a40); \
    MOV64(a40, t); \
    MOV64(t, a11); \
    MOV64(a11, a44); \
    MOV64(a44, t); \
    MOV64(t, a12); \
    MOV64(a12, a43); \
    MOV64(a43, t); \
    MOV64(t, a13); \
    MOV64(a13, a42); \
    MOV64(a42, t); \
    MOV64(t, a14); \
    MOV64(a14, a41); \
    MOV64(a41, t); \
    MOV64(t, a20); \
    MOV64(a20, a30); \
    MOV64(a30, t); \
    MOV64(t, a21); \
    MOV64(a21, a34); \
    MOV64(a34, t); \
    MOV64(t, a22); \
    MOV64(a22, a33); \
    MOV64(a33, t); \
    MOV64(t, a23); \
    MOV64(a23, a32); \
    MOV64(a32, t); \
    MOV64(t, a24); \
    MOV64(a24, a31); \
    MOV64(a31, t); \
  } while (0)

#define LPAR   (
#define RPAR   )

#define KF_ELT(r, s, k)   do { \
    THETA LPAR P ## r RPAR; \
    RHO LPAR P ## r RPAR; \
    KHI LPAR P ## s RPAR; \
    IOTA(k); \
  } while (0)

#define DO(x)   x

#define KECCAK_F_1600   DO(KECCAK_F_1600_)

#if SPH_KECCAK_UNROLL == 1

#define KECCAK_F_1600_   do { \
    int j; \
    for (j = 0; j < 24; j ++) { \
      KF_ELT( 0,  1, RC[j + 0]); \
      P1_TO_P0; \
    } \
  } while (0)

#elif SPH_KECCAK_UNROLL == 2

#define KECCAK_F_1600_   do { \
    int j; \
    for (j = 0; j < 24; j += 2) { \
      KF_ELT( 0,  1, RC[j + 0]); \
      KF_ELT( 1,  2, RC[j + 1]); \
      P2_TO_P0; \
    } \
  } while (0)

#elif SPH_KECCAK_UNROLL == 4

#define KECCAK_F_1600_   do { \
    int j; \
    for (j = 0; j < 24; j += 4) { \
      KF_ELT( 0,  1, RC[j + 0]); \
      KF_ELT( 1,  2, RC[j + 1]); \
      KF_ELT( 2,  3, RC[j + 2]); \
      KF_ELT( 3,  4, RC[j + 3]); \
      P4_TO_P0; \
    } \
  } while (0)

#elif SPH_KECCAK_UNROLL == 6

#define KECCAK_F_1600_   do { \
    int j; \
    for (j = 0; j < 24; j += 6) { \
      KF_ELT( 0,  1, RC[j + 0]); \
      KF_ELT( 1,  2, RC[j + 1]); \
      KF_ELT( 2,  3, RC[j + 2]); \
      KF_ELT( 3,  4, RC[j + 3]); \
      KF_ELT( 4,  5, RC[j + 4]); \
      KF_ELT( 5,  6, RC[j + 5]); \
      P6_TO_P0; \
    } \
  } while (0)

#elif SPH_KECCAK_UNROLL == 8

#define KECCAK_F_1600_   do { \
    int j; \
    for (j = 0; j < 24; j += 8) { \
      KF_ELT( 0,  1, RC[j + 0]); \
      KF_ELT( 1,  2, RC[j + 1]); \
      KF_ELT( 2,  3, RC[j + 2]); \
      KF_ELT( 3,  4, RC[j + 3]); \
      KF_ELT( 4,  5, RC[j + 4]); \
      KF_ELT( 5,  6, RC[j + 5]); \
      KF_ELT( 6,  7, RC[j + 6]); \
      KF_ELT( 7,  8, RC[j + 7]); \
      P8_TO_P0; \
    } \
  } while (0)

#elif SPH_KECCAK_UNROLL == 12

#define KECCAK_F_1600_   do { \
    int j; \
    for (j = 0; j < 24; j += 12) { \
      KF_ELT( 0,  1, RC[j +  0]); \
      KF_ELT( 1,  2, RC[j +  1]); \
      KF_ELT( 2,  3, RC[j +  2]); \
      KF_ELT( 3,  4, RC[j +  3]); \
      KF_ELT( 4,  5, RC[j +  4]); \
      KF_ELT( 5,  6, RC[j +  5]); \
      KF_ELT( 6,  7, RC[j +  6]); \
      KF_ELT( 7,  8, RC[j +  7]); \
      KF_ELT( 8,  9, RC[j +  8]); \
      KF_ELT( 9, 10, RC[j +  9]); \
      KF_ELT(10, 11, RC[j + 10]); \
      KF_ELT(11, 12, RC[j + 11]); \
      P12_TO_P0; \
    } \
  } while (0)

#elif SPH_KECCAK_UNROLL == 0

#define KECCAK_F_1600_   do { \
    KF_ELT( 0,  1, RC[ 0]); \
    KF_ELT( 1,  2, RC[ 1]); \
    KF_ELT( 2,  3, RC[ 2]); \
    KF_ELT( 3,  4, RC[ 3]); \
    KF_ELT( 4,  5, RC[ 4]); \
    KF_ELT( 5,  6, RC[ 5]); \
    KF_ELT( 6,  7, RC[ 6]); \
    KF_ELT( 7,  8, RC[ 7]); \
    KF_ELT( 8,  9, RC[ 8]); \
    KF_ELT( 9, 10, RC[ 9]); \
    KF_ELT(10, 11, RC[10]); \
    KF_ELT(11, 12, RC[11]); \
    KF_ELT(12, 13, RC[12]); \
    KF_ELT(13, 14, RC[13]); \
    KF_ELT(14, 15, RC[14]); \
    KF_ELT(15, 16, RC[15]); \
    KF_ELT(16, 17, RC[16]); \
    KF_ELT(17, 18, RC[17]); \
    KF_ELT(18, 19, RC[18]); \
    KF_ELT(19, 20, RC[19]); \
    KF_ELT(20, 21, RC[20]); \
    KF_ELT(21, 22, RC[21]); \
    KF_ELT(22, 23, RC[22]); \
    KF_ELT(23,  0, RC[23]); \
  } while (0)

#else

#error Unimplemented unroll count for Keccak.

#endif

/* $Id: skein.c 254 2011-06-07 19:38:58Z tp $ */
/*
 * Skein implementation.
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

/*
 * M9_ ## s ## _ ## i  evaluates to s+i mod 9 (0 <= s <= 18, 0 <= i <= 7).
 */

#define M9_0_0    0
#define M9_0_1    1
#define M9_0_2    2
#define M9_0_3    3
#define M9_0_4    4
#define M9_0_5    5
#define M9_0_6    6
#define M9_0_7    7

#define M9_1_0    1
#define M9_1_1    2
#define M9_1_2    3
#define M9_1_3    4
#define M9_1_4    5
#define M9_1_5    6
#define M9_1_6    7
#define M9_1_7    8

#define M9_2_0    2
#define M9_2_1    3
#define M9_2_2    4
#define M9_2_3    5
#define M9_2_4    6
#define M9_2_5    7
#define M9_2_6    8
#define M9_2_7    0

#define M9_3_0    3
#define M9_3_1    4
#define M9_3_2    5
#define M9_3_3    6
#define M9_3_4    7
#define M9_3_5    8
#define M9_3_6    0
#define M9_3_7    1

#define M9_4_0    4
#define M9_4_1    5
#define M9_4_2    6
#define M9_4_3    7
#define M9_4_4    8
#define M9_4_5    0
#define M9_4_6    1
#define M9_4_7    2

#define M9_5_0    5
#define M9_5_1    6
#define M9_5_2    7
#define M9_5_3    8
#define M9_5_4    0
#define M9_5_5    1
#define M9_5_6    2
#define M9_5_7    3

#define M9_6_0    6
#define M9_6_1    7
#define M9_6_2    8
#define M9_6_3    0
#define M9_6_4    1
#define M9_6_5    2
#define M9_6_6    3
#define M9_6_7    4

#define M9_7_0    7
#define M9_7_1    8
#define M9_7_2    0
#define M9_7_3    1
#define M9_7_4    2
#define M9_7_5    3
#define M9_7_6    4
#define M9_7_7    5

#define M9_8_0    8
#define M9_8_1    0
#define M9_8_2    1
#define M9_8_3    2
#define M9_8_4    3
#define M9_8_5    4
#define M9_8_6    5
#define M9_8_7    6

#define M9_9_0    0
#define M9_9_1    1
#define M9_9_2    2
#define M9_9_3    3
#define M9_9_4    4
#define M9_9_5    5
#define M9_9_6    6
#define M9_9_7    7

#define M9_10_0   1
#define M9_10_1   2
#define M9_10_2   3
#define M9_10_3   4
#define M9_10_4   5
#define M9_10_5   6
#define M9_10_6   7
#define M9_10_7   8

#define M9_11_0   2
#define M9_11_1   3
#define M9_11_2   4
#define M9_11_3   5
#define M9_11_4   6
#define M9_11_5   7
#define M9_11_6   8
#define M9_11_7   0

#define M9_12_0   3
#define M9_12_1   4
#define M9_12_2   5
#define M9_12_3   6
#define M9_12_4   7
#define M9_12_5   8
#define M9_12_6   0
#define M9_12_7   1

#define M9_13_0   4
#define M9_13_1   5
#define M9_13_2   6
#define M9_13_3   7
#define M9_13_4   8
#define M9_13_5   0
#define M9_13_6   1
#define M9_13_7   2

#define M9_14_0   5
#define M9_14_1   6
#define M9_14_2   7
#define M9_14_3   8
#define M9_14_4   0
#define M9_14_5   1
#define M9_14_6   2
#define M9_14_7   3

#define M9_15_0   6
#define M9_15_1   7
#define M9_15_2   8
#define M9_15_3   0
#define M9_15_4   1
#define M9_15_5   2
#define M9_15_6   3
#define M9_15_7   4

#define M9_16_0   7
#define M9_16_1   8
#define M9_16_2   0
#define M9_16_3   1
#define M9_16_4   2
#define M9_16_5   3
#define M9_16_6   4
#define M9_16_7   5

#define M9_17_0   8
#define M9_17_1   0
#define M9_17_2   1
#define M9_17_3   2
#define M9_17_4   3
#define M9_17_5   4
#define M9_17_6   5
#define M9_17_7   6

#define M9_18_0   0
#define M9_18_1   1
#define M9_18_2   2
#define M9_18_3   3
#define M9_18_4   4
#define M9_18_5   5
#define M9_18_6   6
#define M9_18_7   7

/*
 * M3_ ## s ## _ ## i  evaluates to s+i mod 3 (0 <= s <= 18, 0 <= i <= 1).
 */

#define M3_0_0    0
#define M3_0_1    1
#define M3_1_0    1
#define M3_1_1    2
#define M3_2_0    2
#define M3_2_1    0
#define M3_3_0    0
#define M3_3_1    1
#define M3_4_0    1
#define M3_4_1    2
#define M3_5_0    2
#define M3_5_1    0
#define M3_6_0    0
#define M3_6_1    1
#define M3_7_0    1
#define M3_7_1    2
#define M3_8_0    2
#define M3_8_1    0
#define M3_9_0    0
#define M3_9_1    1
#define M3_10_0   1
#define M3_10_1   2
#define M3_11_0   2
#define M3_11_1   0
#define M3_12_0   0
#define M3_12_1   1
#define M3_13_0   1
#define M3_13_1   2
#define M3_14_0   2
#define M3_14_1   0
#define M3_15_0   0
#define M3_15_1   1
#define M3_16_0   1
#define M3_16_1   2
#define M3_17_0   2
#define M3_17_1   0
#define M3_18_0   0
#define M3_18_1   1

#define XCAT(x, y)     XCAT_(x, y)
#define XCAT_(x, y)    x ## y

#define SKBI(k, s, i)   XCAT(k, XCAT(XCAT(XCAT(M9_, s), _), i))
#define SKBT(t, s, v)   XCAT(t, XCAT(XCAT(XCAT(M3_, s), _), v))

#define TFBIG_KINIT(k0, k1, k2, k3, k4, k5, k6, k7, k8, t0, t1, t2)   do { \
    k8 = ((k0 ^ k1) ^ (k2 ^ k3)) ^ ((k4 ^ k5) ^ (k6 ^ k7)) \
      ^ SPH_C64(0x1BD11BDAA9FC1A22); \
    t2 = t0 ^ t1; \
  } while (0)

#define TFBIG_ADDKEY(w0, w1, w2, w3, w4, w5, w6, w7, k, t, s)   do { \
    w0 = SPH_T64(w0 + SKBI(k, s, 0)); \
    w1 = SPH_T64(w1 + SKBI(k, s, 1)); \
    w2 = SPH_T64(w2 + SKBI(k, s, 2)); \
    w3 = SPH_T64(w3 + SKBI(k, s, 3)); \
    w4 = SPH_T64(w4 + SKBI(k, s, 4)); \
    w5 = SPH_T64(w5 + SKBI(k, s, 5) + SKBT(t, s, 0)); \
    w6 = SPH_T64(w6 + SKBI(k, s, 6) + SKBT(t, s, 1)); \
    w7 = SPH_T64(w7 + SKBI(k, s, 7) + (sph_u64)s); \
  } while (0)

#define TFBIG_MIX(x0, x1, rc)   do { \
    x0 = SPH_T64(x0 + x1); \
    x1 = SPH_ROTL64(x1, rc) ^ x0; \
  } while (0)

#define TFBIG_MIX8(w0, w1, w2, w3, w4, w5, w6, w7, rc0, rc1, rc2, rc3)  do { \
    TFBIG_MIX(w0, w1, rc0); \
    TFBIG_MIX(w2, w3, rc1); \
    TFBIG_MIX(w4, w5, rc2); \
    TFBIG_MIX(w6, w7, rc3); \
  } while (0)

#define TFBIG_4e(s)   do { \
    TFBIG_ADDKEY(p0, p1, p2, p3, p4, p5, p6, p7, h, t, s); \
    TFBIG_MIX8(p0, p1, p2, p3, p4, p5, p6, p7, 46, 36, 19, 37); \
    TFBIG_MIX8(p2, p1, p4, p7, p6, p5, p0, p3, 33, 27, 14, 42); \
    TFBIG_MIX8(p4, p1, p6, p3, p0, p5, p2, p7, 17, 49, 36, 39); \
    TFBIG_MIX8(p6, p1, p0, p7, p2, p5, p4, p3, 44,  9, 54, 56); \
  } while (0)

#define TFBIG_4o(s)   do { \
    TFBIG_ADDKEY(p0, p1, p2, p3, p4, p5, p6, p7, h, t, s); \
    TFBIG_MIX8(p0, p1, p2, p3, p4, p5, p6, p7, 39, 30, 34, 24); \
    TFBIG_MIX8(p2, p1, p4, p7, p6, p5, p0, p3, 13, 50, 10, 17); \
    TFBIG_MIX8(p4, p1, p6, p3, p0, p5, p2, p7, 25, 29, 39, 43); \
    TFBIG_MIX8(p6, p1, p0, p7, p2, p5, p4, p3,  8, 35, 56, 22); \
  } while (0)

#define UBI_BIG(etype, extra)  do { \
    sph_u64 h8, t0, t1, t2; \
    sph_u64 p0 = m0; \
    sph_u64 p1 = m1; \
    sph_u64 p2 = m2; \
    sph_u64 p3 = m3; \
    sph_u64 p4 = m4; \
    sph_u64 p5 = m5; \
    sph_u64 p6 = m6; \
    sph_u64 p7 = m7; \
    t0 = SPH_T64(bcount << 6) + (sph_u64)(extra); \
    t1 = (bcount >> 58) + ((sph_u64)(etype) << 55); \
    TFBIG_KINIT(h0, h1, h2, h3, h4, h5, h6, h7, h8, t0, t1, t2); \
    TFBIG_4e(0); \
    TFBIG_4o(1); \
    TFBIG_4e(2); \
    TFBIG_4o(3); \
    TFBIG_4e(4); \
    TFBIG_4o(5); \
    TFBIG_4e(6); \
    TFBIG_4o(7); \
    TFBIG_4e(8); \
    TFBIG_4o(9); \
    TFBIG_4e(10); \
    TFBIG_4o(11); \
    TFBIG_4e(12); \
    TFBIG_4o(13); \
    TFBIG_4e(14); \
    TFBIG_4o(15); \
    TFBIG_4e(16); \
    TFBIG_4o(17); \
    TFBIG_ADDKEY(p0, p1, p2, p3, p4, p5, p6, p7, h, t, 18); \
    h0 = m0 ^ p0; \
    h1 = m1 ^ p1; \
    h2 = m2 ^ p2; \
    h3 = m3 ^ p3; \
    h4 = m4 ^ p4; \
    h5 = m5 ^ p5; \
    h6 = m6 ^ p6; \
    h7 = m7 ^ p7; \
  } while (0)

__constant const sph_u64 SKEIN_IV512[] = {
  SPH_C64(0x4903ADFF749C51CE), SPH_C64(0x0D95DE399746DF03),
  SPH_C64(0x8FD1934127C79BCE), SPH_C64(0x9A255629FF352CB1),
  SPH_C64(0x5DB62599DF6CA7B0), SPH_C64(0xEABE394CA9D5C3F4),
  SPH_C64(0x991112C71A75B523), SPH_C64(0xAE18A40B660FCC33)
};

/* $Id: luffa.c 219 2010-06-08 17:24:41Z tp $ */
/*
 * Luffa implementation.
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

#ifdef __cplusplus
extern "C"{
#endif

#if SPH_64_TRUE && !defined SPH_LUFFA_PARALLEL
#define SPH_LUFFA_PARALLEL   1
#endif

__constant const sph_u32 V_INIT[5][8] = {
  {
    SPH_C32(0x6d251e69), SPH_C32(0x44b051e0),
    SPH_C32(0x4eaa6fb4), SPH_C32(0xdbf78465),
    SPH_C32(0x6e292011), SPH_C32(0x90152df4),
    SPH_C32(0xee058139), SPH_C32(0xdef610bb)
  }, {
    SPH_C32(0xc3b44b95), SPH_C32(0xd9d2f256),
    SPH_C32(0x70eee9a0), SPH_C32(0xde099fa3),
    SPH_C32(0x5d9b0557), SPH_C32(0x8fc944b3),
    SPH_C32(0xcf1ccf0e), SPH_C32(0x746cd581)
  }, {
    SPH_C32(0xf7efc89d), SPH_C32(0x5dba5781),
    SPH_C32(0x04016ce5), SPH_C32(0xad659c05),
    SPH_C32(0x0306194f), SPH_C32(0x666d1836),
    SPH_C32(0x24aa230a), SPH_C32(0x8b264ae7)
  }, {
    SPH_C32(0x858075d5), SPH_C32(0x36d79cce),
    SPH_C32(0xe571f7d7), SPH_C32(0x204b1f67),
    SPH_C32(0x35870c6a), SPH_C32(0x57e9e923),
    SPH_C32(0x14bcb808), SPH_C32(0x7cde72ce)
  }, {
    SPH_C32(0x6c68e9be), SPH_C32(0x5ec41e22),
    SPH_C32(0xc825b7c7), SPH_C32(0xaffb4363),
    SPH_C32(0xf5df3999), SPH_C32(0x0fc688f1),
    SPH_C32(0xb07224cc), SPH_C32(0x03e86cea)
  }
};

__constant const sph_u32 RC00[8] = {
  SPH_C32(0x303994a6), SPH_C32(0xc0e65299),
  SPH_C32(0x6cc33a12), SPH_C32(0xdc56983e),
  SPH_C32(0x1e00108f), SPH_C32(0x7800423d),
  SPH_C32(0x8f5b7882), SPH_C32(0x96e1db12)
};

__constant const sph_u32 RC04[8] = {
  SPH_C32(0xe0337818), SPH_C32(0x441ba90d),
  SPH_C32(0x7f34d442), SPH_C32(0x9389217f),
  SPH_C32(0xe5a8bce6), SPH_C32(0x5274baf4),
  SPH_C32(0x26889ba7), SPH_C32(0x9a226e9d)
};

__constant const sph_u32 RC10[8] = {
  SPH_C32(0xb6de10ed), SPH_C32(0x70f47aae),
  SPH_C32(0x0707a3d4), SPH_C32(0x1c1e8f51),
  SPH_C32(0x707a3d45), SPH_C32(0xaeb28562),
  SPH_C32(0xbaca1589), SPH_C32(0x40a46f3e)
};

__constant const sph_u32 RC14[8] = {
  SPH_C32(0x01685f3d), SPH_C32(0x05a17cf4),
  SPH_C32(0xbd09caca), SPH_C32(0xf4272b28),
  SPH_C32(0x144ae5cc), SPH_C32(0xfaa7ae2b),
  SPH_C32(0x2e48f1c1), SPH_C32(0xb923c704)
};

#if SPH_LUFFA_PARALLEL

__constant const sph_u64 RCW010[8] = {
  SPH_C64(0xb6de10ed303994a6), SPH_C64(0x70f47aaec0e65299),
  SPH_C64(0x0707a3d46cc33a12), SPH_C64(0x1c1e8f51dc56983e),
  SPH_C64(0x707a3d451e00108f), SPH_C64(0xaeb285627800423d),
  SPH_C64(0xbaca15898f5b7882), SPH_C64(0x40a46f3e96e1db12)
};

__constant const sph_u64 RCW014[8] = {
  SPH_C64(0x01685f3de0337818), SPH_C64(0x05a17cf4441ba90d),
  SPH_C64(0xbd09caca7f34d442), SPH_C64(0xf4272b289389217f),
  SPH_C64(0x144ae5cce5a8bce6), SPH_C64(0xfaa7ae2b5274baf4),
  SPH_C64(0x2e48f1c126889ba7), SPH_C64(0xb923c7049a226e9d)
};

#endif

__constant const sph_u32 RC20[8] = {
  SPH_C32(0xfc20d9d2), SPH_C32(0x34552e25),
  SPH_C32(0x7ad8818f), SPH_C32(0x8438764a),
  SPH_C32(0xbb6de032), SPH_C32(0xedb780c8),
  SPH_C32(0xd9847356), SPH_C32(0xa2c78434)
};

__constant const sph_u32 RC24[8] = {
  SPH_C32(0xe25e72c1), SPH_C32(0xe623bb72),
  SPH_C32(0x5c58a4a4), SPH_C32(0x1e38e2e7),
  SPH_C32(0x78e38b9d), SPH_C32(0x27586719),
  SPH_C32(0x36eda57f), SPH_C32(0x703aace7)
};

__constant const sph_u32 RC30[8] = {
  SPH_C32(0xb213afa5), SPH_C32(0xc84ebe95),
  SPH_C32(0x4e608a22), SPH_C32(0x56d858fe),
  SPH_C32(0x343b138f), SPH_C32(0xd0ec4e3d),
  SPH_C32(0x2ceb4882), SPH_C32(0xb3ad2208)
};

__constant const sph_u32 RC34[8] = {
  SPH_C32(0xe028c9bf), SPH_C32(0x44756f91),
  SPH_C32(0x7e8fce32), SPH_C32(0x956548be),
  SPH_C32(0xfe191be2), SPH_C32(0x3cb226e5),
  SPH_C32(0x5944a28e), SPH_C32(0xa1c4c355)
};

#if SPH_LUFFA_PARALLEL

__constant const sph_u64 RCW230[8] = {
  SPH_C64(0xb213afa5fc20d9d2), SPH_C64(0xc84ebe9534552e25),
  SPH_C64(0x4e608a227ad8818f), SPH_C64(0x56d858fe8438764a),
  SPH_C64(0x343b138fbb6de032), SPH_C64(0xd0ec4e3dedb780c8),
  SPH_C64(0x2ceb4882d9847356), SPH_C64(0xb3ad2208a2c78434)
};


__constant const sph_u64 RCW234[8] = {
  SPH_C64(0xe028c9bfe25e72c1), SPH_C64(0x44756f91e623bb72),
  SPH_C64(0x7e8fce325c58a4a4), SPH_C64(0x956548be1e38e2e7),
  SPH_C64(0xfe191be278e38b9d), SPH_C64(0x3cb226e527586719),
  SPH_C64(0x5944a28e36eda57f), SPH_C64(0xa1c4c355703aace7)
};

#endif

__constant const sph_u32 RC40[8] = {
  SPH_C32(0xf0d2e9e3), SPH_C32(0xac11d7fa),
  SPH_C32(0x1bcb66f2), SPH_C32(0x6f2d9bc9),
  SPH_C32(0x78602649), SPH_C32(0x8edae952),
  SPH_C32(0x3b6ba548), SPH_C32(0xedae9520)
};

__constant const sph_u32 RC44[8] = {
  SPH_C32(0x5090d577), SPH_C32(0x2d1925ab),
  SPH_C32(0xb46496ac), SPH_C32(0xd1925ab0),
  SPH_C32(0x29131ab6), SPH_C32(0x0fc053c3),
  SPH_C32(0x3f014f0c), SPH_C32(0xfc053c31)
};

#define DECL_TMP8(w) \
  sph_u32 w ## 0, w ## 1, w ## 2, w ## 3, w ## 4, w ## 5, w ## 6, w ## 7;

#define M2(d, s)   do { \
    sph_u32 tmp = s ## 7; \
    d ## 7 = s ## 6; \
    d ## 6 = s ## 5; \
    d ## 5 = s ## 4; \
    d ## 4 = s ## 3 ^ tmp; \
    d ## 3 = s ## 2 ^ tmp; \
    d ## 2 = s ## 1; \
    d ## 1 = s ## 0 ^ tmp; \
    d ## 0 = tmp; \
  } while (0)

#define XOR(d, s1, s2)   do { \
    d ## 0 = s1 ## 0 ^ s2 ## 0; \
    d ## 1 = s1 ## 1 ^ s2 ## 1; \
    d ## 2 = s1 ## 2 ^ s2 ## 2; \
    d ## 3 = s1 ## 3 ^ s2 ## 3; \
    d ## 4 = s1 ## 4 ^ s2 ## 4; \
    d ## 5 = s1 ## 5 ^ s2 ## 5; \
    d ## 6 = s1 ## 6 ^ s2 ## 6; \
    d ## 7 = s1 ## 7 ^ s2 ## 7; \
  } while (0)

#if SPH_LUFFA_PARALLEL

#define SUB_CRUMB_GEN(a0, a1, a2, a3, width)   do { \
    sph_u ## width tmp; \
    tmp = (a0); \
    (a0) |= (a1); \
    (a2) ^= (a3); \
    (a1) = SPH_T ## width(~(a1)); \
    (a0) ^= (a3); \
    (a3) &= tmp; \
    (a1) ^= (a3); \
    (a3) ^= (a2); \
    (a2) &= (a0); \
    (a0) = SPH_T ## width(~(a0)); \
    (a2) ^= (a1); \
    (a1) |= (a3); \
    tmp ^= (a1); \
    (a3) ^= (a2); \
    (a2) &= (a1); \
    (a1) ^= (a0); \
    (a0) = tmp; \
  } while (0)

#define SUB_CRUMB(a0, a1, a2, a3)    SUB_CRUMB_GEN(a0, a1, a2, a3, 32)
#define SUB_CRUMBW(a0, a1, a2, a3)   SUB_CRUMB_GEN(a0, a1, a2, a3, 64)

#define MIX_WORDW(u, v)   do { \
    sph_u32 ul, uh, vl, vh; \
    (v) ^= (u); \
    ul = SPH_T32((sph_u32)(u)); \
    uh = SPH_T32((sph_u32)((u) >> 32)); \
    vl = SPH_T32((sph_u32)(v)); \
    vh = SPH_T32((sph_u32)((v) >> 32)); \
    ul = SPH_ROTL32(ul, 2) ^ vl; \
    vl = SPH_ROTL32(vl, 14) ^ ul; \
    ul = SPH_ROTL32(ul, 10) ^ vl; \
    vl = SPH_ROTL32(vl, 1); \
    uh = SPH_ROTL32(uh, 2) ^ vh; \
    vh = SPH_ROTL32(vh, 14) ^ uh; \
    uh = SPH_ROTL32(uh, 10) ^ vh; \
    vh = SPH_ROTL32(vh, 1); \
    (u) = (sph_u64)ul | ((sph_u64)uh << 32); \
    (v) = (sph_u64)vl | ((sph_u64)vh << 32); \
  } while (0)

#else

#define SUB_CRUMB(a0, a1, a2, a3)   do { \
    sph_u32 tmp; \
    tmp = (a0); \
    (a0) |= (a1); \
    (a2) ^= (a3); \
    (a1) = SPH_T32(~(a1)); \
    (a0) ^= (a3); \
    (a3) &= tmp; \
    (a1) ^= (a3); \
    (a3) ^= (a2); \
    (a2) &= (a0); \
    (a0) = SPH_T32(~(a0)); \
    (a2) ^= (a1); \
    (a1) |= (a3); \
    tmp ^= (a1); \
    (a3) ^= (a2); \
    (a2) &= (a1); \
    (a1) ^= (a0); \
    (a0) = tmp; \
  } while (0)

#endif

#define MIX_WORD(u, v)   do { \
    (v) ^= (u); \
    (u) = SPH_ROTL32((u), 2) ^ (v); \
    (v) = SPH_ROTL32((v), 14) ^ (u); \
    (u) = SPH_ROTL32((u), 10) ^ (v); \
    (v) = SPH_ROTL32((v), 1); \
  } while (0)

#define MI5   do { \
    DECL_TMP8(a) \
    DECL_TMP8(b) \
    XOR(a, V0, V1); \
    XOR(b, V2, V3); \
    XOR(a, a, b); \
    XOR(a, a, V4); \
    M2(a, a); \
    XOR(V0, a, V0); \
    XOR(V1, a, V1); \
    XOR(V2, a, V2); \
    XOR(V3, a, V3); \
    XOR(V4, a, V4); \
    M2(b, V0); \
    XOR(b, b, V1); \
    M2(V1, V1); \
    XOR(V1, V1, V2); \
    M2(V2, V2); \
    XOR(V2, V2, V3); \
    M2(V3, V3); \
    XOR(V3, V3, V4); \
    M2(V4, V4); \
    XOR(V4, V4, V0); \
    M2(V0, b); \
    XOR(V0, V0, V4); \
    M2(V4, V4); \
    XOR(V4, V4, V3); \
    M2(V3, V3); \
    XOR(V3, V3, V2); \
    M2(V2, V2); \
    XOR(V2, V2, V1); \
    M2(V1, V1); \
    XOR(V1, V1, b); \
    XOR(V0, V0, M); \
    M2(M, M); \
    XOR(V1, V1, M); \
    M2(M, M); \
    XOR(V2, V2, M); \
    M2(M, M); \
    XOR(V3, V3, M); \
    M2(M, M); \
    XOR(V4, V4, M); \
  } while (0)

#define TWEAK5   do { \
    V14 = SPH_ROTL32(V14, 1); \
    V15 = SPH_ROTL32(V15, 1); \
    V16 = SPH_ROTL32(V16, 1); \
    V17 = SPH_ROTL32(V17, 1); \
    V24 = SPH_ROTL32(V24, 2); \
    V25 = SPH_ROTL32(V25, 2); \
    V26 = SPH_ROTL32(V26, 2); \
    V27 = SPH_ROTL32(V27, 2); \
    V34 = SPH_ROTL32(V34, 3); \
    V35 = SPH_ROTL32(V35, 3); \
    V36 = SPH_ROTL32(V36, 3); \
    V37 = SPH_ROTL32(V37, 3); \
    V44 = SPH_ROTL32(V44, 4); \
    V45 = SPH_ROTL32(V45, 4); \
    V46 = SPH_ROTL32(V46, 4); \
    V47 = SPH_ROTL32(V47, 4); \
  } while (0)

#if SPH_LUFFA_PARALLEL

#define LUFFA_P5   do { \
    int r; \
    sph_u64 W0, W1, W2, W3, W4, W5, W6, W7; \
    TWEAK5; \
    W0 = (sph_u64)V00 | ((sph_u64)V10 << 32); \
    W1 = (sph_u64)V01 | ((sph_u64)V11 << 32); \
    W2 = (sph_u64)V02 | ((sph_u64)V12 << 32); \
    W3 = (sph_u64)V03 | ((sph_u64)V13 << 32); \
    W4 = (sph_u64)V04 | ((sph_u64)V14 << 32); \
    W5 = (sph_u64)V05 | ((sph_u64)V15 << 32); \
    W6 = (sph_u64)V06 | ((sph_u64)V16 << 32); \
    W7 = (sph_u64)V07 | ((sph_u64)V17 << 32); \
    for (r = 0; r < 8; r ++) { \
      SUB_CRUMBW(W0, W1, W2, W3); \
      SUB_CRUMBW(W5, W6, W7, W4); \
      MIX_WORDW(W0, W4); \
      MIX_WORDW(W1, W5); \
      MIX_WORDW(W2, W6); \
      MIX_WORDW(W3, W7); \
      W0 ^= RCW010[r]; \
      W4 ^= RCW014[r]; \
    } \
    V00 = SPH_T32((sph_u32)W0); \
    V10 = SPH_T32((sph_u32)(W0 >> 32)); \
    V01 = SPH_T32((sph_u32)W1); \
    V11 = SPH_T32((sph_u32)(W1 >> 32)); \
    V02 = SPH_T32((sph_u32)W2); \
    V12 = SPH_T32((sph_u32)(W2 >> 32)); \
    V03 = SPH_T32((sph_u32)W3); \
    V13 = SPH_T32((sph_u32)(W3 >> 32)); \
    V04 = SPH_T32((sph_u32)W4); \
    V14 = SPH_T32((sph_u32)(W4 >> 32)); \
    V05 = SPH_T32((sph_u32)W5); \
    V15 = SPH_T32((sph_u32)(W5 >> 32)); \
    V06 = SPH_T32((sph_u32)W6); \
    V16 = SPH_T32((sph_u32)(W6 >> 32)); \
    V07 = SPH_T32((sph_u32)W7); \
    V17 = SPH_T32((sph_u32)(W7 >> 32)); \
    W0 = (sph_u64)V20 | ((sph_u64)V30 << 32); \
    W1 = (sph_u64)V21 | ((sph_u64)V31 << 32); \
    W2 = (sph_u64)V22 | ((sph_u64)V32 << 32); \
    W3 = (sph_u64)V23 | ((sph_u64)V33 << 32); \
    W4 = (sph_u64)V24 | ((sph_u64)V34 << 32); \
    W5 = (sph_u64)V25 | ((sph_u64)V35 << 32); \
    W6 = (sph_u64)V26 | ((sph_u64)V36 << 32); \
    W7 = (sph_u64)V27 | ((sph_u64)V37 << 32); \
    for (r = 0; r < 8; r ++) { \
      SUB_CRUMBW(W0, W1, W2, W3); \
      SUB_CRUMBW(W5, W6, W7, W4); \
      MIX_WORDW(W0, W4); \
      MIX_WORDW(W1, W5); \
      MIX_WORDW(W2, W6); \
      MIX_WORDW(W3, W7); \
      W0 ^= RCW230[r]; \
      W4 ^= RCW234[r]; \
    } \
    V20 = SPH_T32((sph_u32)W0); \
    V30 = SPH_T32((sph_u32)(W0 >> 32)); \
    V21 = SPH_T32((sph_u32)W1); \
    V31 = SPH_T32((sph_u32)(W1 >> 32)); \
    V22 = SPH_T32((sph_u32)W2); \
    V32 = SPH_T32((sph_u32)(W2 >> 32)); \
    V23 = SPH_T32((sph_u32)W3); \
    V33 = SPH_T32((sph_u32)(W3 >> 32)); \
    V24 = SPH_T32((sph_u32)W4); \
    V34 = SPH_T32((sph_u32)(W4 >> 32)); \
    V25 = SPH_T32((sph_u32)W5); \
    V35 = SPH_T32((sph_u32)(W5 >> 32)); \
    V26 = SPH_T32((sph_u32)W6); \
    V36 = SPH_T32((sph_u32)(W6 >> 32)); \
    V27 = SPH_T32((sph_u32)W7); \
    V37 = SPH_T32((sph_u32)(W7 >> 32)); \
    for (r = 0; r < 8; r ++) { \
      SUB_CRUMB(V40, V41, V42, V43); \
      SUB_CRUMB(V45, V46, V47, V44); \
      MIX_WORD(V40, V44); \
      MIX_WORD(V41, V45); \
      MIX_WORD(V42, V46); \
      MIX_WORD(V43, V47); \
      V40 ^= RC40[r]; \
      V44 ^= RC44[r]; \
    } \
  } while (0)

#else

#define LUFFA_P5   do { \
    int r; \
    TWEAK5; \
    for (r = 0; r < 8; r ++) { \
      SUB_CRUMB(V00, V01, V02, V03); \
      SUB_CRUMB(V05, V06, V07, V04); \
      MIX_WORD(V00, V04); \
      MIX_WORD(V01, V05); \
      MIX_WORD(V02, V06); \
      MIX_WORD(V03, V07); \
      V00 ^= RC00[r]; \
      V04 ^= RC04[r]; \
    } \
    for (r = 0; r < 8; r ++) { \
      SUB_CRUMB(V10, V11, V12, V13); \
      SUB_CRUMB(V15, V16, V17, V14); \
      MIX_WORD(V10, V14); \
      MIX_WORD(V11, V15); \
      MIX_WORD(V12, V16); \
      MIX_WORD(V13, V17); \
      V10 ^= RC10[r]; \
      V14 ^= RC14[r]; \
    } \
    for (r = 0; r < 8; r ++) { \
      SUB_CRUMB(V20, V21, V22, V23); \
      SUB_CRUMB(V25, V26, V27, V24); \
      MIX_WORD(V20, V24); \
      MIX_WORD(V21, V25); \
      MIX_WORD(V22, V26); \
      MIX_WORD(V23, V27); \
      V20 ^= RC20[r]; \
      V24 ^= RC24[r]; \
    } \
    for (r = 0; r < 8; r ++) { \
      SUB_CRUMB(V30, V31, V32, V33); \
      SUB_CRUMB(V35, V36, V37, V34); \
      MIX_WORD(V30, V34); \
      MIX_WORD(V31, V35); \
      MIX_WORD(V32, V36); \
      MIX_WORD(V33, V37); \
      V30 ^= RC30[r]; \
      V34 ^= RC34[r]; \
    } \
    for (r = 0; r < 8; r ++) { \
      SUB_CRUMB(V40, V41, V42, V43); \
      SUB_CRUMB(V45, V46, V47, V44); \
      MIX_WORD(V40, V44); \
      MIX_WORD(V41, V45); \
      MIX_WORD(V42, V46); \
      MIX_WORD(V43, V47); \
      V40 ^= RC40[r]; \
      V44 ^= RC44[r]; \
    } \
  } while (0)

#endif

/* $Id: cubehash.c 227 2010-06-16 17:28:38Z tp $ */
/*
 * CubeHash implementation.
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

/*
 * Some tests were conducted on an Intel Core2 Q6600 (32-bit and 64-bit
 * mode), a PowerPC G3, and a MIPS-compatible CPU (Broadcom BCM3302).
 * It appears that the optimal settings are:
 *  -- full unroll, no state copy on the "big" systems (x86, PowerPC)
 *  -- unroll to 4 or 8, state copy on the "small" system (MIPS)
 */

#if !defined SPH_CUBEHASH_UNROLL
#define SPH_CUBEHASH_UNROLL   0
#endif

__constant const sph_u32 CUBEHASH_IV512[] = {
  SPH_C32(0x2AEA2A61), SPH_C32(0x50F494D4), SPH_C32(0x2D538B8B),
  SPH_C32(0x4167D83E), SPH_C32(0x3FEE2313), SPH_C32(0xC701CF8C),
  SPH_C32(0xCC39968E), SPH_C32(0x50AC5695), SPH_C32(0x4D42C787),
  SPH_C32(0xA647A8B3), SPH_C32(0x97CF0BEF), SPH_C32(0x825B4537),
  SPH_C32(0xEEF864D2), SPH_C32(0xF22090C4), SPH_C32(0xD0E5CD33),
  SPH_C32(0xA23911AE), SPH_C32(0xFCD398D9), SPH_C32(0x148FE485),
  SPH_C32(0x1B017BEF), SPH_C32(0xB6444532), SPH_C32(0x6A536159),
  SPH_C32(0x2FF5781C), SPH_C32(0x91FA7934), SPH_C32(0x0DBADEA9),
  SPH_C32(0xD65C8A2B), SPH_C32(0xA5A70E75), SPH_C32(0xB1C62456),
  SPH_C32(0xBC796576), SPH_C32(0x1921C8F7), SPH_C32(0xE7989AF1),
  SPH_C32(0x7795D246), SPH_C32(0xD43E3B44)
};

#define T32      SPH_T32
#define ROTL32   SPH_ROTL32

#define ROUND_EVEN   do { \
    xg = T32(x0 + xg); \
    x0 = ROTL32(x0, 7); \
    xh = T32(x1 + xh); \
    x1 = ROTL32(x1, 7); \
    xi = T32(x2 + xi); \
    x2 = ROTL32(x2, 7); \
    xj = T32(x3 + xj); \
    x3 = ROTL32(x3, 7); \
    xk = T32(x4 + xk); \
    x4 = ROTL32(x4, 7); \
    xl = T32(x5 + xl); \
    x5 = ROTL32(x5, 7); \
    xm = T32(x6 + xm); \
    x6 = ROTL32(x6, 7); \
    xn = T32(x7 + xn); \
    x7 = ROTL32(x7, 7); \
    xo = T32(x8 + xo); \
    x8 = ROTL32(x8, 7); \
    xp = T32(x9 + xp); \
    x9 = ROTL32(x9, 7); \
    xq = T32(xa + xq); \
    xa = ROTL32(xa, 7); \
    xr = T32(xb + xr); \
    xb = ROTL32(xb, 7); \
    xs = T32(xc + xs); \
    xc = ROTL32(xc, 7); \
    xt = T32(xd + xt); \
    xd = ROTL32(xd, 7); \
    xu = T32(xe + xu); \
    xe = ROTL32(xe, 7); \
    xv = T32(xf + xv); \
    xf = ROTL32(xf, 7); \
    x8 ^= xg; \
    x9 ^= xh; \
    xa ^= xi; \
    xb ^= xj; \
    xc ^= xk; \
    xd ^= xl; \
    xe ^= xm; \
    xf ^= xn; \
    x0 ^= xo; \
    x1 ^= xp; \
    x2 ^= xq; \
    x3 ^= xr; \
    x4 ^= xs; \
    x5 ^= xt; \
    x6 ^= xu; \
    x7 ^= xv; \
    xi = T32(x8 + xi); \
    x8 = ROTL32(x8, 11); \
    xj = T32(x9 + xj); \
    x9 = ROTL32(x9, 11); \
    xg = T32(xa + xg); \
    xa = ROTL32(xa, 11); \
    xh = T32(xb + xh); \
    xb = ROTL32(xb, 11); \
    xm = T32(xc + xm); \
    xc = ROTL32(xc, 11); \
    xn = T32(xd + xn); \
    xd = ROTL32(xd, 11); \
    xk = T32(xe + xk); \
    xe = ROTL32(xe, 11); \
    xl = T32(xf + xl); \
    xf = ROTL32(xf, 11); \
    xq = T32(x0 + xq); \
    x0 = ROTL32(x0, 11); \
    xr = T32(x1 + xr); \
    x1 = ROTL32(x1, 11); \
    xo = T32(x2 + xo); \
    x2 = ROTL32(x2, 11); \
    xp = T32(x3 + xp); \
    x3 = ROTL32(x3, 11); \
    xu = T32(x4 + xu); \
    x4 = ROTL32(x4, 11); \
    xv = T32(x5 + xv); \
    x5 = ROTL32(x5, 11); \
    xs = T32(x6 + xs); \
    x6 = ROTL32(x6, 11); \
    xt = T32(x7 + xt); \
    x7 = ROTL32(x7, 11); \
    xc ^= xi; \
    xd ^= xj; \
    xe ^= xg; \
    xf ^= xh; \
    x8 ^= xm; \
    x9 ^= xn; \
    xa ^= xk; \
    xb ^= xl; \
    x4 ^= xq; \
    x5 ^= xr; \
    x6 ^= xo; \
    x7 ^= xp; \
    x0 ^= xu; \
    x1 ^= xv; \
    x2 ^= xs; \
    x3 ^= xt; \
  } while (0)

#define ROUND_ODD   do { \
    xj = T32(xc + xj); \
    xc = ROTL32(xc, 7); \
    xi = T32(xd + xi); \
    xd = ROTL32(xd, 7); \
    xh = T32(xe + xh); \
    xe = ROTL32(xe, 7); \
    xg = T32(xf + xg); \
    xf = ROTL32(xf, 7); \
    xn = T32(x8 + xn); \
    x8 = ROTL32(x8, 7); \
    xm = T32(x9 + xm); \
    x9 = ROTL32(x9, 7); \
    xl = T32(xa + xl); \
    xa = ROTL32(xa, 7); \
    xk = T32(xb + xk); \
    xb = ROTL32(xb, 7); \
    xr = T32(x4 + xr); \
    x4 = ROTL32(x4, 7); \
    xq = T32(x5 + xq); \
    x5 = ROTL32(x5, 7); \
    xp = T32(x6 + xp); \
    x6 = ROTL32(x6, 7); \
    xo = T32(x7 + xo); \
    x7 = ROTL32(x7, 7); \
    xv = T32(x0 + xv); \
    x0 = ROTL32(x0, 7); \
    xu = T32(x1 + xu); \
    x1 = ROTL32(x1, 7); \
    xt = T32(x2 + xt); \
    x2 = ROTL32(x2, 7); \
    xs = T32(x3 + xs); \
    x3 = ROTL32(x3, 7); \
    x4 ^= xj; \
    x5 ^= xi; \
    x6 ^= xh; \
    x7 ^= xg; \
    x0 ^= xn; \
    x1 ^= xm; \
    x2 ^= xl; \
    x3 ^= xk; \
    xc ^= xr; \
    xd ^= xq; \
    xe ^= xp; \
    xf ^= xo; \
    x8 ^= xv; \
    x9 ^= xu; \
    xa ^= xt; \
    xb ^= xs; \
    xh = T32(x4 + xh); \
    x4 = ROTL32(x4, 11); \
    xg = T32(x5 + xg); \
    x5 = ROTL32(x5, 11); \
    xj = T32(x6 + xj); \
    x6 = ROTL32(x6, 11); \
    xi = T32(x7 + xi); \
    x7 = ROTL32(x7, 11); \
    xl = T32(x0 + xl); \
    x0 = ROTL32(x0, 11); \
    xk = T32(x1 + xk); \
    x1 = ROTL32(x1, 11); \
    xn = T32(x2 + xn); \
    x2 = ROTL32(x2, 11); \
    xm = T32(x3 + xm); \
    x3 = ROTL32(x3, 11); \
    xp = T32(xc + xp); \
    xc = ROTL32(xc, 11); \
    xo = T32(xd + xo); \
    xd = ROTL32(xd, 11); \
    xr = T32(xe + xr); \
    xe = ROTL32(xe, 11); \
    xq = T32(xf + xq); \
    xf = ROTL32(xf, 11); \
    xt = T32(x8 + xt); \
    x8 = ROTL32(x8, 11); \
    xs = T32(x9 + xs); \
    x9 = ROTL32(x9, 11); \
    xv = T32(xa + xv); \
    xa = ROTL32(xa, 11); \
    xu = T32(xb + xu); \
    xb = ROTL32(xb, 11); \
    x0 ^= xh; \
    x1 ^= xg; \
    x2 ^= xj; \
    x3 ^= xi; \
    x4 ^= xl; \
    x5 ^= xk; \
    x6 ^= xn; \
    x7 ^= xm; \
    x8 ^= xp; \
    x9 ^= xo; \
    xa ^= xr; \
    xb ^= xq; \
    xc ^= xt; \
    xd ^= xs; \
    xe ^= xv; \
    xf ^= xu; \
  } while (0)

/*
 * There is no need to unroll all 16 rounds. The word-swapping permutation
 * is an involution, so we need to unroll an even number of rounds. On
 * "big" systems, unrolling 4 rounds yields about 97% of the speed
 * achieved with full unrolling; and it keeps the code more compact
 * for small architectures.
 */

#if SPH_CUBEHASH_UNROLL == 2

#define SIXTEEN_ROUNDS   do { \
    int j; \
    for (j = 0; j < 8; j ++) { \
      ROUND_EVEN; \
      ROUND_ODD; \
    } \
  } while (0)

#elif SPH_CUBEHASH_UNROLL == 4

#define SIXTEEN_ROUNDS   do { \
    int j; \
    for (j = 0; j < 4; j ++) { \
      ROUND_EVEN; \
      ROUND_ODD; \
      ROUND_EVEN; \
      ROUND_ODD; \
    } \
  } while (0)

#elif SPH_CUBEHASH_UNROLL == 8

#define SIXTEEN_ROUNDS   do { \
    int j; \
    for (j = 0; j < 2; j ++) { \
      ROUND_EVEN; \
      ROUND_ODD; \
      ROUND_EVEN; \
      ROUND_ODD; \
      ROUND_EVEN; \
      ROUND_ODD; \
      ROUND_EVEN; \
      ROUND_ODD; \
    } \
  } while (0)

#else

#define SIXTEEN_ROUNDS   do { \
    ROUND_EVEN; \
    ROUND_ODD; \
    ROUND_EVEN; \
    ROUND_ODD; \
    ROUND_EVEN; \
    ROUND_ODD; \
    ROUND_EVEN; \
    ROUND_ODD; \
    ROUND_EVEN; \
    ROUND_ODD; \
    ROUND_EVEN; \
    ROUND_ODD; \
    ROUND_EVEN; \
    ROUND_ODD; \
    ROUND_EVEN; \
    ROUND_ODD; \
  } while (0)

#endif

/* $Id: shavite.c 227 2010-06-16 17:28:38Z tp $ */
/*
 * SHAvite-3 implementation.
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

/*
 * As of round 2 of the SHA-3 competition, the published reference
 * implementation and test vectors are wrong, because they use
 * big-endian AES tables while the internal decoding uses little-endian.
 * The code below follows the specification. To turn it into a code
 * which follows the reference implementation (the one called "BugFix"
 * on the SHAvite-3 web site, published on Nov 23rd, 2009), comment out
 * the code below (from the '#define AES_BIG_ENDIAN...' to the definition
 * of the AES_ROUND_NOKEY macro) and replace it with the version which
 * is commented out afterwards.
 */

#define AES_BIG_ENDIAN   0

#define AES_ROUND_NOKEY(x0, x1, x2, x3)   do { \
    sph_u32 t0 = (x0); \
    sph_u32 t1 = (x1); \
    sph_u32 t2 = (x2); \
    sph_u32 t3 = (x3); \
    AES_ROUND_NOKEY_LE(t0, t1, t2, t3, x0, x1, x2, x3); \
  } while (0)

#define KEY_EXPAND_ELT(k0, k1, k2, k3)   do { \
    sph_u32 kt; \
    AES_ROUND_NOKEY(k1, k2, k3, k0); \
    kt = (k0); \
    (k0) = (k1); \
    (k1) = (k2); \
    (k2) = (k3); \
    (k3) = kt; \
  } while (0)

/*
 * This function assumes that "msg" is aligned for 32-bit access.
 */
#define c512(msg) do { \
  sph_u32 p0, p1, p2, p3, p4, p5, p6, p7; \
  sph_u32 p8, p9, pA, pB, pC, pD, pE, pF; \
  sph_u32 x0, x1, x2, x3; \
  int r; \
 \
  p0 = h0; \
  p1 = h1; \
  p2 = h2; \
  p3 = h3; \
  p4 = h4; \
  p5 = h5; \
  p6 = h6; \
  p7 = h7; \
  p8 = h8; \
  p9 = h9; \
  pA = hA; \
  pB = hB; \
  pC = hC; \
  pD = hD; \
  pE = hE; \
  pF = hF; \
  /* round 0 */ \
  x0 = p4 ^ rk00; \
  x1 = p5 ^ rk01; \
  x2 = p6 ^ rk02; \
  x3 = p7 ^ rk03; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  x0 ^= rk04; \
  x1 ^= rk05; \
  x2 ^= rk06; \
  x3 ^= rk07; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  x0 ^= rk08; \
  x1 ^= rk09; \
  x2 ^= rk0A; \
  x3 ^= rk0B; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  x0 ^= rk0C; \
  x1 ^= rk0D; \
  x2 ^= rk0E; \
  x3 ^= rk0F; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p0 ^= x0; \
  p1 ^= x1; \
  p2 ^= x2; \
  p3 ^= x3; \
  x0 = pC ^ rk10; \
  x1 = pD ^ rk11; \
  x2 = pE ^ rk12; \
  x3 = pF ^ rk13; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  x0 ^= rk14; \
  x1 ^= rk15; \
  x2 ^= rk16; \
  x3 ^= rk17; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  x0 ^= rk18; \
  x1 ^= rk19; \
  x2 ^= rk1A; \
  x3 ^= rk1B; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  x0 ^= rk1C; \
  x1 ^= rk1D; \
  x2 ^= rk1E; \
  x3 ^= rk1F; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p8 ^= x0; \
  p9 ^= x1; \
  pA ^= x2; \
  pB ^= x3; \
 \
  for (r = 0; r < 3; r ++) { \
    /* round 1, 5, 9 */ \
    KEY_EXPAND_ELT(rk00, rk01, rk02, rk03); \
    rk00 ^= rk1C; \
    rk01 ^= rk1D; \
    rk02 ^= rk1E; \
    rk03 ^= rk1F; \
    if (r == 0) { \
      rk00 ^= sc_count0; \
      rk01 ^= sc_count1; \
      rk02 ^= sc_count2; \
      rk03 ^= SPH_T32(~sc_count3); \
    } \
    x0 = p0 ^ rk00; \
    x1 = p1 ^ rk01; \
    x2 = p2 ^ rk02; \
    x3 = p3 ^ rk03; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    KEY_EXPAND_ELT(rk04, rk05, rk06, rk07); \
    rk04 ^= rk00; \
    rk05 ^= rk01; \
    rk06 ^= rk02; \
    rk07 ^= rk03; \
    if (r == 1) { \
      rk04 ^= sc_count3; \
      rk05 ^= sc_count2; \
      rk06 ^= sc_count1; \
      rk07 ^= SPH_T32(~sc_count0); \
    } \
    x0 ^= rk04; \
    x1 ^= rk05; \
    x2 ^= rk06; \
    x3 ^= rk07; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    KEY_EXPAND_ELT(rk08, rk09, rk0A, rk0B); \
    rk08 ^= rk04; \
    rk09 ^= rk05; \
    rk0A ^= rk06; \
    rk0B ^= rk07; \
    x0 ^= rk08; \
    x1 ^= rk09; \
    x2 ^= rk0A; \
    x3 ^= rk0B; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    KEY_EXPAND_ELT(rk0C, rk0D, rk0E, rk0F); \
    rk0C ^= rk08; \
    rk0D ^= rk09; \
    rk0E ^= rk0A; \
    rk0F ^= rk0B; \
    x0 ^= rk0C; \
    x1 ^= rk0D; \
    x2 ^= rk0E; \
    x3 ^= rk0F; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    pC ^= x0; \
    pD ^= x1; \
    pE ^= x2; \
    pF ^= x3; \
    KEY_EXPAND_ELT(rk10, rk11, rk12, rk13); \
    rk10 ^= rk0C; \
    rk11 ^= rk0D; \
    rk12 ^= rk0E; \
    rk13 ^= rk0F; \
    x0 = p8 ^ rk10; \
    x1 = p9 ^ rk11; \
    x2 = pA ^ rk12; \
    x3 = pB ^ rk13; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    KEY_EXPAND_ELT(rk14, rk15, rk16, rk17); \
    rk14 ^= rk10; \
    rk15 ^= rk11; \
    rk16 ^= rk12; \
    rk17 ^= rk13; \
    x0 ^= rk14; \
    x1 ^= rk15; \
    x2 ^= rk16; \
    x3 ^= rk17; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    KEY_EXPAND_ELT(rk18, rk19, rk1A, rk1B); \
    rk18 ^= rk14; \
    rk19 ^= rk15; \
    rk1A ^= rk16; \
    rk1B ^= rk17; \
    x0 ^= rk18; \
    x1 ^= rk19; \
    x2 ^= rk1A; \
    x3 ^= rk1B; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    KEY_EXPAND_ELT(rk1C, rk1D, rk1E, rk1F); \
    rk1C ^= rk18; \
    rk1D ^= rk19; \
    rk1E ^= rk1A; \
    rk1F ^= rk1B; \
    if (r == 2) { \
      rk1C ^= sc_count2; \
      rk1D ^= sc_count3; \
      rk1E ^= sc_count0; \
      rk1F ^= SPH_T32(~sc_count1); \
    } \
    x0 ^= rk1C; \
    x1 ^= rk1D; \
    x2 ^= rk1E; \
    x3 ^= rk1F; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    p4 ^= x0; \
    p5 ^= x1; \
    p6 ^= x2; \
    p7 ^= x3; \
    /* round 2, 6, 10 */ \
    rk00 ^= rk19; \
    x0 = pC ^ rk00; \
    rk01 ^= rk1A; \
    x1 = pD ^ rk01; \
    rk02 ^= rk1B; \
    x2 = pE ^ rk02; \
    rk03 ^= rk1C; \
    x3 = pF ^ rk03; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    rk04 ^= rk1D; \
    x0 ^= rk04; \
    rk05 ^= rk1E; \
    x1 ^= rk05; \
    rk06 ^= rk1F; \
    x2 ^= rk06; \
    rk07 ^= rk00; \
    x3 ^= rk07; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    rk08 ^= rk01; \
    x0 ^= rk08; \
    rk09 ^= rk02; \
    x1 ^= rk09; \
    rk0A ^= rk03; \
    x2 ^= rk0A; \
    rk0B ^= rk04; \
    x3 ^= rk0B; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    rk0C ^= rk05; \
    x0 ^= rk0C; \
    rk0D ^= rk06; \
    x1 ^= rk0D; \
    rk0E ^= rk07; \
    x2 ^= rk0E; \
    rk0F ^= rk08; \
    x3 ^= rk0F; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    p8 ^= x0; \
    p9 ^= x1; \
    pA ^= x2; \
    pB ^= x3; \
    rk10 ^= rk09; \
    x0 = p4 ^ rk10; \
    rk11 ^= rk0A; \
    x1 = p5 ^ rk11; \
    rk12 ^= rk0B; \
    x2 = p6 ^ rk12; \
    rk13 ^= rk0C; \
    x3 = p7 ^ rk13; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    rk14 ^= rk0D; \
    x0 ^= rk14; \
    rk15 ^= rk0E; \
    x1 ^= rk15; \
    rk16 ^= rk0F; \
    x2 ^= rk16; \
    rk17 ^= rk10; \
    x3 ^= rk17; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    rk18 ^= rk11; \
    x0 ^= rk18; \
    rk19 ^= rk12; \
    x1 ^= rk19; \
    rk1A ^= rk13; \
    x2 ^= rk1A; \
    rk1B ^= rk14; \
    x3 ^= rk1B; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    rk1C ^= rk15; \
    x0 ^= rk1C; \
    rk1D ^= rk16; \
    x1 ^= rk1D; \
    rk1E ^= rk17; \
    x2 ^= rk1E; \
    rk1F ^= rk18; \
    x3 ^= rk1F; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    p0 ^= x0; \
    p1 ^= x1; \
    p2 ^= x2; \
    p3 ^= x3; \
    /* round 3, 7, 11 */ \
    KEY_EXPAND_ELT(rk00, rk01, rk02, rk03); \
    rk00 ^= rk1C; \
    rk01 ^= rk1D; \
    rk02 ^= rk1E; \
    rk03 ^= rk1F; \
    x0 = p8 ^ rk00; \
    x1 = p9 ^ rk01; \
    x2 = pA ^ rk02; \
    x3 = pB ^ rk03; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    KEY_EXPAND_ELT(rk04, rk05, rk06, rk07); \
    rk04 ^= rk00; \
    rk05 ^= rk01; \
    rk06 ^= rk02; \
    rk07 ^= rk03; \
    x0 ^= rk04; \
    x1 ^= rk05; \
    x2 ^= rk06; \
    x3 ^= rk07; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    KEY_EXPAND_ELT(rk08, rk09, rk0A, rk0B); \
    rk08 ^= rk04; \
    rk09 ^= rk05; \
    rk0A ^= rk06; \
    rk0B ^= rk07; \
    x0 ^= rk08; \
    x1 ^= rk09; \
    x2 ^= rk0A; \
    x3 ^= rk0B; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    KEY_EXPAND_ELT(rk0C, rk0D, rk0E, rk0F); \
    rk0C ^= rk08; \
    rk0D ^= rk09; \
    rk0E ^= rk0A; \
    rk0F ^= rk0B; \
    x0 ^= rk0C; \
    x1 ^= rk0D; \
    x2 ^= rk0E; \
    x3 ^= rk0F; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    p4 ^= x0; \
    p5 ^= x1; \
    p6 ^= x2; \
    p7 ^= x3; \
    KEY_EXPAND_ELT(rk10, rk11, rk12, rk13); \
    rk10 ^= rk0C; \
    rk11 ^= rk0D; \
    rk12 ^= rk0E; \
    rk13 ^= rk0F; \
    x0 = p0 ^ rk10; \
    x1 = p1 ^ rk11; \
    x2 = p2 ^ rk12; \
    x3 = p3 ^ rk13; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    KEY_EXPAND_ELT(rk14, rk15, rk16, rk17); \
    rk14 ^= rk10; \
    rk15 ^= rk11; \
    rk16 ^= rk12; \
    rk17 ^= rk13; \
    x0 ^= rk14; \
    x1 ^= rk15; \
    x2 ^= rk16; \
    x3 ^= rk17; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    KEY_EXPAND_ELT(rk18, rk19, rk1A, rk1B); \
    rk18 ^= rk14; \
    rk19 ^= rk15; \
    rk1A ^= rk16; \
    rk1B ^= rk17; \
    x0 ^= rk18; \
    x1 ^= rk19; \
    x2 ^= rk1A; \
    x3 ^= rk1B; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    KEY_EXPAND_ELT(rk1C, rk1D, rk1E, rk1F); \
    rk1C ^= rk18; \
    rk1D ^= rk19; \
    rk1E ^= rk1A; \
    rk1F ^= rk1B; \
    x0 ^= rk1C; \
    x1 ^= rk1D; \
    x2 ^= rk1E; \
    x3 ^= rk1F; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    pC ^= x0; \
    pD ^= x1; \
    pE ^= x2; \
    pF ^= x3; \
    /* round 4, 8, 12 */ \
    rk00 ^= rk19; \
    x0 = p4 ^ rk00; \
    rk01 ^= rk1A; \
    x1 = p5 ^ rk01; \
    rk02 ^= rk1B; \
    x2 = p6 ^ rk02; \
    rk03 ^= rk1C; \
    x3 = p7 ^ rk03; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    rk04 ^= rk1D; \
    x0 ^= rk04; \
    rk05 ^= rk1E; \
    x1 ^= rk05; \
    rk06 ^= rk1F; \
    x2 ^= rk06; \
    rk07 ^= rk00; \
    x3 ^= rk07; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    rk08 ^= rk01; \
    x0 ^= rk08; \
    rk09 ^= rk02; \
    x1 ^= rk09; \
    rk0A ^= rk03; \
    x2 ^= rk0A; \
    rk0B ^= rk04; \
    x3 ^= rk0B; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    rk0C ^= rk05; \
    x0 ^= rk0C; \
    rk0D ^= rk06; \
    x1 ^= rk0D; \
    rk0E ^= rk07; \
    x2 ^= rk0E; \
    rk0F ^= rk08; \
    x3 ^= rk0F; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    p0 ^= x0; \
    p1 ^= x1; \
    p2 ^= x2; \
    p3 ^= x3; \
    rk10 ^= rk09; \
    x0 = pC ^ rk10; \
    rk11 ^= rk0A; \
    x1 = pD ^ rk11; \
    rk12 ^= rk0B; \
    x2 = pE ^ rk12; \
    rk13 ^= rk0C; \
    x3 = pF ^ rk13; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    rk14 ^= rk0D; \
    x0 ^= rk14; \
    rk15 ^= rk0E; \
    x1 ^= rk15; \
    rk16 ^= rk0F; \
    x2 ^= rk16; \
    rk17 ^= rk10; \
    x3 ^= rk17; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    rk18 ^= rk11; \
    x0 ^= rk18; \
    rk19 ^= rk12; \
    x1 ^= rk19; \
    rk1A ^= rk13; \
    x2 ^= rk1A; \
    rk1B ^= rk14; \
    x3 ^= rk1B; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    rk1C ^= rk15; \
    x0 ^= rk1C; \
    rk1D ^= rk16; \
    x1 ^= rk1D; \
    rk1E ^= rk17; \
    x2 ^= rk1E; \
    rk1F ^= rk18; \
    x3 ^= rk1F; \
    AES_ROUND_NOKEY(x0, x1, x2, x3); \
    p8 ^= x0; \
    p9 ^= x1; \
    pA ^= x2; \
    pB ^= x3; \
  } \
  /* round 13 */ \
  KEY_EXPAND_ELT(rk00, rk01, rk02, rk03); \
  rk00 ^= rk1C; \
  rk01 ^= rk1D; \
  rk02 ^= rk1E; \
  rk03 ^= rk1F; \
  x0 = p0 ^ rk00; \
  x1 = p1 ^ rk01; \
  x2 = p2 ^ rk02; \
  x3 = p3 ^ rk03; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk04, rk05, rk06, rk07); \
  rk04 ^= rk00; \
  rk05 ^= rk01; \
  rk06 ^= rk02; \
  rk07 ^= rk03; \
  x0 ^= rk04; \
  x1 ^= rk05; \
  x2 ^= rk06; \
  x3 ^= rk07; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk08, rk09, rk0A, rk0B); \
  rk08 ^= rk04; \
  rk09 ^= rk05; \
  rk0A ^= rk06; \
  rk0B ^= rk07; \
  x0 ^= rk08; \
  x1 ^= rk09; \
  x2 ^= rk0A; \
  x3 ^= rk0B; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk0C, rk0D, rk0E, rk0F); \
  rk0C ^= rk08; \
  rk0D ^= rk09; \
  rk0E ^= rk0A; \
  rk0F ^= rk0B; \
  x0 ^= rk0C; \
  x1 ^= rk0D; \
  x2 ^= rk0E; \
  x3 ^= rk0F; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  pC ^= x0; \
  pD ^= x1; \
  pE ^= x2; \
  pF ^= x3; \
  KEY_EXPAND_ELT(rk10, rk11, rk12, rk13); \
  rk10 ^= rk0C; \
  rk11 ^= rk0D; \
  rk12 ^= rk0E; \
  rk13 ^= rk0F; \
  x0 = p8 ^ rk10; \
  x1 = p9 ^ rk11; \
  x2 = pA ^ rk12; \
  x3 = pB ^ rk13; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk14, rk15, rk16, rk17); \
  rk14 ^= rk10; \
  rk15 ^= rk11; \
  rk16 ^= rk12; \
  rk17 ^= rk13; \
  x0 ^= rk14; \
  x1 ^= rk15; \
  x2 ^= rk16; \
  x3 ^= rk17; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk18, rk19, rk1A, rk1B); \
  rk18 ^= rk14 ^ sc_count1; \
  rk19 ^= rk15 ^ sc_count0; \
  rk1A ^= rk16 ^ sc_count3; \
  rk1B ^= rk17 ^ SPH_T32(~sc_count2); \
  x0 ^= rk18; \
  x1 ^= rk19; \
  x2 ^= rk1A; \
  x3 ^= rk1B; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk1C, rk1D, rk1E, rk1F); \
  rk1C ^= rk18; \
  rk1D ^= rk19; \
  rk1E ^= rk1A; \
  rk1F ^= rk1B; \
  x0 ^= rk1C; \
  x1 ^= rk1D; \
  x2 ^= rk1E; \
  x3 ^= rk1F; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p4 ^= x0; \
  p5 ^= x1; \
  p6 ^= x2; \
  p7 ^= x3; \
  h0 ^= p8; \
  h1 ^= p9; \
  h2 ^= pA; \
  h3 ^= pB; \
  h4 ^= pC; \
  h5 ^= pD; \
  h6 ^= pE; \
  h7 ^= pF; \
  h8 ^= p0; \
  h9 ^= p1; \
  hA ^= p2; \
  hB ^= p3; \
  hC ^= p4; \
  hD ^= p5; \
  hE ^= p6; \
  hF ^= p7; \
  } while (0)

#define c256(msg)    do { \
  sph_u32 p0, p1, p2, p3, p4, p5, p6, p7; \
  sph_u32 x0, x1, x2, x3; \
        \
  p0 = h[0x0]; \
  p1 = h[0x1]; \
  p2 = h[0x2]; \
  p3 = h[0x3]; \
  p4 = h[0x4]; \
  p5 = h[0x5]; \
  p6 = h[0x6]; \
  p7 = h[0x7]; \
  /* round 0 */ \
  x0 = p4 ^ rk0; \
  x1 = p5 ^ rk1; \
  x2 = p6 ^ rk2; \
  x3 = p7 ^ rk3; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  x0 ^= rk4; \
  x1 ^= rk5; \
  x2 ^= rk6; \
  x3 ^= rk7; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  x0 ^= rk8; \
  x1 ^= rk9; \
  x2 ^= rkA; \
  x3 ^= rkB; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p0 ^= x0; \
  p1 ^= x1; \
  p2 ^= x2; \
  p3 ^= x3; \
  /* round 1 */ \
  x0 = p0 ^ rkC; \
  x1 = p1 ^ rkD; \
  x2 = p2 ^ rkE; \
  x3 = p3 ^ rkF; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk0, rk1, rk2, rk3); \
  rk0 ^= rkC ^ count0; \
  rk1 ^= rkD ^ SPH_T32(~count1); \
  rk2 ^= rkE; \
  rk3 ^= rkF; \
  x0 ^= rk0; \
  x1 ^= rk1; \
  x2 ^= rk2; \
  x3 ^= rk3; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk4, rk5, rk6, rk7); \
  rk4 ^= rk0; \
  rk5 ^= rk1; \
  rk6 ^= rk2; \
  rk7 ^= rk3; \
  x0 ^= rk4; \
  x1 ^= rk5; \
  x2 ^= rk6; \
  x3 ^= rk7; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p4 ^= x0; \
  p5 ^= x1; \
  p6 ^= x2; \
  p7 ^= x3; \
  /* round 2 */ \
  KEY_EXPAND_ELT(rk8, rk9, rkA, rkB); \
  rk8 ^= rk4; \
  rk9 ^= rk5; \
  rkA ^= rk6; \
  rkB ^= rk7; \
  x0 = p4 ^ rk8; \
  x1 = p5 ^ rk9; \
  x2 = p6 ^ rkA; \
  x3 = p7 ^ rkB; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rkC, rkD, rkE, rkF); \
  rkC ^= rk8; \
  rkD ^= rk9; \
  rkE ^= rkA; \
  rkF ^= rkB; \
  x0 ^= rkC; \
  x1 ^= rkD; \
  x2 ^= rkE; \
  x3 ^= rkF; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  rk0 ^= rkD; \
  x0 ^= rk0; \
  rk1 ^= rkE; \
  x1 ^= rk1; \
  rk2 ^= rkF; \
  x2 ^= rk2; \
  rk3 ^= rk0; \
  x3 ^= rk3; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p0 ^= x0; \
  p1 ^= x1; \
  p2 ^= x2; \
  p3 ^= x3; \
  /* round 3 */ \
  rk4 ^= rk1; \
  x0 = p0 ^ rk4; \
  rk5 ^= rk2; \
  x1 = p1 ^ rk5; \
  rk6 ^= rk3; \
  x2 = p2 ^ rk6; \
  rk7 ^= rk4; \
  x3 = p3 ^ rk7; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  rk8 ^= rk5; \
  x0 ^= rk8; \
  rk9 ^= rk6; \
  x1 ^= rk9; \
  rkA ^= rk7; \
  x2 ^= rkA; \
  rkB ^= rk8; \
  x3 ^= rkB; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  rkC ^= rk9; \
  x0 ^= rkC; \
  rkD ^= rkA; \
  x1 ^= rkD; \
  rkE ^= rkB; \
  x2 ^= rkE; \
  rkF ^= rkC; \
  x3 ^= rkF; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p4 ^= x0; \
  p5 ^= x1; \
  p6 ^= x2; \
  p7 ^= x3; \
  /* round 4 */ \
  KEY_EXPAND_ELT(rk0, rk1, rk2, rk3); \
  rk0 ^= rkC; \
  rk1 ^= rkD; \
  rk2 ^= rkE; \
  rk3 ^= rkF; \
  x0 = p4 ^ rk0; \
  x1 = p5 ^ rk1; \
  x2 = p6 ^ rk2; \
  x3 = p7 ^ rk3; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk4, rk5, rk6, rk7); \
  rk4 ^= rk0; \
  rk5 ^= rk1; \
  rk6 ^= rk2; \
  rk7 ^= rk3; \
  x0 ^= rk4; \
  x1 ^= rk5; \
  x2 ^= rk6; \
  x3 ^= rk7; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk8, rk9, rkA, rkB); \
  rk8 ^= rk4; \
  rk9 ^= rk5 ^ count1; \
  rkA ^= rk6 ^ SPH_T32(~count0); \
  rkB ^= rk7; \
  x0 ^= rk8; \
  x1 ^= rk9; \
  x2 ^= rkA; \
  x3 ^= rkB; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p0 ^= x0; \
  p1 ^= x1; \
  p2 ^= x2; \
  p3 ^= x3; \
  /* round 5 */ \
  KEY_EXPAND_ELT(rkC, rkD, rkE, rkF); \
  rkC ^= rk8; \
  rkD ^= rk9; \
  rkE ^= rkA; \
  rkF ^= rkB; \
  x0 = p0 ^ rkC; \
  x1 = p1 ^ rkD; \
  x2 = p2 ^ rkE; \
  x3 = p3 ^ rkF; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  rk0 ^= rkD; \
  x0 ^= rk0; \
  rk1 ^= rkE; \
  x1 ^= rk1; \
  rk2 ^= rkF; \
  x2 ^= rk2; \
  rk3 ^= rk0; \
  x3 ^= rk3; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  rk4 ^= rk1; \
  x0 ^= rk4; \
  rk5 ^= rk2; \
  x1 ^= rk5; \
  rk6 ^= rk3; \
  x2 ^= rk6; \
  rk7 ^= rk4; \
  x3 ^= rk7; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p4 ^= x0; \
  p5 ^= x1; \
  p6 ^= x2; \
  p7 ^= x3; \
  /* round 6 */ \
  rk8 ^= rk5; \
  x0 = p4 ^ rk8; \
  rk9 ^= rk6; \
  x1 = p5 ^ rk9; \
  rkA ^= rk7; \
  x2 = p6 ^ rkA; \
  rkB ^= rk8; \
  x3 = p7 ^ rkB; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  rkC ^= rk9; \
  x0 ^= rkC; \
  rkD ^= rkA; \
  x1 ^= rkD; \
  rkE ^= rkB; \
  x2 ^= rkE; \
  rkF ^= rkC; \
  x3 ^= rkF; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk0, rk1, rk2, rk3); \
  rk0 ^= rkC; \
  rk1 ^= rkD; \
  rk2 ^= rkE; \
  rk3 ^= rkF; \
  x0 ^= rk0; \
  x1 ^= rk1; \
  x2 ^= rk2; \
  x3 ^= rk3; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p0 ^= x0; \
  p1 ^= x1; \
  p2 ^= x2; \
  p3 ^= x3; \
  /* round 7 */ \
  KEY_EXPAND_ELT(rk4, rk5, rk6, rk7); \
  rk4 ^= rk0; \
  rk5 ^= rk1; \
  rk6 ^= rk2 ^ count1; \
  rk7 ^= rk3 ^ SPH_T32(~count0); \
  x0 = p0 ^ rk4; \
  x1 = p1 ^ rk5; \
  x2 = p2 ^ rk6; \
  x3 = p3 ^ rk7; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk8, rk9, rkA, rkB); \
  rk8 ^= rk4; \
  rk9 ^= rk5; \
  rkA ^= rk6; \
  rkB ^= rk7; \
  x0 ^= rk8; \
  x1 ^= rk9; \
  x2 ^= rkA; \
  x3 ^= rkB; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rkC, rkD, rkE, rkF); \
  rkC ^= rk8; \
  rkD ^= rk9; \
  rkE ^= rkA; \
  rkF ^= rkB; \
  x0 ^= rkC; \
  x1 ^= rkD; \
  x2 ^= rkE; \
  x3 ^= rkF; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p4 ^= x0; \
  p5 ^= x1; \
  p6 ^= x2; \
  p7 ^= x3; \
  /* round 8 */ \
  rk0 ^= rkD; \
  x0 = p4 ^ rk0; \
  rk1 ^= rkE; \
  x1 = p5 ^ rk1; \
  rk2 ^= rkF; \
  x2 = p6 ^ rk2; \
  rk3 ^= rk0; \
  x3 = p7 ^ rk3; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  rk4 ^= rk1; \
  x0 ^= rk4; \
  rk5 ^= rk2; \
  x1 ^= rk5; \
  rk6 ^= rk3; \
  x2 ^= rk6; \
  rk7 ^= rk4; \
  x3 ^= rk7; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  rk8 ^= rk5; \
  x0 ^= rk8; \
  rk9 ^= rk6; \
  x1 ^= rk9; \
  rkA ^= rk7; \
  x2 ^= rkA; \
  rkB ^= rk8; \
  x3 ^= rkB; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p0 ^= x0; \
  p1 ^= x1; \
  p2 ^= x2; \
  p3 ^= x3; \
  /* round 9 */ \
  rkC ^= rk9; \
  x0 = p0 ^ rkC; \
  rkD ^= rkA; \
  x1 = p1 ^ rkD; \
  rkE ^= rkB; \
  x2 = p2 ^ rkE; \
  rkF ^= rkC; \
  x3 = p3 ^ rkF; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk0, rk1, rk2, rk3); \
  rk0 ^= rkC; \
  rk1 ^= rkD; \
  rk2 ^= rkE; \
  rk3 ^= rkF; \
  x0 ^= rk0; \
  x1 ^= rk1; \
  x2 ^= rk2; \
  x3 ^= rk3; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rk4, rk5, rk6, rk7); \
  rk4 ^= rk0; \
  rk5 ^= rk1; \
  rk6 ^= rk2; \
  rk7 ^= rk3; \
  x0 ^= rk4; \
  x1 ^= rk5; \
  x2 ^= rk6; \
  x3 ^= rk7; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p4 ^= x0; \
  p5 ^= x1; \
  p6 ^= x2; \
  p7 ^= x3; \
  /* round 10 */ \
  KEY_EXPAND_ELT(rk8, rk9, rkA, rkB); \
  rk8 ^= rk4; \
  rk9 ^= rk5; \
  rkA ^= rk6; \
  rkB ^= rk7; \
  x0 = p4 ^ rk8; \
  x1 = p5 ^ rk9; \
  x2 = p6 ^ rkA; \
  x3 = p7 ^ rkB; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  KEY_EXPAND_ELT(rkC, rkD, rkE, rkF); \
  rkC ^= rk8 ^ count0; \
  rkD ^= rk9; \
  rkE ^= rkA; \
  rkF ^= rkB ^ SPH_T32(~count1); \
  x0 ^= rkC; \
  x1 ^= rkD; \
  x2 ^= rkE; \
  x3 ^= rkF; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  rk0 ^= rkD; \
  x0 ^= rk0; \
  rk1 ^= rkE; \
  x1 ^= rk1; \
  rk2 ^= rkF; \
  x2 ^= rk2; \
  rk3 ^= rk0; \
  x3 ^= rk3; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p0 ^= x0; \
  p1 ^= x1; \
  p2 ^= x2; \
  p3 ^= x3; \
  /* round 11 */ \
  rk4 ^= rk1; \
  x0 = p0 ^ rk4; \
  rk5 ^= rk2; \
  x1 = p1 ^ rk5; \
  rk6 ^= rk3; \
  x2 = p2 ^ rk6; \
  rk7 ^= rk4; \
  x3 = p3 ^ rk7; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  rk8 ^= rk5; \
  x0 ^= rk8; \
  rk9 ^= rk6; \
  x1 ^= rk9; \
  rkA ^= rk7; \
  x2 ^= rkA; \
  rkB ^= rk8; \
  x3 ^= rkB; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  rkC ^= rk9; \
  x0 ^= rkC; \
  rkD ^= rkA; \
  x1 ^= rkD; \
  rkE ^= rkB; \
  x2 ^= rkE; \
  rkF ^= rkC; \
  x3 ^= rkF; \
  AES_ROUND_NOKEY(x0, x1, x2, x3); \
  p4 ^= x0; \
  p5 ^= x1; \
  p6 ^= x2; \
  p7 ^= x3; \
  h[0x0] ^= p0; \
  h[0x1] ^= p1; \
  h[0x2] ^= p2; \
  h[0x3] ^= p3; \
  h[0x4] ^= p4; \
  h[0x5] ^= p5; \
  h[0x6] ^= p6; \
  h[0x7] ^= p7; \
        } while(0)

/* $Id: simd.c 227 2010-06-16 17:28:38Z tp $ */
/*
 * SIMD implementation.
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

typedef sph_u32 u32;
typedef sph_s32 s32;
#define C32     SPH_C32
#define T32     SPH_T32
#define ROL32   SPH_ROTL32

#define XCAT(x, y)    XCAT_(x, y)
#define XCAT_(x, y)   x ## y

__constant const s32 SIMD_Q[] = {
  4, 28, -80, -120, -47, -126, 45, -123, -92, -127, -70, 23, -23, -24, 40, -125, 101, 122, 34, -24, -119, 110, -121, -112, 32, 24, 51, 73, -117, -64, -21, 42, -60, 16, 5, 85, 107, 52, -44, -96, 42, 127, -18, -108, -47, 26, 91, 117, 112, 46, 87, 79, 126, -120, 65, -24, 121, 29, 118, -7, -53, 85, -98, -117, 32, 115, -47, -116, 63, 16, -108, 49, -119, 57, -110, 4, -76, -76, -42, -86, 58, 115, 4, 4, -83, -51, -37, 116, 32, 15, 36, -42, 73, -99, 94, 87, 60, -20, 67, 12, -76, 55, 117, -68, -82, -80, 93, -20, 92, -21, -128, -91, -11, 84, -28, 76, 94, -124, 37, 93, 17, -78, -106, -29, 88, -15, -47, 102, -4, -28, 80, 120, 47, 126, -45, 123, 92, 127, 70, -23, 23, 24, -40, 125, -101, -122, -34, 24, 119, -110, 121, 112, -32, -24, -51, -73, 117, 64, 21, -42, 60, -16, -5, -85, -107, -52, 44, 96, -42, -127, 18, 108, 47, -26, -91, -117, -112, -46, -87, -79, -126, 120, -65, 24, -121, -29, -118, 7, 53, -85, 98, 117, -32, -115, 47, 116, -63, -16, 108, -49, 119, -57, 110, -4, 76, 76, 42, 86, -58, -115, -4, -4, 83, 51, 37, -116, -32, -15, -36, 42, -73, 99, -94, -87, -60, 20, -67, -12, 76, -55, -117, 68, 82, 80, -93, 20, -92, 21, 128, 91, 11, -84, 28, -76, -94, 124, -37, -93, -17, 78, 106, 29, -88, 15, 47, -102
};

/*
 * The powers of 41 modulo 257. We use exponents from 0 to 255, inclusive.
 */
__constant const s32 alpha_tab[] = {
    1,  41, 139,  45,  46,  87, 226,  14,  60, 147, 116, 130,
  190,  80, 196,  69,   2,  82,  21,  90,  92, 174, 195,  28,
  120,  37, 232,   3, 123, 160, 135, 138,   4, 164,  42, 180,
  184,  91, 133,  56, 240,  74, 207,   6, 246,  63,  13,  19,
    8,  71,  84, 103, 111, 182,   9, 112, 223, 148, 157,  12,
  235, 126,  26,  38,  16, 142, 168, 206, 222, 107,  18, 224,
  189,  39,  57,  24, 213, 252,  52,  76,  32,  27,  79, 155,
  187, 214,  36, 191, 121,  78, 114,  48, 169, 247, 104, 152,
   64,  54, 158,  53, 117, 171,  72, 125, 242, 156, 228,  96,
   81, 237, 208,  47, 128, 108,  59, 106, 234,  85, 144, 250,
  227,  55, 199, 192, 162, 217, 159,  94, 256, 216, 118, 212,
  211, 170,  31, 243, 197, 110, 141, 127,  67, 177,  61, 188,
  255, 175, 236, 167, 165,  83,  62, 229, 137, 220,  25, 254,
  134,  97, 122, 119, 253,  93, 215,  77,  73, 166, 124, 201,
   17, 183,  50, 251,  11, 194, 244, 238, 249, 186, 173, 154,
  146,  75, 248, 145,  34, 109, 100, 245,  22, 131, 231, 219,
  241, 115,  89,  51,  35, 150, 239,  33,  68, 218, 200, 233,
   44,   5, 205, 181, 225, 230, 178, 102,  70,  43, 221,  66,
  136, 179, 143, 209,  88,  10, 153, 105, 193, 203,  99, 204,
  140,  86, 185, 132,  15, 101,  29, 161, 176,  20,  49, 210,
  129, 149, 198, 151,  23, 172, 113,   7,  30, 202,  58,  65,
   95,  40,  98, 163
};

/*
 * Ranges:
 *   REDS1: from -32768..98302 to -383..383
 *   REDS2: from -2^31..2^31-1 to -32768..98302
 */
#define REDS1(x)    (((x) & 0xFF) - ((x) >> 8))
#define REDS2(x)    (((x) & 0xFFFF) + ((x) >> 16))

/*
 * If, upon entry, the values of q[] are all in the -N..N range (where
 * N >= 98302) then the new values of q[] are in the -2N..2N range.
 *
 * Since alpha_tab[v] <= 256, maximum allowed range is for N = 8388608.
 */

#define FFT_LOOP_16_8(rb)   do { \
    s32 m = q[(rb)]; \
    s32 n = q[(rb) + 16]; \
    q[(rb)] = m + n; \
    q[(rb) + 16] = m - n; \
    s32 t; \
    m = q[(rb) + 0 + 1]; \
    n = q[(rb) + 0 + 1 + 16]; \
    t = REDS2(n * alpha_tab[0 + 1 * 8]); \
    q[(rb) + 0 + 1] = m + t; \
    q[(rb) + 0 + 1 + 16] = m - t; \
    m = q[(rb) + 0 + 2]; \
    n = q[(rb) + 0 + 2 + 16]; \
    t = REDS2(n * alpha_tab[0 + 2 * 8]); \
    q[(rb) + 0 + 2] = m + t; \
    q[(rb) + 0 + 2 + 16] = m - t; \
    m = q[(rb) + 0 + 3]; \
    n = q[(rb) + 0 + 3 + 16]; \
    t = REDS2(n * alpha_tab[0 + 3 * 8]); \
    q[(rb) + 0 + 3] = m + t; \
    q[(rb) + 0 + 3 + 16] = m - t; \
    \
    m = q[(rb) + 4 + 0]; \
    n = q[(rb) + 4 + 0 + 16]; \
    t = REDS2(n * alpha_tab[32 + 0 * 8]); \
    q[(rb) + 4 + 0] = m + t; \
    q[(rb) + 4 + 0 + 16] = m - t; \
    m = q[(rb) + 4 + 1]; \
    n = q[(rb) + 4 + 1 + 16]; \
    t = REDS2(n * alpha_tab[32 + 1 * 8]); \
    q[(rb) + 4 + 1] = m + t; \
    q[(rb) + 4 + 1 + 16] = m - t; \
    m = q[(rb) + 4 + 2]; \
    n = q[(rb) + 4 + 2 + 16]; \
    t = REDS2(n * alpha_tab[32 + 2 * 8]); \
    q[(rb) + 4 + 2] = m + t; \
    q[(rb) + 4 + 2 + 16] = m - t; \
    m = q[(rb) + 4 + 3]; \
    n = q[(rb) + 4 + 3 + 16]; \
    t = REDS2(n * alpha_tab[32 + 3 * 8]); \
    q[(rb) + 4 + 3] = m + t; \
    q[(rb) + 4 + 3 + 16] = m - t; \
    \
    m = q[(rb) + 8 + 0]; \
    n = q[(rb) + 8 + 0 + 16]; \
    t = REDS2(n * alpha_tab[64 + 0 * 8]); \
    q[(rb) + 8 + 0] = m + t; \
    q[(rb) + 8 + 0 + 16] = m - t; \
    m = q[(rb) + 8 + 1]; \
    n = q[(rb) + 8 + 1 + 16]; \
    t = REDS2(n * alpha_tab[64 + 1 * 8]); \
    q[(rb) + 8 + 1] = m + t; \
    q[(rb) + 8 + 1 + 16] = m - t; \
    m = q[(rb) + 8 + 2]; \
    n = q[(rb) + 8 + 2 + 16]; \
    t = REDS2(n * alpha_tab[64 + 2 * 8]); \
    q[(rb) + 8 + 2] = m + t; \
    q[(rb) + 8 + 2 + 16] = m - t; \
    m = q[(rb) + 8 + 3]; \
    n = q[(rb) + 8 + 3 + 16]; \
    t = REDS2(n * alpha_tab[64 + 3 * 8]); \
    q[(rb) + 8 + 3] = m + t; \
    q[(rb) + 8 + 3 + 16] = m - t; \
    \
    m = q[(rb) + 12 + 0]; \
    n = q[(rb) + 12 + 0 + 16]; \
    t = REDS2(n * alpha_tab[96 + 0 * 8]); \
    q[(rb) + 12 + 0] = m + t; \
    q[(rb) + 12 + 0 + 16] = m - t; \
    m = q[(rb) + 12 + 1]; \
    n = q[(rb) + 12 + 1 + 16]; \
    t = REDS2(n * alpha_tab[96 + 1 * 8]); \
    q[(rb) + 12 + 1] = m + t; \
    q[(rb) + 12 + 1 + 16] = m - t; \
    m = q[(rb) + 12 + 2]; \
    n = q[(rb) + 12 + 2 + 16]; \
    t = REDS2(n * alpha_tab[96 + 2 * 8]); \
    q[(rb) + 12 + 2] = m + t; \
    q[(rb) + 12 + 2 + 16] = m - t; \
    m = q[(rb) + 12 + 3]; \
    n = q[(rb) + 12 + 3 + 16]; \
    t = REDS2(n * alpha_tab[96 + 3 * 8]); \
    q[(rb) + 12 + 3] = m + t; \
    q[(rb) + 12 + 3 + 16] = m - t; \
  } while (0)

#define FFT_LOOP_32_4(rb)   do { \
    s32 m = q[(rb)]; \
    s32 n = q[(rb) + 32]; \
    q[(rb)] = m + n; \
    q[(rb) + 32] = m - n; \
    s32 t; \
    m = q[(rb) + 0 + 1]; \
    n = q[(rb) + 0 + 1 + 32]; \
    t = REDS2(n * alpha_tab[0 + 1 * 4]); \
    q[(rb) + 0 + 1] = m + t; \
    q[(rb) + 0 + 1 + 32] = m - t; \
    m = q[(rb) + 0 + 2]; \
    n = q[(rb) + 0 + 2 + 32]; \
    t = REDS2(n * alpha_tab[0 + 2 * 4]); \
    q[(rb) + 0 + 2] = m + t; \
    q[(rb) + 0 + 2 + 32] = m - t; \
    m = q[(rb) + 0 + 3]; \
    n = q[(rb) + 0 + 3 + 32]; \
    t = REDS2(n * alpha_tab[0 + 3 * 4]); \
    q[(rb) + 0 + 3] = m + t; \
    q[(rb) + 0 + 3 + 32] = m - t; \
    \
    m = q[(rb) + 4 + 0]; \
    n = q[(rb) + 4 + 0 + 32]; \
    t = REDS2(n * alpha_tab[16 + 0 * 4]); \
    q[(rb) + 4 + 0] = m + t; \
    q[(rb) + 4 + 0 + 32] = m - t; \
    m = q[(rb) + 4 + 1]; \
    n = q[(rb) + 4 + 1 + 32]; \
    t = REDS2(n * alpha_tab[16 + 1 * 4]); \
    q[(rb) + 4 + 1] = m + t; \
    q[(rb) + 4 + 1 + 32] = m - t; \
    m = q[(rb) + 4 + 2]; \
    n = q[(rb) + 4 + 2 + 32]; \
    t = REDS2(n * alpha_tab[16 + 2 * 4]); \
    q[(rb) + 4 + 2] = m + t; \
    q[(rb) + 4 + 2 + 32] = m - t; \
    m = q[(rb) + 4 + 3]; \
    n = q[(rb) + 4 + 3 + 32]; \
    t = REDS2(n * alpha_tab[16 + 3 * 4]); \
    q[(rb) + 4 + 3] = m + t; \
    q[(rb) + 4 + 3 + 32] = m - t; \
    \
    m = q[(rb) + 8 + 0]; \
    n = q[(rb) + 8 + 0 + 32]; \
    t = REDS2(n * alpha_tab[32 + 0 * 4]); \
    q[(rb) + 8 + 0] = m + t; \
    q[(rb) + 8 + 0 + 32] = m - t; \
    m = q[(rb) + 8 + 1]; \
    n = q[(rb) + 8 + 1 + 32]; \
    t = REDS2(n * alpha_tab[32 + 1 * 4]); \
    q[(rb) + 8 + 1] = m + t; \
    q[(rb) + 8 + 1 + 32] = m - t; \
    m = q[(rb) + 8 + 2]; \
    n = q[(rb) + 8 + 2 + 32]; \
    t = REDS2(n * alpha_tab[32 + 2 * 4]); \
    q[(rb) + 8 + 2] = m + t; \
    q[(rb) + 8 + 2 + 32] = m - t; \
    m = q[(rb) + 8 + 3]; \
    n = q[(rb) + 8 + 3 + 32]; \
    t = REDS2(n * alpha_tab[32 + 3 * 4]); \
    q[(rb) + 8 + 3] = m + t; \
    q[(rb) + 8 + 3 + 32] = m - t; \
    \
    m = q[(rb) + 12 + 0]; \
    n = q[(rb) + 12 + 0 + 32]; \
    t = REDS2(n * alpha_tab[48 + 0 * 4]); \
    q[(rb) + 12 + 0] = m + t; \
    q[(rb) + 12 + 0 + 32] = m - t; \
    m = q[(rb) + 12 + 1]; \
    n = q[(rb) + 12 + 1 + 32]; \
    t = REDS2(n * alpha_tab[48 + 1 * 4]); \
    q[(rb) + 12 + 1] = m + t; \
    q[(rb) + 12 + 1 + 32] = m - t; \
    m = q[(rb) + 12 + 2]; \
    n = q[(rb) + 12 + 2 + 32]; \
    t = REDS2(n * alpha_tab[48 + 2 * 4]); \
    q[(rb) + 12 + 2] = m + t; \
    q[(rb) + 12 + 2 + 32] = m - t; \
    m = q[(rb) + 12 + 3]; \
    n = q[(rb) + 12 + 3 + 32]; \
    t = REDS2(n * alpha_tab[48 + 3 * 4]); \
    q[(rb) + 12 + 3] = m + t; \
    q[(rb) + 12 + 3 + 32] = m - t; \
    \
    m = q[(rb) + 16 + 0]; \
    n = q[(rb) + 16 + 0 + 32]; \
    t = REDS2(n * alpha_tab[64 + 0 * 4]); \
    q[(rb) + 16 + 0] = m + t; \
    q[(rb) + 16 + 0 + 32] = m - t; \
    m = q[(rb) + 16 + 1]; \
    n = q[(rb) + 16 + 1 + 32]; \
    t = REDS2(n * alpha_tab[64 + 1 * 4]); \
    q[(rb) + 16 + 1] = m + t; \
    q[(rb) + 16 + 1 + 32] = m - t; \
    m = q[(rb) + 16 + 2]; \
    n = q[(rb) + 16 + 2 + 32]; \
    t = REDS2(n * alpha_tab[64 + 2 * 4]); \
    q[(rb) + 16 + 2] = m + t; \
    q[(rb) + 16 + 2 + 32] = m - t; \
    m = q[(rb) + 16 + 3]; \
    n = q[(rb) + 16 + 3 + 32]; \
    t = REDS2(n * alpha_tab[64 + 3 * 4]); \
    q[(rb) + 16 + 3] = m + t; \
    q[(rb) + 16 + 3 + 32] = m - t; \
    \
    m = q[(rb) + 20 + 0]; \
    n = q[(rb) + 20 + 0 + 32]; \
    t = REDS2(n * alpha_tab[80 + 0 * 4]); \
    q[(rb) + 20 + 0] = m + t; \
    q[(rb) + 20 + 0 + 32] = m - t; \
    m = q[(rb) + 20 + 1]; \
    n = q[(rb) + 20 + 1 + 32]; \
    t = REDS2(n * alpha_tab[80 + 1 * 4]); \
    q[(rb) + 20 + 1] = m + t; \
    q[(rb) + 20 + 1 + 32] = m - t; \
    m = q[(rb) + 20 + 2]; \
    n = q[(rb) + 20 + 2 + 32]; \
    t = REDS2(n * alpha_tab[80 + 2 * 4]); \
    q[(rb) + 20 + 2] = m + t; \
    q[(rb) + 20 + 2 + 32] = m - t; \
    m = q[(rb) + 20 + 3]; \
    n = q[(rb) + 20 + 3 + 32]; \
    t = REDS2(n * alpha_tab[80 + 3 * 4]); \
    q[(rb) + 20 + 3] = m + t; \
    q[(rb) + 20 + 3 + 32] = m - t; \
    \
    m = q[(rb) + 24 + 0]; \
    n = q[(rb) + 24 + 0 + 32]; \
    t = REDS2(n * alpha_tab[96 + 0 * 4]); \
    q[(rb) + 24 + 0] = m + t; \
    q[(rb) + 24 + 0 + 32] = m - t; \
    m = q[(rb) + 24 + 1]; \
    n = q[(rb) + 24 + 1 + 32]; \
    t = REDS2(n * alpha_tab[96 + 1 * 4]); \
    q[(rb) + 24 + 1] = m + t; \
    q[(rb) + 24 + 1 + 32] = m - t; \
    m = q[(rb) + 24 + 2]; \
    n = q[(rb) + 24 + 2 + 32]; \
    t = REDS2(n * alpha_tab[96 + 2 * 4]); \
    q[(rb) + 24 + 2] = m + t; \
    q[(rb) + 24 + 2 + 32] = m - t; \
    m = q[(rb) + 24 + 3]; \
    n = q[(rb) + 24 + 3 + 32]; \
    t = REDS2(n * alpha_tab[96 + 3 * 4]); \
    q[(rb) + 24 + 3] = m + t; \
    q[(rb) + 24 + 3 + 32] = m - t; \
    \
    m = q[(rb) + 28 + 0]; \
    n = q[(rb) + 28 + 0 + 32]; \
    t = REDS2(n * alpha_tab[112 + 0 * 4]); \
    q[(rb) + 28 + 0] = m + t; \
    q[(rb) + 28 + 0 + 32] = m - t; \
    m = q[(rb) + 28 + 1]; \
    n = q[(rb) + 28 + 1 + 32]; \
    t = REDS2(n * alpha_tab[112 + 1 * 4]); \
    q[(rb) + 28 + 1] = m + t; \
    q[(rb) + 28 + 1 + 32] = m - t; \
    m = q[(rb) + 28 + 2]; \
    n = q[(rb) + 28 + 2 + 32]; \
    t = REDS2(n * alpha_tab[112 + 2 * 4]); \
    q[(rb) + 28 + 2] = m + t; \
    q[(rb) + 28 + 2 + 32] = m - t; \
    m = q[(rb) + 28 + 3]; \
    n = q[(rb) + 28 + 3 + 32]; \
    t = REDS2(n * alpha_tab[112 + 3 * 4]); \
    q[(rb) + 28 + 3] = m + t; \
    q[(rb) + 28 + 3 + 32] = m - t; \
  } while (0)

#define FFT_LOOP_64_2(rb)   do { \
    s32 m = q[(rb)]; \
    s32 n = q[(rb) + 64]; \
    q[(rb)] = m + n; \
    q[(rb) + 64] = m - n; \
    s32 t; \
    m = q[(rb) + 0 + 1]; \
    n = q[(rb) + 0 + 1 + 64]; \
    t = REDS2(n * alpha_tab[0 + 1 * 2]); \
    q[(rb) + 0 + 1] = m + t; \
    q[(rb) + 0 + 1 + 64] = m - t; \
    m = q[(rb) + 0 + 2]; \
    n = q[(rb) + 0 + 2 + 64]; \
    t = REDS2(n * alpha_tab[0 + 2 * 2]); \
    q[(rb) + 0 + 2] = m + t; \
    q[(rb) + 0 + 2 + 64] = m - t; \
    m = q[(rb) + 0 + 3]; \
    n = q[(rb) + 0 + 3 + 64]; \
    t = REDS2(n * alpha_tab[0 + 3 * 2]); \
    q[(rb) + 0 + 3] = m + t; \
    q[(rb) + 0 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 4 + 0]; \
    n = q[(rb) + 4 + 0 + 64]; \
    t = REDS2(n * alpha_tab[8 + 0 * 2]); \
    q[(rb) + 4 + 0] = m + t; \
    q[(rb) + 4 + 0 + 64] = m - t; \
    m = q[(rb) + 4 + 1]; \
    n = q[(rb) + 4 + 1 + 64]; \
    t = REDS2(n * alpha_tab[8 + 1 * 2]); \
    q[(rb) + 4 + 1] = m + t; \
    q[(rb) + 4 + 1 + 64] = m - t; \
    m = q[(rb) + 4 + 2]; \
    n = q[(rb) + 4 + 2 + 64]; \
    t = REDS2(n * alpha_tab[8 + 2 * 2]); \
    q[(rb) + 4 + 2] = m + t; \
    q[(rb) + 4 + 2 + 64] = m - t; \
    m = q[(rb) + 4 + 3]; \
    n = q[(rb) + 4 + 3 + 64]; \
    t = REDS2(n * alpha_tab[8 + 3 * 2]); \
    q[(rb) + 4 + 3] = m + t; \
    q[(rb) + 4 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 8 + 0]; \
    n = q[(rb) + 8 + 0 + 64]; \
    t = REDS2(n * alpha_tab[16 + 0 * 2]); \
    q[(rb) + 8 + 0] = m + t; \
    q[(rb) + 8 + 0 + 64] = m - t; \
    m = q[(rb) + 8 + 1]; \
    n = q[(rb) + 8 + 1 + 64]; \
    t = REDS2(n * alpha_tab[16 + 1 * 2]); \
    q[(rb) + 8 + 1] = m + t; \
    q[(rb) + 8 + 1 + 64] = m - t; \
    m = q[(rb) + 8 + 2]; \
    n = q[(rb) + 8 + 2 + 64]; \
    t = REDS2(n * alpha_tab[16 + 2 * 2]); \
    q[(rb) + 8 + 2] = m + t; \
    q[(rb) + 8 + 2 + 64] = m - t; \
    m = q[(rb) + 8 + 3]; \
    n = q[(rb) + 8 + 3 + 64]; \
    t = REDS2(n * alpha_tab[16 + 3 * 2]); \
    q[(rb) + 8 + 3] = m + t; \
    q[(rb) + 8 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 12 + 0]; \
    n = q[(rb) + 12 + 0 + 64]; \
    t = REDS2(n * alpha_tab[24 + 0 * 2]); \
    q[(rb) + 12 + 0] = m + t; \
    q[(rb) + 12 + 0 + 64] = m - t; \
    m = q[(rb) + 12 + 1]; \
    n = q[(rb) + 12 + 1 + 64]; \
    t = REDS2(n * alpha_tab[24 + 1 * 2]); \
    q[(rb) + 12 + 1] = m + t; \
    q[(rb) + 12 + 1 + 64] = m - t; \
    m = q[(rb) + 12 + 2]; \
    n = q[(rb) + 12 + 2 + 64]; \
    t = REDS2(n * alpha_tab[24 + 2 * 2]); \
    q[(rb) + 12 + 2] = m + t; \
    q[(rb) + 12 + 2 + 64] = m - t; \
    m = q[(rb) + 12 + 3]; \
    n = q[(rb) + 12 + 3 + 64]; \
    t = REDS2(n * alpha_tab[24 + 3 * 2]); \
    q[(rb) + 12 + 3] = m + t; \
    q[(rb) + 12 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 16 + 0]; \
    n = q[(rb) + 16 + 0 + 64]; \
    t = REDS2(n * alpha_tab[32 + 0 * 2]); \
    q[(rb) + 16 + 0] = m + t; \
    q[(rb) + 16 + 0 + 64] = m - t; \
    m = q[(rb) + 16 + 1]; \
    n = q[(rb) + 16 + 1 + 64]; \
    t = REDS2(n * alpha_tab[32 + 1 * 2]); \
    q[(rb) + 16 + 1] = m + t; \
    q[(rb) + 16 + 1 + 64] = m - t; \
    m = q[(rb) + 16 + 2]; \
    n = q[(rb) + 16 + 2 + 64]; \
    t = REDS2(n * alpha_tab[32 + 2 * 2]); \
    q[(rb) + 16 + 2] = m + t; \
    q[(rb) + 16 + 2 + 64] = m - t; \
    m = q[(rb) + 16 + 3]; \
    n = q[(rb) + 16 + 3 + 64]; \
    t = REDS2(n * alpha_tab[32 + 3 * 2]); \
    q[(rb) + 16 + 3] = m + t; \
    q[(rb) + 16 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 20 + 0]; \
    n = q[(rb) + 20 + 0 + 64]; \
    t = REDS2(n * alpha_tab[40 + 0 * 2]); \
    q[(rb) + 20 + 0] = m + t; \
    q[(rb) + 20 + 0 + 64] = m - t; \
    m = q[(rb) + 20 + 1]; \
    n = q[(rb) + 20 + 1 + 64]; \
    t = REDS2(n * alpha_tab[40 + 1 * 2]); \
    q[(rb) + 20 + 1] = m + t; \
    q[(rb) + 20 + 1 + 64] = m - t; \
    m = q[(rb) + 20 + 2]; \
    n = q[(rb) + 20 + 2 + 64]; \
    t = REDS2(n * alpha_tab[40 + 2 * 2]); \
    q[(rb) + 20 + 2] = m + t; \
    q[(rb) + 20 + 2 + 64] = m - t; \
    m = q[(rb) + 20 + 3]; \
    n = q[(rb) + 20 + 3 + 64]; \
    t = REDS2(n * alpha_tab[40 + 3 * 2]); \
    q[(rb) + 20 + 3] = m + t; \
    q[(rb) + 20 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 24 + 0]; \
    n = q[(rb) + 24 + 0 + 64]; \
    t = REDS2(n * alpha_tab[48 + 0 * 2]); \
    q[(rb) + 24 + 0] = m + t; \
    q[(rb) + 24 + 0 + 64] = m - t; \
    m = q[(rb) + 24 + 1]; \
    n = q[(rb) + 24 + 1 + 64]; \
    t = REDS2(n * alpha_tab[48 + 1 * 2]); \
    q[(rb) + 24 + 1] = m + t; \
    q[(rb) + 24 + 1 + 64] = m - t; \
    m = q[(rb) + 24 + 2]; \
    n = q[(rb) + 24 + 2 + 64]; \
    t = REDS2(n * alpha_tab[48 + 2 * 2]); \
    q[(rb) + 24 + 2] = m + t; \
    q[(rb) + 24 + 2 + 64] = m - t; \
    m = q[(rb) + 24 + 3]; \
    n = q[(rb) + 24 + 3 + 64]; \
    t = REDS2(n * alpha_tab[48 + 3 * 2]); \
    q[(rb) + 24 + 3] = m + t; \
    q[(rb) + 24 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 28 + 0]; \
    n = q[(rb) + 28 + 0 + 64]; \
    t = REDS2(n * alpha_tab[56 + 0 * 2]); \
    q[(rb) + 28 + 0] = m + t; \
    q[(rb) + 28 + 0 + 64] = m - t; \
    m = q[(rb) + 28 + 1]; \
    n = q[(rb) + 28 + 1 + 64]; \
    t = REDS2(n * alpha_tab[56 + 1 * 2]); \
    q[(rb) + 28 + 1] = m + t; \
    q[(rb) + 28 + 1 + 64] = m - t; \
    m = q[(rb) + 28 + 2]; \
    n = q[(rb) + 28 + 2 + 64]; \
    t = REDS2(n * alpha_tab[56 + 2 * 2]); \
    q[(rb) + 28 + 2] = m + t; \
    q[(rb) + 28 + 2 + 64] = m - t; \
    m = q[(rb) + 28 + 3]; \
    n = q[(rb) + 28 + 3 + 64]; \
    t = REDS2(n * alpha_tab[56 + 3 * 2]); \
    q[(rb) + 28 + 3] = m + t; \
    q[(rb) + 28 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 32 + 0]; \
    n = q[(rb) + 32 + 0 + 64]; \
    t = REDS2(n * alpha_tab[64 + 0 * 2]); \
    q[(rb) + 32 + 0] = m + t; \
    q[(rb) + 32 + 0 + 64] = m - t; \
    m = q[(rb) + 32 + 1]; \
    n = q[(rb) + 32 + 1 + 64]; \
    t = REDS2(n * alpha_tab[64 + 1 * 2]); \
    q[(rb) + 32 + 1] = m + t; \
    q[(rb) + 32 + 1 + 64] = m - t; \
    m = q[(rb) + 32 + 2]; \
    n = q[(rb) + 32 + 2 + 64]; \
    t = REDS2(n * alpha_tab[64 + 2 * 2]); \
    q[(rb) + 32 + 2] = m + t; \
    q[(rb) + 32 + 2 + 64] = m - t; \
    m = q[(rb) + 32 + 3]; \
    n = q[(rb) + 32 + 3 + 64]; \
    t = REDS2(n * alpha_tab[64 + 3 * 2]); \
    q[(rb) + 32 + 3] = m + t; \
    q[(rb) + 32 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 36 + 0]; \
    n = q[(rb) + 36 + 0 + 64]; \
    t = REDS2(n * alpha_tab[72 + 0 * 2]); \
    q[(rb) + 36 + 0] = m + t; \
    q[(rb) + 36 + 0 + 64] = m - t; \
    m = q[(rb) + 36 + 1]; \
    n = q[(rb) + 36 + 1 + 64]; \
    t = REDS2(n * alpha_tab[72 + 1 * 2]); \
    q[(rb) + 36 + 1] = m + t; \
    q[(rb) + 36 + 1 + 64] = m - t; \
    m = q[(rb) + 36 + 2]; \
    n = q[(rb) + 36 + 2 + 64]; \
    t = REDS2(n * alpha_tab[72 + 2 * 2]); \
    q[(rb) + 36 + 2] = m + t; \
    q[(rb) + 36 + 2 + 64] = m - t; \
    m = q[(rb) + 36 + 3]; \
    n = q[(rb) + 36 + 3 + 64]; \
    t = REDS2(n * alpha_tab[72 + 3 * 2]); \
    q[(rb) + 36 + 3] = m + t; \
    q[(rb) + 36 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 40 + 0]; \
    n = q[(rb) + 40 + 0 + 64]; \
    t = REDS2(n * alpha_tab[80 + 0 * 2]); \
    q[(rb) + 40 + 0] = m + t; \
    q[(rb) + 40 + 0 + 64] = m - t; \
    m = q[(rb) + 40 + 1]; \
    n = q[(rb) + 40 + 1 + 64]; \
    t = REDS2(n * alpha_tab[80 + 1 * 2]); \
    q[(rb) + 40 + 1] = m + t; \
    q[(rb) + 40 + 1 + 64] = m - t; \
    m = q[(rb) + 40 + 2]; \
    n = q[(rb) + 40 + 2 + 64]; \
    t = REDS2(n * alpha_tab[80 + 2 * 2]); \
    q[(rb) + 40 + 2] = m + t; \
    q[(rb) + 40 + 2 + 64] = m - t; \
    m = q[(rb) + 40 + 3]; \
    n = q[(rb) + 40 + 3 + 64]; \
    t = REDS2(n * alpha_tab[80 + 3 * 2]); \
    q[(rb) + 40 + 3] = m + t; \
    q[(rb) + 40 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 44 + 0]; \
    n = q[(rb) + 44 + 0 + 64]; \
    t = REDS2(n * alpha_tab[88 + 0 * 2]); \
    q[(rb) + 44 + 0] = m + t; \
    q[(rb) + 44 + 0 + 64] = m - t; \
    m = q[(rb) + 44 + 1]; \
    n = q[(rb) + 44 + 1 + 64]; \
    t = REDS2(n * alpha_tab[88 + 1 * 2]); \
    q[(rb) + 44 + 1] = m + t; \
    q[(rb) + 44 + 1 + 64] = m - t; \
    m = q[(rb) + 44 + 2]; \
    n = q[(rb) + 44 + 2 + 64]; \
    t = REDS2(n * alpha_tab[88 + 2 * 2]); \
    q[(rb) + 44 + 2] = m + t; \
    q[(rb) + 44 + 2 + 64] = m - t; \
    m = q[(rb) + 44 + 3]; \
    n = q[(rb) + 44 + 3 + 64]; \
    t = REDS2(n * alpha_tab[88 + 3 * 2]); \
    q[(rb) + 44 + 3] = m + t; \
    q[(rb) + 44 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 48 + 0]; \
    n = q[(rb) + 48 + 0 + 64]; \
    t = REDS2(n * alpha_tab[96 + 0 * 2]); \
    q[(rb) + 48 + 0] = m + t; \
    q[(rb) + 48 + 0 + 64] = m - t; \
    m = q[(rb) + 48 + 1]; \
    n = q[(rb) + 48 + 1 + 64]; \
    t = REDS2(n * alpha_tab[96 + 1 * 2]); \
    q[(rb) + 48 + 1] = m + t; \
    q[(rb) + 48 + 1 + 64] = m - t; \
    m = q[(rb) + 48 + 2]; \
    n = q[(rb) + 48 + 2 + 64]; \
    t = REDS2(n * alpha_tab[96 + 2 * 2]); \
    q[(rb) + 48 + 2] = m + t; \
    q[(rb) + 48 + 2 + 64] = m - t; \
    m = q[(rb) + 48 + 3]; \
    n = q[(rb) + 48 + 3 + 64]; \
    t = REDS2(n * alpha_tab[96 + 3 * 2]); \
    q[(rb) + 48 + 3] = m + t; \
    q[(rb) + 48 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 52 + 0]; \
    n = q[(rb) + 52 + 0 + 64]; \
    t = REDS2(n * alpha_tab[104 + 0 * 2]); \
    q[(rb) + 52 + 0] = m + t; \
    q[(rb) + 52 + 0 + 64] = m - t; \
    m = q[(rb) + 52 + 1]; \
    n = q[(rb) + 52 + 1 + 64]; \
    t = REDS2(n * alpha_tab[104 + 1 * 2]); \
    q[(rb) + 52 + 1] = m + t; \
    q[(rb) + 52 + 1 + 64] = m - t; \
    m = q[(rb) + 52 + 2]; \
    n = q[(rb) + 52 + 2 + 64]; \
    t = REDS2(n * alpha_tab[104 + 2 * 2]); \
    q[(rb) + 52 + 2] = m + t; \
    q[(rb) + 52 + 2 + 64] = m - t; \
    m = q[(rb) + 52 + 3]; \
    n = q[(rb) + 52 + 3 + 64]; \
    t = REDS2(n * alpha_tab[104 + 3 * 2]); \
    q[(rb) + 52 + 3] = m + t; \
    q[(rb) + 52 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 56 + 0]; \
    n = q[(rb) + 56 + 0 + 64]; \
    t = REDS2(n * alpha_tab[112 + 0 * 2]); \
    q[(rb) + 56 + 0] = m + t; \
    q[(rb) + 56 + 0 + 64] = m - t; \
    m = q[(rb) + 56 + 1]; \
    n = q[(rb) + 56 + 1 + 64]; \
    t = REDS2(n * alpha_tab[112 + 1 * 2]); \
    q[(rb) + 56 + 1] = m + t; \
    q[(rb) + 56 + 1 + 64] = m - t; \
    m = q[(rb) + 56 + 2]; \
    n = q[(rb) + 56 + 2 + 64]; \
    t = REDS2(n * alpha_tab[112 + 2 * 2]); \
    q[(rb) + 56 + 2] = m + t; \
    q[(rb) + 56 + 2 + 64] = m - t; \
    m = q[(rb) + 56 + 3]; \
    n = q[(rb) + 56 + 3 + 64]; \
    t = REDS2(n * alpha_tab[112 + 3 * 2]); \
    q[(rb) + 56 + 3] = m + t; \
    q[(rb) + 56 + 3 + 64] = m - t; \
    \
    m = q[(rb) + 60 + 0]; \
    n = q[(rb) + 60 + 0 + 64]; \
    t = REDS2(n * alpha_tab[120 + 0 * 2]); \
    q[(rb) + 60 + 0] = m + t; \
    q[(rb) + 60 + 0 + 64] = m - t; \
    m = q[(rb) + 60 + 1]; \
    n = q[(rb) + 60 + 1 + 64]; \
    t = REDS2(n * alpha_tab[120 + 1 * 2]); \
    q[(rb) + 60 + 1] = m + t; \
    q[(rb) + 60 + 1 + 64] = m - t; \
    m = q[(rb) + 60 + 2]; \
    n = q[(rb) + 60 + 2 + 64]; \
    t = REDS2(n * alpha_tab[120 + 2 * 2]); \
    q[(rb) + 60 + 2] = m + t; \
    q[(rb) + 60 + 2 + 64] = m - t; \
    m = q[(rb) + 60 + 3]; \
    n = q[(rb) + 60 + 3 + 64]; \
    t = REDS2(n * alpha_tab[120 + 3 * 2]); \
    q[(rb) + 60 + 3] = m + t; \
    q[(rb) + 60 + 3 + 64] = m - t; \
  } while (0)

#define FFT_LOOP_128_1(rb)   do { \
    s32 m = q[(rb)]; \
    s32 n = q[(rb) + 128]; \
    q[(rb)] = m + n; \
    q[(rb) + 128] = m - n; \
    s32 t; \
    m = q[(rb) + 0 + 1]; \
    n = q[(rb) + 0 + 1 + 128]; \
    t = REDS2(n * alpha_tab[0 + 1 * 1]); \
    q[(rb) + 0 + 1] = m + t; \
    q[(rb) + 0 + 1 + 128] = m - t; \
    m = q[(rb) + 0 + 2]; \
    n = q[(rb) + 0 + 2 + 128]; \
    t = REDS2(n * alpha_tab[0 + 2 * 1]); \
    q[(rb) + 0 + 2] = m + t; \
    q[(rb) + 0 + 2 + 128] = m - t; \
    m = q[(rb) + 0 + 3]; \
    n = q[(rb) + 0 + 3 + 128]; \
    t = REDS2(n * alpha_tab[0 + 3 * 1]); \
    q[(rb) + 0 + 3] = m + t; \
    q[(rb) + 0 + 3 + 128] = m - t; \
    m = q[(rb) + 4 + 0]; \
    n = q[(rb) + 4 + 0 + 128]; \
    t = REDS2(n * alpha_tab[4 + 0 * 1]); \
    q[(rb) + 4 + 0] = m + t; \
    q[(rb) + 4 + 0 + 128] = m - t; \
    m = q[(rb) + 4 + 1]; \
    n = q[(rb) + 4 + 1 + 128]; \
    t = REDS2(n * alpha_tab[4 + 1 * 1]); \
    q[(rb) + 4 + 1] = m + t; \
    q[(rb) + 4 + 1 + 128] = m - t; \
    m = q[(rb) + 4 + 2]; \
    n = q[(rb) + 4 + 2 + 128]; \
    t = REDS2(n * alpha_tab[4 + 2 * 1]); \
    q[(rb) + 4 + 2] = m + t; \
    q[(rb) + 4 + 2 + 128] = m - t; \
    m = q[(rb) + 4 + 3]; \
    n = q[(rb) + 4 + 3 + 128]; \
    t = REDS2(n * alpha_tab[4 + 3 * 1]); \
    q[(rb) + 4 + 3] = m + t; \
    q[(rb) + 4 + 3 + 128] = m - t; \
    m = q[(rb) + 8 + 0]; \
    n = q[(rb) + 8 + 0 + 128]; \
    t = REDS2(n * alpha_tab[8 + 0 * 1]); \
    q[(rb) + 8 + 0] = m + t; \
    q[(rb) + 8 + 0 + 128] = m - t; \
    m = q[(rb) + 8 + 1]; \
    n = q[(rb) + 8 + 1 + 128]; \
    t = REDS2(n * alpha_tab[8 + 1 * 1]); \
    q[(rb) + 8 + 1] = m + t; \
    q[(rb) + 8 + 1 + 128] = m - t; \
    m = q[(rb) + 8 + 2]; \
    n = q[(rb) + 8 + 2 + 128]; \
    t = REDS2(n * alpha_tab[8 + 2 * 1]); \
    q[(rb) + 8 + 2] = m + t; \
    q[(rb) + 8 + 2 + 128] = m - t; \
    m = q[(rb) + 8 + 3]; \
    n = q[(rb) + 8 + 3 + 128]; \
    t = REDS2(n * alpha_tab[8 + 3 * 1]); \
    q[(rb) + 8 + 3] = m + t; \
    q[(rb) + 8 + 3 + 128] = m - t; \
    m = q[(rb) + 12 + 0]; \
    n = q[(rb) + 12 + 0 + 128]; \
    t = REDS2(n * alpha_tab[12 + 0 * 1]); \
    q[(rb) + 12 + 0] = m + t; \
    q[(rb) + 12 + 0 + 128] = m - t; \
    m = q[(rb) + 12 + 1]; \
    n = q[(rb) + 12 + 1 + 128]; \
    t = REDS2(n * alpha_tab[12 + 1 * 1]); \
    q[(rb) + 12 + 1] = m + t; \
    q[(rb) + 12 + 1 + 128] = m - t; \
    m = q[(rb) + 12 + 2]; \
    n = q[(rb) + 12 + 2 + 128]; \
    t = REDS2(n * alpha_tab[12 + 2 * 1]); \
    q[(rb) + 12 + 2] = m + t; \
    q[(rb) + 12 + 2 + 128] = m - t; \
    m = q[(rb) + 12 + 3]; \
    n = q[(rb) + 12 + 3 + 128]; \
    t = REDS2(n * alpha_tab[12 + 3 * 1]); \
    q[(rb) + 12 + 3] = m + t; \
    q[(rb) + 12 + 3 + 128] = m - t; \
    m = q[(rb) + 16 + 0]; \
    n = q[(rb) + 16 + 0 + 128]; \
    t = REDS2(n * alpha_tab[16 + 0 * 1]); \
    q[(rb) + 16 + 0] = m + t; \
    q[(rb) + 16 + 0 + 128] = m - t; \
    m = q[(rb) + 16 + 1]; \
    n = q[(rb) + 16 + 1 + 128]; \
    t = REDS2(n * alpha_tab[16 + 1 * 1]); \
    q[(rb) + 16 + 1] = m + t; \
    q[(rb) + 16 + 1 + 128] = m - t; \
    m = q[(rb) + 16 + 2]; \
    n = q[(rb) + 16 + 2 + 128]; \
    t = REDS2(n * alpha_tab[16 + 2 * 1]); \
    q[(rb) + 16 + 2] = m + t; \
    q[(rb) + 16 + 2 + 128] = m - t; \
    m = q[(rb) + 16 + 3]; \
    n = q[(rb) + 16 + 3 + 128]; \
    t = REDS2(n * alpha_tab[16 + 3 * 1]); \
    q[(rb) + 16 + 3] = m + t; \
    q[(rb) + 16 + 3 + 128] = m - t; \
    m = q[(rb) + 20 + 0]; \
    n = q[(rb) + 20 + 0 + 128]; \
    t = REDS2(n * alpha_tab[20 + 0 * 1]); \
    q[(rb) + 20 + 0] = m + t; \
    q[(rb) + 20 + 0 + 128] = m - t; \
    m = q[(rb) + 20 + 1]; \
    n = q[(rb) + 20 + 1 + 128]; \
    t = REDS2(n * alpha_tab[20 + 1 * 1]); \
    q[(rb) + 20 + 1] = m + t; \
    q[(rb) + 20 + 1 + 128] = m - t; \
    m = q[(rb) + 20 + 2]; \
    n = q[(rb) + 20 + 2 + 128]; \
    t = REDS2(n * alpha_tab[20 + 2 * 1]); \
    q[(rb) + 20 + 2] = m + t; \
    q[(rb) + 20 + 2 + 128] = m - t; \
    m = q[(rb) + 20 + 3]; \
    n = q[(rb) + 20 + 3 + 128]; \
    t = REDS2(n * alpha_tab[20 + 3 * 1]); \
    q[(rb) + 20 + 3] = m + t; \
    q[(rb) + 20 + 3 + 128] = m - t; \
    m = q[(rb) + 24 + 0]; \
    n = q[(rb) + 24 + 0 + 128]; \
    t = REDS2(n * alpha_tab[24 + 0 * 1]); \
    q[(rb) + 24 + 0] = m + t; \
    q[(rb) + 24 + 0 + 128] = m - t; \
    m = q[(rb) + 24 + 1]; \
    n = q[(rb) + 24 + 1 + 128]; \
    t = REDS2(n * alpha_tab[24 + 1 * 1]); \
    q[(rb) + 24 + 1] = m + t; \
    q[(rb) + 24 + 1 + 128] = m - t; \
    m = q[(rb) + 24 + 2]; \
    n = q[(rb) + 24 + 2 + 128]; \
    t = REDS2(n * alpha_tab[24 + 2 * 1]); \
    q[(rb) + 24 + 2] = m + t; \
    q[(rb) + 24 + 2 + 128] = m - t; \
    m = q[(rb) + 24 + 3]; \
    n = q[(rb) + 24 + 3 + 128]; \
    t = REDS2(n * alpha_tab[24 + 3 * 1]); \
    q[(rb) + 24 + 3] = m + t; \
    q[(rb) + 24 + 3 + 128] = m - t; \
    m = q[(rb) + 28 + 0]; \
    n = q[(rb) + 28 + 0 + 128]; \
    t = REDS2(n * alpha_tab[28 + 0 * 1]); \
    q[(rb) + 28 + 0] = m + t; \
    q[(rb) + 28 + 0 + 128] = m - t; \
    m = q[(rb) + 28 + 1]; \
    n = q[(rb) + 28 + 1 + 128]; \
    t = REDS2(n * alpha_tab[28 + 1 * 1]); \
    q[(rb) + 28 + 1] = m + t; \
    q[(rb) + 28 + 1 + 128] = m - t; \
    m = q[(rb) + 28 + 2]; \
    n = q[(rb) + 28 + 2 + 128]; \
    t = REDS2(n * alpha_tab[28 + 2 * 1]); \
    q[(rb) + 28 + 2] = m + t; \
    q[(rb) + 28 + 2 + 128] = m - t; \
    m = q[(rb) + 28 + 3]; \
    n = q[(rb) + 28 + 3 + 128]; \
    t = REDS2(n * alpha_tab[28 + 3 * 1]); \
    q[(rb) + 28 + 3] = m + t; \
    q[(rb) + 28 + 3 + 128] = m - t; \
    m = q[(rb) + 32 + 0]; \
    n = q[(rb) + 32 + 0 + 128]; \
    t = REDS2(n * alpha_tab[32 + 0 * 1]); \
    q[(rb) + 32 + 0] = m + t; \
    q[(rb) + 32 + 0 + 128] = m - t; \
    m = q[(rb) + 32 + 1]; \
    n = q[(rb) + 32 + 1 + 128]; \
    t = REDS2(n * alpha_tab[32 + 1 * 1]); \
    q[(rb) + 32 + 1] = m + t; \
    q[(rb) + 32 + 1 + 128] = m - t; \
    m = q[(rb) + 32 + 2]; \
    n = q[(rb) + 32 + 2 + 128]; \
    t = REDS2(n * alpha_tab[32 + 2 * 1]); \
    q[(rb) + 32 + 2] = m + t; \
    q[(rb) + 32 + 2 + 128] = m - t; \
    m = q[(rb) + 32 + 3]; \
    n = q[(rb) + 32 + 3 + 128]; \
    t = REDS2(n * alpha_tab[32 + 3 * 1]); \
    q[(rb) + 32 + 3] = m + t; \
    q[(rb) + 32 + 3 + 128] = m - t; \
    m = q[(rb) + 36 + 0]; \
    n = q[(rb) + 36 + 0 + 128]; \
    t = REDS2(n * alpha_tab[36 + 0 * 1]); \
    q[(rb) + 36 + 0] = m + t; \
    q[(rb) + 36 + 0 + 128] = m - t; \
    m = q[(rb) + 36 + 1]; \
    n = q[(rb) + 36 + 1 + 128]; \
    t = REDS2(n * alpha_tab[36 + 1 * 1]); \
    q[(rb) + 36 + 1] = m + t; \
    q[(rb) + 36 + 1 + 128] = m - t; \
    m = q[(rb) + 36 + 2]; \
    n = q[(rb) + 36 + 2 + 128]; \
    t = REDS2(n * alpha_tab[36 + 2 * 1]); \
    q[(rb) + 36 + 2] = m + t; \
    q[(rb) + 36 + 2 + 128] = m - t; \
    m = q[(rb) + 36 + 3]; \
    n = q[(rb) + 36 + 3 + 128]; \
    t = REDS2(n * alpha_tab[36 + 3 * 1]); \
    q[(rb) + 36 + 3] = m + t; \
    q[(rb) + 36 + 3 + 128] = m - t; \
    m = q[(rb) + 40 + 0]; \
    n = q[(rb) + 40 + 0 + 128]; \
    t = REDS2(n * alpha_tab[40 + 0 * 1]); \
    q[(rb) + 40 + 0] = m + t; \
    q[(rb) + 40 + 0 + 128] = m - t; \
    m = q[(rb) + 40 + 1]; \
    n = q[(rb) + 40 + 1 + 128]; \
    t = REDS2(n * alpha_tab[40 + 1 * 1]); \
    q[(rb) + 40 + 1] = m + t; \
    q[(rb) + 40 + 1 + 128] = m - t; \
    m = q[(rb) + 40 + 2]; \
    n = q[(rb) + 40 + 2 + 128]; \
    t = REDS2(n * alpha_tab[40 + 2 * 1]); \
    q[(rb) + 40 + 2] = m + t; \
    q[(rb) + 40 + 2 + 128] = m - t; \
    m = q[(rb) + 40 + 3]; \
    n = q[(rb) + 40 + 3 + 128]; \
    t = REDS2(n * alpha_tab[40 + 3 * 1]); \
    q[(rb) + 40 + 3] = m + t; \
    q[(rb) + 40 + 3 + 128] = m - t; \
    m = q[(rb) + 44 + 0]; \
    n = q[(rb) + 44 + 0 + 128]; \
    t = REDS2(n * alpha_tab[44 + 0 * 1]); \
    q[(rb) + 44 + 0] = m + t; \
    q[(rb) + 44 + 0 + 128] = m - t; \
    m = q[(rb) + 44 + 1]; \
    n = q[(rb) + 44 + 1 + 128]; \
    t = REDS2(n * alpha_tab[44 + 1 * 1]); \
    q[(rb) + 44 + 1] = m + t; \
    q[(rb) + 44 + 1 + 128] = m - t; \
    m = q[(rb) + 44 + 2]; \
    n = q[(rb) + 44 + 2 + 128]; \
    t = REDS2(n * alpha_tab[44 + 2 * 1]); \
    q[(rb) + 44 + 2] = m + t; \
    q[(rb) + 44 + 2 + 128] = m - t; \
    m = q[(rb) + 44 + 3]; \
    n = q[(rb) + 44 + 3 + 128]; \
    t = REDS2(n * alpha_tab[44 + 3 * 1]); \
    q[(rb) + 44 + 3] = m + t; \
    q[(rb) + 44 + 3 + 128] = m - t; \
    m = q[(rb) + 48 + 0]; \
    n = q[(rb) + 48 + 0 + 128]; \
    t = REDS2(n * alpha_tab[48 + 0 * 1]); \
    q[(rb) + 48 + 0] = m + t; \
    q[(rb) + 48 + 0 + 128] = m - t; \
    m = q[(rb) + 48 + 1]; \
    n = q[(rb) + 48 + 1 + 128]; \
    t = REDS2(n * alpha_tab[48 + 1 * 1]); \
    q[(rb) + 48 + 1] = m + t; \
    q[(rb) + 48 + 1 + 128] = m - t; \
    m = q[(rb) + 48 + 2]; \
    n = q[(rb) + 48 + 2 + 128]; \
    t = REDS2(n * alpha_tab[48 + 2 * 1]); \
    q[(rb) + 48 + 2] = m + t; \
    q[(rb) + 48 + 2 + 128] = m - t; \
    m = q[(rb) + 48 + 3]; \
    n = q[(rb) + 48 + 3 + 128]; \
    t = REDS2(n * alpha_tab[48 + 3 * 1]); \
    q[(rb) + 48 + 3] = m + t; \
    q[(rb) + 48 + 3 + 128] = m - t; \
    m = q[(rb) + 52 + 0]; \
    n = q[(rb) + 52 + 0 + 128]; \
    t = REDS2(n * alpha_tab[52 + 0 * 1]); \
    q[(rb) + 52 + 0] = m + t; \
    q[(rb) + 52 + 0 + 128] = m - t; \
    m = q[(rb) + 52 + 1]; \
    n = q[(rb) + 52 + 1 + 128]; \
    t = REDS2(n * alpha_tab[52 + 1 * 1]); \
    q[(rb) + 52 + 1] = m + t; \
    q[(rb) + 52 + 1 + 128] = m - t; \
    m = q[(rb) + 52 + 2]; \
    n = q[(rb) + 52 + 2 + 128]; \
    t = REDS2(n * alpha_tab[52 + 2 * 1]); \
    q[(rb) + 52 + 2] = m + t; \
    q[(rb) + 52 + 2 + 128] = m - t; \
    m = q[(rb) + 52 + 3]; \
    n = q[(rb) + 52 + 3 + 128]; \
    t = REDS2(n * alpha_tab[52 + 3 * 1]); \
    q[(rb) + 52 + 3] = m + t; \
    q[(rb) + 52 + 3 + 128] = m - t; \
    m = q[(rb) + 56 + 0]; \
    n = q[(rb) + 56 + 0 + 128]; \
    t = REDS2(n * alpha_tab[56 + 0 * 1]); \
    q[(rb) + 56 + 0] = m + t; \
    q[(rb) + 56 + 0 + 128] = m - t; \
    m = q[(rb) + 56 + 1]; \
    n = q[(rb) + 56 + 1 + 128]; \
    t = REDS2(n * alpha_tab[56 + 1 * 1]); \
    q[(rb) + 56 + 1] = m + t; \
    q[(rb) + 56 + 1 + 128] = m - t; \
    m = q[(rb) + 56 + 2]; \
    n = q[(rb) + 56 + 2 + 128]; \
    t = REDS2(n * alpha_tab[56 + 2 * 1]); \
    q[(rb) + 56 + 2] = m + t; \
    q[(rb) + 56 + 2 + 128] = m - t; \
    m = q[(rb) + 56 + 3]; \
    n = q[(rb) + 56 + 3 + 128]; \
    t = REDS2(n * alpha_tab[56 + 3 * 1]); \
    q[(rb) + 56 + 3] = m + t; \
    q[(rb) + 56 + 3 + 128] = m - t; \
    m = q[(rb) + 60 + 0]; \
    n = q[(rb) + 60 + 0 + 128]; \
    t = REDS2(n * alpha_tab[60 + 0 * 1]); \
    q[(rb) + 60 + 0] = m + t; \
    q[(rb) + 60 + 0 + 128] = m - t; \
    m = q[(rb) + 60 + 1]; \
    n = q[(rb) + 60 + 1 + 128]; \
    t = REDS2(n * alpha_tab[60 + 1 * 1]); \
    q[(rb) + 60 + 1] = m + t; \
    q[(rb) + 60 + 1 + 128] = m - t; \
    m = q[(rb) + 60 + 2]; \
    n = q[(rb) + 60 + 2 + 128]; \
    t = REDS2(n * alpha_tab[60 + 2 * 1]); \
    q[(rb) + 60 + 2] = m + t; \
    q[(rb) + 60 + 2 + 128] = m - t; \
    m = q[(rb) + 60 + 3]; \
    n = q[(rb) + 60 + 3 + 128]; \
    t = REDS2(n * alpha_tab[60 + 3 * 1]); \
    q[(rb) + 60 + 3] = m + t; \
    q[(rb) + 60 + 3 + 128] = m - t; \
    m = q[(rb) + 64 + 0]; \
    n = q[(rb) + 64 + 0 + 128]; \
    t = REDS2(n * alpha_tab[64 + 0 * 1]); \
    q[(rb) + 64 + 0] = m + t; \
    q[(rb) + 64 + 0 + 128] = m - t; \
    m = q[(rb) + 64 + 1]; \
    n = q[(rb) + 64 + 1 + 128]; \
    t = REDS2(n * alpha_tab[64 + 1 * 1]); \
    q[(rb) + 64 + 1] = m + t; \
    q[(rb) + 64 + 1 + 128] = m - t; \
    m = q[(rb) + 64 + 2]; \
    n = q[(rb) + 64 + 2 + 128]; \
    t = REDS2(n * alpha_tab[64 + 2 * 1]); \
    q[(rb) + 64 + 2] = m + t; \
    q[(rb) + 64 + 2 + 128] = m - t; \
    m = q[(rb) + 64 + 3]; \
    n = q[(rb) + 64 + 3 + 128]; \
    t = REDS2(n * alpha_tab[64 + 3 * 1]); \
    q[(rb) + 64 + 3] = m + t; \
    q[(rb) + 64 + 3 + 128] = m - t; \
    m = q[(rb) + 68 + 0]; \
    n = q[(rb) + 68 + 0 + 128]; \
    t = REDS2(n * alpha_tab[68 + 0 * 1]); \
    q[(rb) + 68 + 0] = m + t; \
    q[(rb) + 68 + 0 + 128] = m - t; \
    m = q[(rb) + 68 + 1]; \
    n = q[(rb) + 68 + 1 + 128]; \
    t = REDS2(n * alpha_tab[68 + 1 * 1]); \
    q[(rb) + 68 + 1] = m + t; \
    q[(rb) + 68 + 1 + 128] = m - t; \
    m = q[(rb) + 68 + 2]; \
    n = q[(rb) + 68 + 2 + 128]; \
    t = REDS2(n * alpha_tab[68 + 2 * 1]); \
    q[(rb) + 68 + 2] = m + t; \
    q[(rb) + 68 + 2 + 128] = m - t; \
    m = q[(rb) + 68 + 3]; \
    n = q[(rb) + 68 + 3 + 128]; \
    t = REDS2(n * alpha_tab[68 + 3 * 1]); \
    q[(rb) + 68 + 3] = m + t; \
    q[(rb) + 68 + 3 + 128] = m - t; \
    m = q[(rb) + 72 + 0]; \
    n = q[(rb) + 72 + 0 + 128]; \
    t = REDS2(n * alpha_tab[72 + 0 * 1]); \
    q[(rb) + 72 + 0] = m + t; \
    q[(rb) + 72 + 0 + 128] = m - t; \
    m = q[(rb) + 72 + 1]; \
    n = q[(rb) + 72 + 1 + 128]; \
    t = REDS2(n * alpha_tab[72 + 1 * 1]); \
    q[(rb) + 72 + 1] = m + t; \
    q[(rb) + 72 + 1 + 128] = m - t; \
    m = q[(rb) + 72 + 2]; \
    n = q[(rb) + 72 + 2 + 128]; \
    t = REDS2(n * alpha_tab[72 + 2 * 1]); \
    q[(rb) + 72 + 2] = m + t; \
    q[(rb) + 72 + 2 + 128] = m - t; \
    m = q[(rb) + 72 + 3]; \
    n = q[(rb) + 72 + 3 + 128]; \
    t = REDS2(n * alpha_tab[72 + 3 * 1]); \
    q[(rb) + 72 + 3] = m + t; \
    q[(rb) + 72 + 3 + 128] = m - t; \
    m = q[(rb) + 76 + 0]; \
    n = q[(rb) + 76 + 0 + 128]; \
    t = REDS2(n * alpha_tab[76 + 0 * 1]); \
    q[(rb) + 76 + 0] = m + t; \
    q[(rb) + 76 + 0 + 128] = m - t; \
    m = q[(rb) + 76 + 1]; \
    n = q[(rb) + 76 + 1 + 128]; \
    t = REDS2(n * alpha_tab[76 + 1 * 1]); \
    q[(rb) + 76 + 1] = m + t; \
    q[(rb) + 76 + 1 + 128] = m - t; \
    m = q[(rb) + 76 + 2]; \
    n = q[(rb) + 76 + 2 + 128]; \
    t = REDS2(n * alpha_tab[76 + 2 * 1]); \
    q[(rb) + 76 + 2] = m + t; \
    q[(rb) + 76 + 2 + 128] = m - t; \
    m = q[(rb) + 76 + 3]; \
    n = q[(rb) + 76 + 3 + 128]; \
    t = REDS2(n * alpha_tab[76 + 3 * 1]); \
    q[(rb) + 76 + 3] = m + t; \
    q[(rb) + 76 + 3 + 128] = m - t; \
    m = q[(rb) + 80 + 0]; \
    n = q[(rb) + 80 + 0 + 128]; \
    t = REDS2(n * alpha_tab[80 + 0 * 1]); \
    q[(rb) + 80 + 0] = m + t; \
    q[(rb) + 80 + 0 + 128] = m - t; \
    m = q[(rb) + 80 + 1]; \
    n = q[(rb) + 80 + 1 + 128]; \
    t = REDS2(n * alpha_tab[80 + 1 * 1]); \
    q[(rb) + 80 + 1] = m + t; \
    q[(rb) + 80 + 1 + 128] = m - t; \
    m = q[(rb) + 80 + 2]; \
    n = q[(rb) + 80 + 2 + 128]; \
    t = REDS2(n * alpha_tab[80 + 2 * 1]); \
    q[(rb) + 80 + 2] = m + t; \
    q[(rb) + 80 + 2 + 128] = m - t; \
    m = q[(rb) + 80 + 3]; \
    n = q[(rb) + 80 + 3 + 128]; \
    t = REDS2(n * alpha_tab[80 + 3 * 1]); \
    q[(rb) + 80 + 3] = m + t; \
    q[(rb) + 80 + 3 + 128] = m - t; \
    m = q[(rb) + 84 + 0]; \
    n = q[(rb) + 84 + 0 + 128]; \
    t = REDS2(n * alpha_tab[84 + 0 * 1]); \
    q[(rb) + 84 + 0] = m + t; \
    q[(rb) + 84 + 0 + 128] = m - t; \
    m = q[(rb) + 84 + 1]; \
    n = q[(rb) + 84 + 1 + 128]; \
    t = REDS2(n * alpha_tab[84 + 1 * 1]); \
    q[(rb) + 84 + 1] = m + t; \
    q[(rb) + 84 + 1 + 128] = m - t; \
    m = q[(rb) + 84 + 2]; \
    n = q[(rb) + 84 + 2 + 128]; \
    t = REDS2(n * alpha_tab[84 + 2 * 1]); \
    q[(rb) + 84 + 2] = m + t; \
    q[(rb) + 84 + 2 + 128] = m - t; \
    m = q[(rb) + 84 + 3]; \
    n = q[(rb) + 84 + 3 + 128]; \
    t = REDS2(n * alpha_tab[84 + 3 * 1]); \
    q[(rb) + 84 + 3] = m + t; \
    q[(rb) + 84 + 3 + 128] = m - t; \
    m = q[(rb) + 88 + 0]; \
    n = q[(rb) + 88 + 0 + 128]; \
    t = REDS2(n * alpha_tab[88 + 0 * 1]); \
    q[(rb) + 88 + 0] = m + t; \
    q[(rb) + 88 + 0 + 128] = m - t; \
    m = q[(rb) + 88 + 1]; \
    n = q[(rb) + 88 + 1 + 128]; \
    t = REDS2(n * alpha_tab[88 + 1 * 1]); \
    q[(rb) + 88 + 1] = m + t; \
    q[(rb) + 88 + 1 + 128] = m - t; \
    m = q[(rb) + 88 + 2]; \
    n = q[(rb) + 88 + 2 + 128]; \
    t = REDS2(n * alpha_tab[88 + 2 * 1]); \
    q[(rb) + 88 + 2] = m + t; \
    q[(rb) + 88 + 2 + 128] = m - t; \
    m = q[(rb) + 88 + 3]; \
    n = q[(rb) + 88 + 3 + 128]; \
    t = REDS2(n * alpha_tab[88 + 3 * 1]); \
    q[(rb) + 88 + 3] = m + t; \
    q[(rb) + 88 + 3 + 128] = m - t; \
    m = q[(rb) + 92 + 0]; \
    n = q[(rb) + 92 + 0 + 128]; \
    t = REDS2(n * alpha_tab[92 + 0 * 1]); \
    q[(rb) + 92 + 0] = m + t; \
    q[(rb) + 92 + 0 + 128] = m - t; \
    m = q[(rb) + 92 + 1]; \
    n = q[(rb) + 92 + 1 + 128]; \
    t = REDS2(n * alpha_tab[92 + 1 * 1]); \
    q[(rb) + 92 + 1] = m + t; \
    q[(rb) + 92 + 1 + 128] = m - t; \
    m = q[(rb) + 92 + 2]; \
    n = q[(rb) + 92 + 2 + 128]; \
    t = REDS2(n * alpha_tab[92 + 2 * 1]); \
    q[(rb) + 92 + 2] = m + t; \
    q[(rb) + 92 + 2 + 128] = m - t; \
    m = q[(rb) + 92 + 3]; \
    n = q[(rb) + 92 + 3 + 128]; \
    t = REDS2(n * alpha_tab[92 + 3 * 1]); \
    q[(rb) + 92 + 3] = m + t; \
    q[(rb) + 92 + 3 + 128] = m - t; \
    m = q[(rb) + 96 + 0]; \
    n = q[(rb) + 96 + 0 + 128]; \
    t = REDS2(n * alpha_tab[96 + 0 * 1]); \
    q[(rb) + 96 + 0] = m + t; \
    q[(rb) + 96 + 0 + 128] = m - t; \
    m = q[(rb) + 96 + 1]; \
    n = q[(rb) + 96 + 1 + 128]; \
    t = REDS2(n * alpha_tab[96 + 1 * 1]); \
    q[(rb) + 96 + 1] = m + t; \
    q[(rb) + 96 + 1 + 128] = m - t; \
    m = q[(rb) + 96 + 2]; \
    n = q[(rb) + 96 + 2 + 128]; \
    t = REDS2(n * alpha_tab[96 + 2 * 1]); \
    q[(rb) + 96 + 2] = m + t; \
    q[(rb) + 96 + 2 + 128] = m - t; \
    m = q[(rb) + 96 + 3]; \
    n = q[(rb) + 96 + 3 + 128]; \
    t = REDS2(n * alpha_tab[96 + 3 * 1]); \
    q[(rb) + 96 + 3] = m + t; \
    q[(rb) + 96 + 3 + 128] = m - t; \
    m = q[(rb) + 100 + 0]; \
    n = q[(rb) + 100 + 0 + 128]; \
    t = REDS2(n * alpha_tab[100 + 0 * 1]); \
    q[(rb) + 100 + 0] = m + t; \
    q[(rb) + 100 + 0 + 128] = m - t; \
    m = q[(rb) + 100 + 1]; \
    n = q[(rb) + 100 + 1 + 128]; \
    t = REDS2(n * alpha_tab[100 + 1 * 1]); \
    q[(rb) + 100 + 1] = m + t; \
    q[(rb) + 100 + 1 + 128] = m - t; \
    m = q[(rb) + 100 + 2]; \
    n = q[(rb) + 100 + 2 + 128]; \
    t = REDS2(n * alpha_tab[100 + 2 * 1]); \
    q[(rb) + 100 + 2] = m + t; \
    q[(rb) + 100 + 2 + 128] = m - t; \
    m = q[(rb) + 100 + 3]; \
    n = q[(rb) + 100 + 3 + 128]; \
    t = REDS2(n * alpha_tab[100 + 3 * 1]); \
    q[(rb) + 100 + 3] = m + t; \
    q[(rb) + 100 + 3 + 128] = m - t; \
    m = q[(rb) + 104 + 0]; \
    n = q[(rb) + 104 + 0 + 128]; \
    t = REDS2(n * alpha_tab[104 + 0 * 1]); \
    q[(rb) + 104 + 0] = m + t; \
    q[(rb) + 104 + 0 + 128] = m - t; \
    m = q[(rb) + 104 + 1]; \
    n = q[(rb) + 104 + 1 + 128]; \
    t = REDS2(n * alpha_tab[104 + 1 * 1]); \
    q[(rb) + 104 + 1] = m + t; \
    q[(rb) + 104 + 1 + 128] = m - t; \
    m = q[(rb) + 104 + 2]; \
    n = q[(rb) + 104 + 2 + 128]; \
    t = REDS2(n * alpha_tab[104 + 2 * 1]); \
    q[(rb) + 104 + 2] = m + t; \
    q[(rb) + 104 + 2 + 128] = m - t; \
    m = q[(rb) + 104 + 3]; \
    n = q[(rb) + 104 + 3 + 128]; \
    t = REDS2(n * alpha_tab[104 + 3 * 1]); \
    q[(rb) + 104 + 3] = m + t; \
    q[(rb) + 104 + 3 + 128] = m - t; \
    m = q[(rb) + 108 + 0]; \
    n = q[(rb) + 108 + 0 + 128]; \
    t = REDS2(n * alpha_tab[108 + 0 * 1]); \
    q[(rb) + 108 + 0] = m + t; \
    q[(rb) + 108 + 0 + 128] = m - t; \
    m = q[(rb) + 108 + 1]; \
    n = q[(rb) + 108 + 1 + 128]; \
    t = REDS2(n * alpha_tab[108 + 1 * 1]); \
    q[(rb) + 108 + 1] = m + t; \
    q[(rb) + 108 + 1 + 128] = m - t; \
    m = q[(rb) + 108 + 2]; \
    n = q[(rb) + 108 + 2 + 128]; \
    t = REDS2(n * alpha_tab[108 + 2 * 1]); \
    q[(rb) + 108 + 2] = m + t; \
    q[(rb) + 108 + 2 + 128] = m - t; \
    m = q[(rb) + 108 + 3]; \
    n = q[(rb) + 108 + 3 + 128]; \
    t = REDS2(n * alpha_tab[108 + 3 * 1]); \
    q[(rb) + 108 + 3] = m + t; \
    q[(rb) + 108 + 3 + 128] = m - t; \
    m = q[(rb) + 112 + 0]; \
    n = q[(rb) + 112 + 0 + 128]; \
    t = REDS2(n * alpha_tab[112 + 0 * 1]); \
    q[(rb) + 112 + 0] = m + t; \
    q[(rb) + 112 + 0 + 128] = m - t; \
    m = q[(rb) + 112 + 1]; \
    n = q[(rb) + 112 + 1 + 128]; \
    t = REDS2(n * alpha_tab[112 + 1 * 1]); \
    q[(rb) + 112 + 1] = m + t; \
    q[(rb) + 112 + 1 + 128] = m - t; \
    m = q[(rb) + 112 + 2]; \
    n = q[(rb) + 112 + 2 + 128]; \
    t = REDS2(n * alpha_tab[112 + 2 * 1]); \
    q[(rb) + 112 + 2] = m + t; \
    q[(rb) + 112 + 2 + 128] = m - t; \
    m = q[(rb) + 112 + 3]; \
    n = q[(rb) + 112 + 3 + 128]; \
    t = REDS2(n * alpha_tab[112 + 3 * 1]); \
    q[(rb) + 112 + 3] = m + t; \
    q[(rb) + 112 + 3 + 128] = m - t; \
    m = q[(rb) + 116 + 0]; \
    n = q[(rb) + 116 + 0 + 128]; \
    t = REDS2(n * alpha_tab[116 + 0 * 1]); \
    q[(rb) + 116 + 0] = m + t; \
    q[(rb) + 116 + 0 + 128] = m - t; \
    m = q[(rb) + 116 + 1]; \
    n = q[(rb) + 116 + 1 + 128]; \
    t = REDS2(n * alpha_tab[116 + 1 * 1]); \
    q[(rb) + 116 + 1] = m + t; \
    q[(rb) + 116 + 1 + 128] = m - t; \
    m = q[(rb) + 116 + 2]; \
    n = q[(rb) + 116 + 2 + 128]; \
    t = REDS2(n * alpha_tab[116 + 2 * 1]); \
    q[(rb) + 116 + 2] = m + t; \
    q[(rb) + 116 + 2 + 128] = m - t; \
    m = q[(rb) + 116 + 3]; \
    n = q[(rb) + 116 + 3 + 128]; \
    t = REDS2(n * alpha_tab[116 + 3 * 1]); \
    q[(rb) + 116 + 3] = m + t; \
    q[(rb) + 116 + 3 + 128] = m - t; \
    m = q[(rb) + 120 + 0]; \
    n = q[(rb) + 120 + 0 + 128]; \
    t = REDS2(n * alpha_tab[120 + 0 * 1]); \
    q[(rb) + 120 + 0] = m + t; \
    q[(rb) + 120 + 0 + 128] = m - t; \
    m = q[(rb) + 120 + 1]; \
    n = q[(rb) + 120 + 1 + 128]; \
    t = REDS2(n * alpha_tab[120 + 1 * 1]); \
    q[(rb) + 120 + 1] = m + t; \
    q[(rb) + 120 + 1 + 128] = m - t; \
    m = q[(rb) + 120 + 2]; \
    n = q[(rb) + 120 + 2 + 128]; \
    t = REDS2(n * alpha_tab[120 + 2 * 1]); \
    q[(rb) + 120 + 2] = m + t; \
    q[(rb) + 120 + 2 + 128] = m - t; \
    m = q[(rb) + 120 + 3]; \
    n = q[(rb) + 120 + 3 + 128]; \
    t = REDS2(n * alpha_tab[120 + 3 * 1]); \
    q[(rb) + 120 + 3] = m + t; \
    q[(rb) + 120 + 3 + 128] = m - t; \
    m = q[(rb) + 124 + 0]; \
    n = q[(rb) + 124 + 0 + 128]; \
    t = REDS2(n * alpha_tab[124 + 0 * 1]); \
    q[(rb) + 124 + 0] = m + t; \
    q[(rb) + 124 + 0 + 128] = m - t; \
    m = q[(rb) + 124 + 1]; \
    n = q[(rb) + 124 + 1 + 128]; \
    t = REDS2(n * alpha_tab[124 + 1 * 1]); \
    q[(rb) + 124 + 1] = m + t; \
    q[(rb) + 124 + 1 + 128] = m - t; \
    m = q[(rb) + 124 + 2]; \
    n = q[(rb) + 124 + 2 + 128]; \
    t = REDS2(n * alpha_tab[124 + 2 * 1]); \
    q[(rb) + 124 + 2] = m + t; \
    q[(rb) + 124 + 2 + 128] = m - t; \
    m = q[(rb) + 124 + 3]; \
    n = q[(rb) + 124 + 3 + 128]; \
    t = REDS2(n * alpha_tab[124 + 3 * 1]); \
    q[(rb) + 124 + 3] = m + t; \
    q[(rb) + 124 + 3 + 128] = m - t; \
  } while (0)

/*
 * Output ranges:
 *   d0:   min=    0   max= 1020
 *   d1:   min=  -67   max= 4587
 *   d2:   min=-4335   max= 4335
 *   d3:   min=-4147   max=  507
 *   d4:   min= -510   max=  510
 *   d5:   min= -252   max= 4402
 *   d6:   min=-4335   max= 4335
 *   d7:   min=-4332   max=  322
 */
#define FFT8(xb, xs, d)   do { \
    s32 x0 = x[(xb)]; \
    s32 x1 = x[(xb) + (xs)]; \
    s32 x2 = x[(xb) + 2 * (xs)]; \
    s32 x3 = x[(xb) + 3 * (xs)]; \
    s32 a0 = x0 + x2; \
    s32 a1 = x0 + (x2 << 4); \
    s32 a2 = x0 - x2; \
    s32 a3 = x0 - (x2 << 4); \
    s32 b0 = x1 + x3; \
    s32 b1 = REDS1((x1 << 2) + (x3 << 6)); \
    s32 b2 = (x1 << 4) - (x3 << 4); \
    s32 b3 = REDS1((x1 << 6) + (x3 << 2)); \
    d ## 0 = a0 + b0; \
    d ## 1 = a1 + b1; \
    d ## 2 = a2 + b2; \
    d ## 3 = a3 + b3; \
    d ## 4 = a0 - b0; \
    d ## 5 = a1 - b1; \
    d ## 6 = a2 - b2; \
    d ## 7 = a3 - b3; \
  } while (0)

/*
 * When k=16, we have alpha=2. Multiplication by alpha^i is then reduced
 * to some shifting.
 *
 * Output: within -591471..591723
 */
#define FFT16(xb, xs, rb)   do { \
    s32 d1_0, d1_1, d1_2, d1_3, d1_4, d1_5, d1_6, d1_7; \
    s32 d2_0, d2_1, d2_2, d2_3, d2_4, d2_5, d2_6, d2_7; \
    FFT8(xb, (xs) << 1, d1_); \
    FFT8((xb) + (xs), (xs) << 1, d2_); \
    q[(rb) +  0] = d1_0 + d2_0; \
    q[(rb) +  1] = d1_1 + (d2_1 << 1); \
    q[(rb) +  2] = d1_2 + (d2_2 << 2); \
    q[(rb) +  3] = d1_3 + (d2_3 << 3); \
    q[(rb) +  4] = d1_4 + (d2_4 << 4); \
    q[(rb) +  5] = d1_5 + (d2_5 << 5); \
    q[(rb) +  6] = d1_6 + (d2_6 << 6); \
    q[(rb) +  7] = d1_7 + (d2_7 << 7); \
    q[(rb) +  8] = d1_0 - d2_0; \
    q[(rb) +  9] = d1_1 - (d2_1 << 1); \
    q[(rb) + 10] = d1_2 - (d2_2 << 2); \
    q[(rb) + 11] = d1_3 - (d2_3 << 3); \
    q[(rb) + 12] = d1_4 - (d2_4 << 4); \
    q[(rb) + 13] = d1_5 - (d2_5 << 5); \
    q[(rb) + 14] = d1_6 - (d2_6 << 6); \
    q[(rb) + 15] = d1_7 - (d2_7 << 7); \
  } while (0)

/*
 * Output range: |q| <= 1183446
 */
#define FFT32(xb, xs, rb, id)   do { \
    FFT16(xb, (xs) << 1, rb); \
    FFT16((xb) + (xs), (xs) << 1, (rb) + 16); \
    FFT_LOOP_16_8(rb); \
  } while (0)

/*
 * Output range: |q| <= 2366892
 */
#define FFT64(xb, xs, rb)   do { \
  FFT32(xb, (xs) << 1, (rb), label_a); \
  FFT32((xb) + (xs), (xs) << 1, (rb) + 32, label_b); \
  FFT_LOOP_32_4(rb); \
  } while (0)

/*
 * Output range: |q| <= 9467568
 */
#define FFT256(xb, xs, rb, id)   do { \
    FFT64((xb) + ((xs) * 0), (xs) << 2, (rb + 0)); \
    FFT64((xb) + ((xs) * 2), (xs) << 2, (rb + 64)); \
    FFT_LOOP_64_2(rb); \
    FFT64((xb) + ((xs) * 1), (xs) << 2, (rb + 128)); \
    FFT64((xb) + ((xs) * 3), (xs) << 2, (rb + 192)); \
    FFT_LOOP_64_2((rb) + 128); \
    FFT_LOOP_128_1(rb); \
  } while (0)

/*
 * beta^(255*i) mod 257
 */
__constant const unsigned short yoff_b_n[] = {
    1, 163,  98,  40,  95,  65,  58, 202,  30,   7, 113, 172,
   23, 151, 198, 149, 129, 210,  49,  20, 176, 161,  29, 101,
   15, 132, 185,  86, 140, 204,  99, 203, 193, 105, 153,  10,
   88, 209, 143, 179, 136,  66, 221,  43,  70, 102, 178, 230,
  225, 181, 205,   5,  44, 233, 200, 218,  68,  33, 239, 150,
   35,  51,  89, 115, 241, 219, 231, 131,  22, 245, 100, 109,
   34, 145, 248,  75, 146, 154, 173, 186, 249, 238, 244, 194,
   11, 251,  50, 183,  17, 201, 124, 166,  73,  77, 215,  93,
  253, 119, 122,  97, 134, 254,  25, 220, 137, 229,  62,  83,
  165, 167, 236, 175, 255, 188,  61, 177,  67, 127, 141, 110,
  197, 243,  31, 170, 211, 212, 118, 216, 256,  94, 159, 217,
  162, 192, 199,  55, 227, 250, 144,  85, 234, 106,  59, 108,
  128,  47, 208, 237,  81,  96, 228, 156, 242, 125,  72, 171,
  117,  53, 158,  54,  64, 152, 104, 247, 169,  48, 114,  78,
  121, 191,  36, 214, 187, 155,  79,  27,  32,  76,  52, 252,
  213,  24,  57,  39, 189, 224,  18, 107, 222, 206, 168, 142,
   16,  38,  26, 126, 235,  12, 157, 148, 223, 112,   9, 182,
  111, 103,  84,  71,   8,  19,  13,  63, 246,   6, 207,  74,
  240,  56, 133,  91, 184, 180,  42, 164,   4, 138, 135, 160,
  123,   3, 232,  37, 120,  28, 195, 174,  92,  90,  21,  82,
    2,  69, 196,  80, 190, 130, 116, 147,  60,  14, 226,  87,
   46,  45, 139,  41
};

#define INNER(l, h, mm)   (((u32)((l) * (mm)) & 0xFFFFU) \
                          + ((u32)((h) * (mm)) << 16))

#define W_BIG(sb, o1, o2, mm) \
  (INNER(q[16 * (sb) + 2 * 0 + o1], q[16 * (sb) + 2 * 0 + o2], mm), \
   INNER(q[16 * (sb) + 2 * 1 + o1], q[16 * (sb) + 2 * 1 + o2], mm), \
   INNER(q[16 * (sb) + 2 * 2 + o1], q[16 * (sb) + 2 * 2 + o2], mm), \
   INNER(q[16 * (sb) + 2 * 3 + o1], q[16 * (sb) + 2 * 3 + o2], mm), \
   INNER(q[16 * (sb) + 2 * 4 + o1], q[16 * (sb) + 2 * 4 + o2], mm), \
   INNER(q[16 * (sb) + 2 * 5 + o1], q[16 * (sb) + 2 * 5 + o2], mm), \
   INNER(q[16 * (sb) + 2 * 6 + o1], q[16 * (sb) + 2 * 6 + o2], mm), \
   INNER(q[16 * (sb) + 2 * 7 + o1], q[16 * (sb) + 2 * 7 + o2], mm)

#define WB_0_0   W_BIG( 4,    0,    1, 185)
#define WB_0_1   W_BIG( 6,    0,    1, 185)
#define WB_0_2   W_BIG( 0,    0,    1, 185)
#define WB_0_3   W_BIG( 2,    0,    1, 185)
#define WB_0_4   W_BIG( 7,    0,    1, 185)
#define WB_0_5   W_BIG( 5,    0,    1, 185)
#define WB_0_6   W_BIG( 3,    0,    1, 185)
#define WB_0_7   W_BIG( 1,    0,    1, 185)
#define WB_1_0   W_BIG(15,    0,    1, 185)
#define WB_1_1   W_BIG(11,    0,    1, 185)
#define WB_1_2   W_BIG(12,    0,    1, 185)
#define WB_1_3   W_BIG( 8,    0,    1, 185)
#define WB_1_4   W_BIG( 9,    0,    1, 185)
#define WB_1_5   W_BIG(13,    0,    1, 185)
#define WB_1_6   W_BIG(10,    0,    1, 185)
#define WB_1_7   W_BIG(14,    0,    1, 185)
#define WB_2_0   W_BIG(17, -256, -128, 233)
#define WB_2_1   W_BIG(18, -256, -128, 233)
#define WB_2_2   W_BIG(23, -256, -128, 233)
#define WB_2_3   W_BIG(20, -256, -128, 233)
#define WB_2_4   W_BIG(22, -256, -128, 233)
#define WB_2_5   W_BIG(21, -256, -128, 233)
#define WB_2_6   W_BIG(16, -256, -128, 233)
#define WB_2_7   W_BIG(19, -256, -128, 233)
#define WB_3_0   W_BIG(30, -383, -255, 233)
#define WB_3_1   W_BIG(24, -383, -255, 233)
#define WB_3_2   W_BIG(25, -383, -255, 233)
#define WB_3_3   W_BIG(31, -383, -255, 233)
#define WB_3_4   W_BIG(27, -383, -255, 233)
#define WB_3_5   W_BIG(29, -383, -255, 233)
#define WB_3_6   W_BIG(28, -383, -255, 233)
#define WB_3_7   W_BIG(26, -383, -255, 233)

#define IF(x, y, z)    ((((y) ^ (z)) & (x)) ^ (z))
#define MAJ(x, y, z)   (((x) & (y)) | (((x) | (y)) & (z)))

#define PP4_0_0   1
#define PP4_0_1   0
#define PP4_0_2   3
#define PP4_0_3   2
#define PP4_1_0   2
#define PP4_1_1   3
#define PP4_1_2   0
#define PP4_1_3   1
#define PP4_2_0   3
#define PP4_2_1   2
#define PP4_2_2   1
#define PP4_2_3   0

#define PP8_0_0   1
#define PP8_0_1   0
#define PP8_0_2   3
#define PP8_0_3   2
#define PP8_0_4   5
#define PP8_0_5   4
#define PP8_0_6   7
#define PP8_0_7   6

#define PP8_1_0   6
#define PP8_1_1   7
#define PP8_1_2   4
#define PP8_1_3   5
#define PP8_1_4   2
#define PP8_1_5   3
#define PP8_1_6   0
#define PP8_1_7   1

#define PP8_2_0   2
#define PP8_2_1   3
#define PP8_2_2   0
#define PP8_2_3   1
#define PP8_2_4   6
#define PP8_2_5   7
#define PP8_2_6   4
#define PP8_2_7   5

#define PP8_3_0   3
#define PP8_3_1   2
#define PP8_3_2   1
#define PP8_3_3   0
#define PP8_3_4   7
#define PP8_3_5   6
#define PP8_3_6   5
#define PP8_3_7   4

#define PP8_4_0   5
#define PP8_4_1   4
#define PP8_4_2   7
#define PP8_4_3   6
#define PP8_4_4   1
#define PP8_4_5   0
#define PP8_4_6   3
#define PP8_4_7   2

#define PP8_5_0   7
#define PP8_5_1   6
#define PP8_5_2   5
#define PP8_5_3   4
#define PP8_5_4   3
#define PP8_5_5   2
#define PP8_5_6   1
#define PP8_5_7   0

#define PP8_6_0   4
#define PP8_6_1   5
#define PP8_6_2   6
#define PP8_6_3   7
#define PP8_6_4   0
#define PP8_6_5   1
#define PP8_6_6   2
#define PP8_6_7   3

#define STEP_ELT(n, w, fun, s, ppb)   do { \
    u32 tt = T32(D ## n + (w) + fun(A ## n, B ## n, C ## n)); \
    A ## n = T32(ROL32(tt, s) + XCAT(tA, XCAT(ppb, n))); \
    D ## n = C ## n; \
    C ## n = B ## n; \
    B ## n = tA ## n; \
  } while (0)

#define STEP_BIG(w0, w1, w2, w3, w4, w5, w6, w7, fun, r, s, pp8b)   do { \
    u32 tA0 = ROL32(A0, r); \
    u32 tA1 = ROL32(A1, r); \
    u32 tA2 = ROL32(A2, r); \
    u32 tA3 = ROL32(A3, r); \
    u32 tA4 = ROL32(A4, r); \
    u32 tA5 = ROL32(A5, r); \
    u32 tA6 = ROL32(A6, r); \
    u32 tA7 = ROL32(A7, r); \
    STEP_ELT(0, w0, fun, s, pp8b); \
    STEP_ELT(1, w1, fun, s, pp8b); \
    STEP_ELT(2, w2, fun, s, pp8b); \
    STEP_ELT(3, w3, fun, s, pp8b); \
    STEP_ELT(4, w4, fun, s, pp8b); \
    STEP_ELT(5, w5, fun, s, pp8b); \
    STEP_ELT(6, w6, fun, s, pp8b); \
    STEP_ELT(7, w7, fun, s, pp8b); \
  } while (0)

#define SIMD_M3_0_0   0_
#define SIMD_M3_1_0   1_
#define SIMD_M3_2_0   2_
#define SIMD_M3_3_0   0_
#define SIMD_M3_4_0   1_
#define SIMD_M3_5_0   2_
#define SIMD_M3_6_0   0_
#define SIMD_M3_7_0   1_

#define SIMD_M3_0_1   1_
#define SIMD_M3_1_1   2_
#define SIMD_M3_2_1   0_
#define SIMD_M3_3_1   1_
#define SIMD_M3_4_1   2_
#define SIMD_M3_5_1   0_
#define SIMD_M3_6_1   1_
#define SIMD_M3_7_1   2_

#define SIMD_M3_0_2   2_
#define SIMD_M3_1_2   0_
#define SIMD_M3_2_2   1_
#define SIMD_M3_3_2   2_
#define SIMD_M3_4_2   0_
#define SIMD_M3_5_2   1_
#define SIMD_M3_6_2   2_
#define SIMD_M3_7_2   0_

#define M7_0_0   0_
#define M7_1_0   1_
#define M7_2_0   2_
#define M7_3_0   3_
#define M7_4_0   4_
#define M7_5_0   5_
#define M7_6_0   6_
#define M7_7_0   0_

#define M7_0_1   1_
#define M7_1_1   2_
#define M7_2_1   3_
#define M7_3_1   4_
#define M7_4_1   5_
#define M7_5_1   6_
#define M7_6_1   0_
#define M7_7_1   1_

#define M7_0_2   2_
#define M7_1_2   3_
#define M7_2_2   4_
#define M7_3_2   5_
#define M7_4_2   6_
#define M7_5_2   0_
#define M7_6_2   1_
#define M7_7_2   2_

#define M7_0_3   3_
#define M7_1_3   4_
#define M7_2_3   5_
#define M7_3_3   6_
#define M7_4_3   0_
#define M7_5_3   1_
#define M7_6_3   2_
#define M7_7_3   3_

#define STEP_BIG_(w, fun, r, s, pp8b)   STEP_BIG w, fun, r, s, pp8b)

#define ONE_ROUND_BIG(ri, isp, p0, p1, p2, p3)   do { \
    STEP_BIG_(WB_ ## ri ## 0, \
      IF,  p0, p1, XCAT(PP8_, M7_0_ ## isp)); \
    STEP_BIG_(WB_ ## ri ## 1, \
      IF,  p1, p2, XCAT(PP8_, M7_1_ ## isp)); \
    STEP_BIG_(WB_ ## ri ## 2, \
      IF,  p2, p3, XCAT(PP8_, M7_2_ ## isp)); \
    STEP_BIG_(WB_ ## ri ## 3, \
      IF,  p3, p0, XCAT(PP8_, M7_3_ ## isp)); \
    STEP_BIG_(WB_ ## ri ## 4, \
      MAJ, p0, p1, XCAT(PP8_, M7_4_ ## isp)); \
    STEP_BIG_(WB_ ## ri ## 5, \
      MAJ, p1, p2, XCAT(PP8_, M7_5_ ## isp)); \
    STEP_BIG_(WB_ ## ri ## 6, \
      MAJ, p2, p3, XCAT(PP8_, M7_6_ ## isp)); \
    STEP_BIG_(WB_ ## ri ## 7, \
      MAJ, p3, p0, XCAT(PP8_, M7_7_ ## isp)); \
  } while (0)

__constant const u32 SIMD_IV512[] = {
  C32(0x0BA16B95), C32(0x72F999AD), C32(0x9FECC2AE), C32(0xBA3264FC),
  C32(0x5E894929), C32(0x8E9F30E5), C32(0x2F1DAA37), C32(0xF0F2C558),
  C32(0xAC506643), C32(0xA90635A5), C32(0xE25B878B), C32(0xAAB7878F),
  C32(0x88817F7A), C32(0x0A02892B), C32(0x559A7550), C32(0x598F657E),
  C32(0x7EEF60A1), C32(0x6B70E3E8), C32(0x9C1714D1), C32(0xB958E2A8),
  C32(0xAB02675E), C32(0xED1C014F), C32(0xCD8D65BB), C32(0xFDB7A257),
  C32(0x09254899), C32(0xD699C7BC), C32(0x9019B6DC), C32(0x2B9022E4),
  C32(0x8FA14956), C32(0x21BF9BD3), C32(0xB94D0943), C32(0x6FFDDC22)
};

/* $Id: echo.c 227 2010-06-16 17:28:38Z tp $ */
/*
 * ECHO implementation.
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

#define T32   SPH_T32
#define C32   SPH_C32
#if SPH_64
#define C64   SPH_C64
#endif


#define ECHO_DECL_STATE_BIG   \
  sph_u64 W00, W01, W10, W11, W20, W21, W30, W31, W40, W41, W50, W51, W60, W61, W70, W71, W80, W81, W90, W91, WA0, WA1, WB0, WB1, WC0, WC1, WD0, WD1, WE0, WE1, WF0, WF1;

#define AES_2ROUNDS(XX, XY)   do { \
    sph_u32 X0 = (sph_u32)(XX); \
    sph_u32 X1 = (sph_u32)(XX >> 32); \
    sph_u32 X2 = (sph_u32)(XY); \
    sph_u32 X3 = (sph_u32)(XY >> 32); \
    sph_u32 Y0, Y1, Y2, Y3; \
    AES_ROUND_LE(X0, X1, X2, X3, K0, K1, K2, K3, Y0, Y1, Y2, Y3); \
    AES_ROUND_NOKEY_LE(Y0, Y1, Y2, Y3, X0, X1, X2, X3); \
    XX = (sph_u64)X0 | ((sph_u64)X1 << 32); \
    XY = (sph_u64)X2 | ((sph_u64)X3 << 32); \
    if ((K0 = T32(K0 + 1)) == 0) { \
      if ((K1 = T32(K1 + 1)) == 0) \
        if ((K2 = T32(K2 + 1)) == 0) \
          K3 = T32(K3 + 1); \
    } \
  } while (0)

#define BIG_SUB_WORDS   do { \
    AES_2ROUNDS(W00, W01); \
    AES_2ROUNDS(W10, W11); \
    AES_2ROUNDS(W20, W21); \
    AES_2ROUNDS(W30, W31); \
    AES_2ROUNDS(W40, W41); \
    AES_2ROUNDS(W50, W51); \
    AES_2ROUNDS(W60, W61); \
    AES_2ROUNDS(W70, W71); \
    AES_2ROUNDS(W80, W81); \
    AES_2ROUNDS(W90, W91); \
    AES_2ROUNDS(WA0, WA1); \
    AES_2ROUNDS(WB0, WB1); \
    AES_2ROUNDS(WC0, WC1); \
    AES_2ROUNDS(WD0, WD1); \
    AES_2ROUNDS(WE0, WE1); \
    AES_2ROUNDS(WF0, WF1); \
  } while (0)

#define SHIFT_ROW1(a, b, c, d)   do { \
    sph_u64 tmp; \
    tmp = W ## a ## 0; \
    W ## a ## 0 = W ## b ## 0; \
    W ## b ## 0 = W ## c ## 0; \
    W ## c ## 0 = W ## d ## 0; \
    W ## d ## 0 = tmp; \
    tmp = W ## a ## 1; \
    W ## a ## 1 = W ## b ## 1; \
    W ## b ## 1 = W ## c ## 1; \
    W ## c ## 1 = W ## d ## 1; \
    W ## d ## 1 = tmp; \
  } while (0)

#define SHIFT_ROW2(a, b, c, d)   do { \
    sph_u64 tmp; \
    tmp = W ## a ## 0; \
    W ## a ## 0 = W ## c ## 0; \
    W ## c ## 0 = tmp; \
    tmp = W ## b ## 0; \
    W ## b ## 0 = W ## d ## 0; \
    W ## d ## 0 = tmp; \
    tmp = W ## a ## 1; \
    W ## a ## 1 = W ## c ## 1; \
    W ## c ## 1 = tmp; \
    tmp = W ## b ## 1; \
    W ## b ## 1 = W ## d ## 1; \
    W ## d ## 1 = tmp; \
  } while (0)

#define SHIFT_ROW3(a, b, c, d)   SHIFT_ROW1(d, c, b, a)

#define BIG_SHIFT_ROWS   do { \
    SHIFT_ROW1(1, 5, 9, D); \
    SHIFT_ROW2(2, 6, A, E); \
    SHIFT_ROW3(3, 7, B, F); \
  } while (0)

#define MIX_COLUMN1(ia, ib, ic, id, n)   do { \
    sph_u64 a = W ## ia ## n; \
    sph_u64 b = W ## ib ## n; \
    sph_u64 c = W ## ic ## n; \
    sph_u64 d = W ## id ## n; \
    sph_u64 ab = a ^ b; \
    sph_u64 bc = b ^ c; \
    sph_u64 cd = c ^ d; \
    sph_u64 abx = ((ab & C64(0x8080808080808080)) >> 7) * 27U \
      ^ ((ab & C64(0x7F7F7F7F7F7F7F7F)) << 1); \
    sph_u64 bcx = ((bc & C64(0x8080808080808080)) >> 7) * 27U \
      ^ ((bc & C64(0x7F7F7F7F7F7F7F7F)) << 1); \
    sph_u64 cdx = ((cd & C64(0x8080808080808080)) >> 7) * 27U \
      ^ ((cd & C64(0x7F7F7F7F7F7F7F7F)) << 1); \
    W ## ia ## n = abx ^ bc ^ d; \
    W ## ib ## n = bcx ^ a ^ cd; \
    W ## ic ## n = cdx ^ ab ^ d; \
    W ## id ## n = abx ^ bcx ^ cdx ^ ab ^ c; \
  } while (0)

#define MIX_COLUMN(a, b, c, d)   do { \
    MIX_COLUMN1(a, b, c, d, 0); \
    MIX_COLUMN1(a, b, c, d, 1); \
  } while (0)

#define BIG_MIX_COLUMNS   do { \
    MIX_COLUMN(0, 1, 2, 3); \
    MIX_COLUMN(4, 5, 6, 7); \
    MIX_COLUMN(8, 9, A, B); \
    MIX_COLUMN(C, D, E, F); \
  } while (0)

#define BIG_ROUND   do { \
    BIG_SUB_WORDS; \
    BIG_SHIFT_ROWS; \
    BIG_MIX_COLUMNS; \
  } while (0)

#define ECHO_COMPRESS_BIG(sc)   do { \
    sph_u32 K0 = sc->C0; \
    sph_u32 K1 = sc->C1; \
    sph_u32 K2 = sc->C2; \
    sph_u32 K3 = sc->C3; \
    unsigned u; \
    INPUT_BLOCK_BIG(sc); \
    for (u = 0; u < 10; u ++) { \
      BIG_ROUND; \
    } \
    ECHO_FINAL_BIG; \
  } while (0)


#define SWAP4(x) as_uint(as_uchar4(x).wzyx)
#define SWAP8(x) as_ulong(as_uchar8(x).s76543210)

#if SPH_BIG_ENDIAN
    #define DEC64E(x) (x)
    #define DEC64BE(x) (*(const __global sph_u64 *) (x));
#else
    #define DEC64E(x) SWAP8(x)
    #define DEC64BE(x) SWAP8(*(const __global sph_u64 *) (x));
#endif

typedef union {
    unsigned char h1[64];
    uint h4[16];
    ulong h8[8];
} hash_t;

__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search(__global unsigned char* block, __global hash_t* hashes)
{
    uint gid = get_global_id(0);
    __global hash_t *hash = &(hashes[gid-get_global_offset(0)]);

  // blake
  {
   sph_u64 H0 = SPH_C64(0x6A09E667F3BCC908), H1 = SPH_C64(0xBB67AE8584CAA73B);
   sph_u64 H2 = SPH_C64(0x3C6EF372FE94F82B), H3 = SPH_C64(0xA54FF53A5F1D36F1);
   sph_u64 H4 = SPH_C64(0x510E527FADE682D1), H5 = SPH_C64(0x9B05688C2B3E6C1F);
   sph_u64 H6 = SPH_C64(0x1F83D9ABFB41BD6B), H7 = SPH_C64(0x5BE0CD19137E2179);
   sph_u64 S0 = 0, S1 = 0, S2 = 0, S3 = 0;
   sph_u64 T0 = SPH_C64(0xFFFFFFFFFFFFFC00) + (80 << 3), T1 = 0xFFFFFFFFFFFFFFFF;;

   if ((T0 = SPH_T64(T0 + 1024)) < 1024)
   {
     T1 = SPH_T64(T1 + 1);
   }
   sph_u64 M0, M1, M2, M3, M4, M5, M6, M7;
   sph_u64 M8, M9, MA, MB, MC, MD, ME, MF;
   sph_u64 V0, V1, V2, V3, V4, V5, V6, V7;
   sph_u64 V8, V9, VA, VB, VC, VD, VE, VF;
   M0 = DEC64BE(block +   0);
   M1 = DEC64BE(block +   8);
   M2 = DEC64BE(block +  16);
   M3 = DEC64BE(block +  24);
   M4 = DEC64BE(block +  32);
   M5 = DEC64BE(block +  40);
   M6 = DEC64BE(block +  48);
   M7 = DEC64BE(block +  56);
   M8 = DEC64BE(block +  64);
   M9 = DEC64BE(block +  72);
   M9 &= 0xFFFFFFFF00000000;
   M9 ^= SWAP4(gid);
   MA = 0x8000000000000000;
   MB = 0;
   MC = 0;
   MD = 1;
   ME = 0;
   MF = 0x280;

   COMPRESS64;

   hash->h8[0] = H0;
   hash->h8[1] = H1;
   hash->h8[2] = H2;
   hash->h8[3] = H3;
   hash->h8[4] = H4;
   hash->h8[5] = H5;
   hash->h8[6] = H6;
   hash->h8[7] = H7;
  }
  barrier(CLK_GLOBAL_MEM_FENCE);
}

__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search1(__global hash_t* hashes)
{
    uint gid = get_global_id(0);
    __global hash_t *hash = &(hashes[gid-get_global_offset(0)]);

    // bmw
    sph_u64 BMW_H[16];
    for(unsigned u = 0; u < 16; u++)
        BMW_H[u] = BMW_IV512[u];

    sph_u64 BMW_h1[16], BMW_h2[16];
    sph_u64 mv[16];

    mv[ 0] = SWAP8(hash->h8[0]);
    mv[ 1] = SWAP8(hash->h8[1]);
    mv[ 2] = SWAP8(hash->h8[2]);
    mv[ 3] = SWAP8(hash->h8[3]);
    mv[ 4] = SWAP8(hash->h8[4]);
    mv[ 5] = SWAP8(hash->h8[5]);
    mv[ 6] = SWAP8(hash->h8[6]);
    mv[ 7] = SWAP8(hash->h8[7]);
    mv[ 8] = 0x80;
    mv[ 9] = 0;
    mv[10] = 0;
    mv[11] = 0;
    mv[12] = 0;
    mv[13] = 0;
    mv[14] = 0;
    mv[15] = 0x200;
#define M(x)    (mv[x])
#define H(x)    (BMW_H[x])
#define dH(x)   (BMW_h2[x])

    FOLDb;

#undef M
#undef H
#undef dH

#define M(x)    (BMW_h2[x])
#define H(x)    (final_b[x])
#define dH(x)   (BMW_h1[x])

    FOLDb;

#undef M
#undef H
#undef dH

    hash->h8[0] = SWAP8(BMW_h1[8]);
    hash->h8[1] = SWAP8(BMW_h1[9]);
    hash->h8[2] = SWAP8(BMW_h1[10]);
    hash->h8[3] = SWAP8(BMW_h1[11]);
    hash->h8[4] = SWAP8(BMW_h1[12]);
    hash->h8[5] = SWAP8(BMW_h1[13]);
    hash->h8[6] = SWAP8(BMW_h1[14]);
    hash->h8[7] = SWAP8(BMW_h1[15]);
  barrier(CLK_GLOBAL_MEM_FENCE);

}
__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search2(__global hash_t* hashes)
{
    uint gid = get_global_id(0);
    __global hash_t *hash = &(hashes[gid-get_global_offset(0)]);

#if !SPH_SMALL_FOOTPRINT_GROESTL
    __local sph_u64 T0[256], T1[256], T2[256], T3[256];
    __local sph_u64 T4[256], T5[256], T6[256], T7[256];
#else
    __local sph_u64 T0[256], T4[256];
#endif
    int init = get_local_id(0);
    int step = get_local_size(0);
    for (int i = init; i < 256; i += step)
    {
        T0[i] = T0_C[i];
        T4[i] = T4_C[i];
#if !SPH_SMALL_FOOTPRINT_GROESTL
        T1[i] = T1_C[i];
        T2[i] = T2_C[i];
        T3[i] = T3_C[i];
        T5[i] = T5_C[i];
        T6[i] = T6_C[i];
        T7[i] = T7_C[i];
#endif
    }
    barrier(CLK_LOCAL_MEM_FENCE);    // groestl

    sph_u64 H[16];
    for (unsigned int u = 0; u < 15; u ++)
        H[u] = 0;
#if USE_LE
    H[15] = ((sph_u64)(512 & 0xFF) << 56) | ((sph_u64)(512 & 0xFF00) << 40);
#else
    H[15] = (sph_u64)512;
#endif

    sph_u64 g[16], m[16];
    m[0] = DEC64E(hash->h8[0]);
    m[1] = DEC64E(hash->h8[1]);
    m[2] = DEC64E(hash->h8[2]);
    m[3] = DEC64E(hash->h8[3]);
    m[4] = DEC64E(hash->h8[4]);
    m[5] = DEC64E(hash->h8[5]);
    m[6] = DEC64E(hash->h8[6]);
    m[7] = DEC64E(hash->h8[7]);
    for (unsigned int u = 0; u < 16; u ++)
        g[u] = m[u] ^ H[u];
    m[8] = 0x80; g[8] = m[8] ^ H[8];
    m[9] = 0; g[9] = m[9] ^ H[9];
    m[10] = 0; g[10] = m[10] ^ H[10];
    m[11] = 0; g[11] = m[11] ^ H[11];
    m[12] = 0; g[12] = m[12] ^ H[12];
    m[13] = 0; g[13] = m[13] ^ H[13];
    m[14] = 0; g[14] = m[14] ^ H[14];
    m[15] = 0x100000000000000; g[15] = m[15] ^ H[15];
    PERM_BIG_P(g);
    PERM_BIG_Q(m);
    for (unsigned int u = 0; u < 16; u ++)
        H[u] ^= g[u] ^ m[u];
    sph_u64 xH[16];
    for (unsigned int u = 0; u < 16; u ++)
        xH[u] = H[u];
    PERM_BIG_P(xH);
    for (unsigned int u = 0; u < 16; u ++)
        H[u] ^= xH[u];
    for (unsigned int u = 0; u < 8; u ++)
        hash->h8[u] = DEC64E(H[u + 8]);
  barrier(CLK_GLOBAL_MEM_FENCE);

}
__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search3(__global hash_t* hashes)
{
    uint gid = get_global_id(0);
    __global hash_t *hash = &(hashes[gid-get_global_offset(0)]);

    // skein

    sph_u64 h0 = SPH_C64(0x4903ADFF749C51CE), h1 = SPH_C64(0x0D95DE399746DF03), h2 = SPH_C64(0x8FD1934127C79BCE), h3 = SPH_C64(0x9A255629FF352CB1), h4 = SPH_C64(0x5DB62599DF6CA7B0), h5 = SPH_C64(0xEABE394CA9D5C3F4), h6 = SPH_C64(0x991112C71A75B523), h7 = SPH_C64(0xAE18A40B660FCC33);
    sph_u64 m0, m1, m2, m3, m4, m5, m6, m7;
    sph_u64 bcount = 0;

    m0 = SWAP8(hash->h8[0]);
    m1 = SWAP8(hash->h8[1]);
    m2 = SWAP8(hash->h8[2]);
    m3 = SWAP8(hash->h8[3]);
    m4 = SWAP8(hash->h8[4]);
    m5 = SWAP8(hash->h8[5]);
    m6 = SWAP8(hash->h8[6]);
    m7 = SWAP8(hash->h8[7]);
    UBI_BIG(480, 64);
    bcount = 0;
    m0 = m1 = m2 = m3 = m4 = m5 = m6 = m7 = 0;
    UBI_BIG(510, 8);
    hash->h8[0] = SWAP8(h0);
    hash->h8[1] = SWAP8(h1);
    hash->h8[2] = SWAP8(h2);
    hash->h8[3] = SWAP8(h3);
    hash->h8[4] = SWAP8(h4);
    hash->h8[5] = SWAP8(h5);
    hash->h8[6] = SWAP8(h6);
    hash->h8[7] = SWAP8(h7);

  barrier(CLK_GLOBAL_MEM_FENCE);
}
__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search4(__global hash_t* hashes)
{
    uint gid = get_global_id(0);
    __global hash_t *hash = &(hashes[gid-get_global_offset(0)]);

    // jh

     sph_u64 h0h = C64e(0x6fd14b963e00aa17), h0l = C64e(0x636a2e057a15d543), h1h = C64e(0x8a225e8d0c97ef0b), h1l = C64e(0xe9341259f2b3c361), h2h = C64e(0x891da0c1536f801e), h2l = C64e(0x2aa9056bea2b6d80), h3h = C64e(0x588eccdb2075baa6), h3l = C64e(0xa90f3a76baf83bf7);
     sph_u64 h4h = C64e(0x0169e60541e34a69), h4l = C64e(0x46b58a8e2e6fe65a), h5h = C64e(0x1047a7d0c1843c24), h5l = C64e(0x3b6e71b12d5ac199), h6h = C64e(0xcf57f6ec9db1f856), h6l = C64e(0xa706887c5716b156), h7h = C64e(0xe3c2fcdfe68517fb), h7l = C64e(0x545a4678cc8cdd4b);
     sph_u64 tmp;

     for(int i = 0; i < 2; i++)
     {
         if (i == 0) {
             h0h ^= DEC64E(hash->h8[0]);
             h0l ^= DEC64E(hash->h8[1]);
             h1h ^= DEC64E(hash->h8[2]);
             h1l ^= DEC64E(hash->h8[3]);
             h2h ^= DEC64E(hash->h8[4]);
             h2l ^= DEC64E(hash->h8[5]);
             h3h ^= DEC64E(hash->h8[6]);
             h3l ^= DEC64E(hash->h8[7]);
         } else if(i == 1) {
             h4h ^= DEC64E(hash->h8[0]);
             h4l ^= DEC64E(hash->h8[1]);
             h5h ^= DEC64E(hash->h8[2]);
             h5l ^= DEC64E(hash->h8[3]);
             h6h ^= DEC64E(hash->h8[4]);
             h6l ^= DEC64E(hash->h8[5]);
             h7h ^= DEC64E(hash->h8[6]);
             h7l ^= DEC64E(hash->h8[7]);

             h0h ^= 0x80;
             h3l ^= 0x2000000000000;
         }
         E8;
     }
     h4h ^= 0x80;
     h7l ^= 0x2000000000000;

     hash->h8[0] = DEC64E(h4h);
     hash->h8[1] = DEC64E(h4l);
     hash->h8[2] = DEC64E(h5h);
     hash->h8[3] = DEC64E(h5l);
     hash->h8[4] = DEC64E(h6h);
     hash->h8[5] = DEC64E(h6l);
     hash->h8[6] = DEC64E(h7h);
     hash->h8[7] = DEC64E(h7l);

  barrier(CLK_GLOBAL_MEM_FENCE);
}
__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search5(__global hash_t* hashes)
{
    uint gid = get_global_id(0);
    __global hash_t *hash = &(hashes[gid-get_global_offset(0)]);

    // keccak

    sph_u64 a00 = 0, a01 = 0, a02 = 0, a03 = 0, a04 = 0;
    sph_u64 a10 = 0, a11 = 0, a12 = 0, a13 = 0, a14 = 0;
    sph_u64 a20 = 0, a21 = 0, a22 = 0, a23 = 0, a24 = 0;
    sph_u64 a30 = 0, a31 = 0, a32 = 0, a33 = 0, a34 = 0;
    sph_u64 a40 = 0, a41 = 0, a42 = 0, a43 = 0, a44 = 0;

    a10 = SPH_C64(0xFFFFFFFFFFFFFFFF);
    a20 = SPH_C64(0xFFFFFFFFFFFFFFFF);
    a31 = SPH_C64(0xFFFFFFFFFFFFFFFF);
    a22 = SPH_C64(0xFFFFFFFFFFFFFFFF);
    a23 = SPH_C64(0xFFFFFFFFFFFFFFFF);
    a04 = SPH_C64(0xFFFFFFFFFFFFFFFF);

    a00 ^= SWAP8(hash->h8[0]);
    a10 ^= SWAP8(hash->h8[1]);
    a20 ^= SWAP8(hash->h8[2]);
    a30 ^= SWAP8(hash->h8[3]);
    a40 ^= SWAP8(hash->h8[4]);
    a01 ^= SWAP8(hash->h8[5]);
    a11 ^= SWAP8(hash->h8[6]);
    a21 ^= SWAP8(hash->h8[7]);
    a31 ^= 0x8000000000000001;
    KECCAK_F_1600;
    // Finalize the "lane complement"
    a10 = ~a10;
    a20 = ~a20;

    hash->h8[0] = SWAP8(a00);
    hash->h8[1] = SWAP8(a10);
    hash->h8[2] = SWAP8(a20);
    hash->h8[3] = SWAP8(a30);
    hash->h8[4] = SWAP8(a40);
    hash->h8[5] = SWAP8(a01);
    hash->h8[6] = SWAP8(a11);
    hash->h8[7] = SWAP8(a21);

    barrier(CLK_GLOBAL_MEM_FENCE);
}
__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search6(__global hash_t* hashes)
{
    uint gid = get_global_id(0);
    __global hash_t *hash = &(hashes[gid-get_global_offset(0)]);

    // luffa

    sph_u32 V00 = SPH_C32(0x6d251e69), V01 = SPH_C32(0x44b051e0), V02 = SPH_C32(0x4eaa6fb4), V03 = SPH_C32(0xdbf78465), V04 = SPH_C32(0x6e292011), V05 = SPH_C32(0x90152df4), V06 = SPH_C32(0xee058139), V07 = SPH_C32(0xdef610bb);
    sph_u32 V10 = SPH_C32(0xc3b44b95), V11 = SPH_C32(0xd9d2f256), V12 = SPH_C32(0x70eee9a0), V13 = SPH_C32(0xde099fa3), V14 = SPH_C32(0x5d9b0557), V15 = SPH_C32(0x8fc944b3), V16 = SPH_C32(0xcf1ccf0e), V17 = SPH_C32(0x746cd581);
    sph_u32 V20 = SPH_C32(0xf7efc89d), V21 = SPH_C32(0x5dba5781), V22 = SPH_C32(0x04016ce5), V23 = SPH_C32(0xad659c05), V24 = SPH_C32(0x0306194f), V25 = SPH_C32(0x666d1836), V26 = SPH_C32(0x24aa230a), V27 = SPH_C32(0x8b264ae7);
    sph_u32 V30 = SPH_C32(0x858075d5), V31 = SPH_C32(0x36d79cce), V32 = SPH_C32(0xe571f7d7), V33 = SPH_C32(0x204b1f67), V34 = SPH_C32(0x35870c6a), V35 = SPH_C32(0x57e9e923), V36 = SPH_C32(0x14bcb808), V37 = SPH_C32(0x7cde72ce);
    sph_u32 V40 = SPH_C32(0x6c68e9be), V41 = SPH_C32(0x5ec41e22), V42 = SPH_C32(0xc825b7c7), V43 = SPH_C32(0xaffb4363), V44 = SPH_C32(0xf5df3999), V45 = SPH_C32(0x0fc688f1), V46 = SPH_C32(0xb07224cc), V47 = SPH_C32(0x03e86cea);

    DECL_TMP8(M);

    M0 = hash->h4[1];
    M1 = hash->h4[0];
    M2 = hash->h4[3];
    M3 = hash->h4[2];
    M4 = hash->h4[5];
    M5 = hash->h4[4];
    M6 = hash->h4[7];
    M7 = hash->h4[6];

    for(uint i = 0; i < 5; i++)
    {
        MI5;
        LUFFA_P5;

        if(i == 0) {
            M0 = hash->h4[9];
            M1 = hash->h4[8];
            M2 = hash->h4[11];
            M3 = hash->h4[10];
            M4 = hash->h4[13];
            M5 = hash->h4[12];
            M6 = hash->h4[15];
            M7 = hash->h4[14];
        } else if(i == 1) {
            M0 = 0x80000000;
            M1 = M2 = M3 = M4 = M5 = M6 = M7 = 0;
        } else if(i == 2) {
            M0 = M1 = M2 = M3 = M4 = M5 = M6 = M7 = 0;
        } else if(i == 3) {
            hash->h4[1] = V00 ^ V10 ^ V20 ^ V30 ^ V40;
            hash->h4[0] = V01 ^ V11 ^ V21 ^ V31 ^ V41;
            hash->h4[3] = V02 ^ V12 ^ V22 ^ V32 ^ V42;
            hash->h4[2] = V03 ^ V13 ^ V23 ^ V33 ^ V43;
            hash->h4[5] = V04 ^ V14 ^ V24 ^ V34 ^ V44;
            hash->h4[4] = V05 ^ V15 ^ V25 ^ V35 ^ V45;
            hash->h4[7] = V06 ^ V16 ^ V26 ^ V36 ^ V46;
            hash->h4[6] = V07 ^ V17 ^ V27 ^ V37 ^ V47;
        }
    }
    hash->h4[9] = V00 ^ V10 ^ V20 ^ V30 ^ V40;
    hash->h4[8] = V01 ^ V11 ^ V21 ^ V31 ^ V41;
    hash->h4[11] = V02 ^ V12 ^ V22 ^ V32 ^ V42;
    hash->h4[10] = V03 ^ V13 ^ V23 ^ V33 ^ V43;
    hash->h4[13] = V04 ^ V14 ^ V24 ^ V34 ^ V44;
    hash->h4[12] = V05 ^ V15 ^ V25 ^ V35 ^ V45;
    hash->h4[15] = V06 ^ V16 ^ V26 ^ V36 ^ V46;
    hash->h4[14] = V07 ^ V17 ^ V27 ^ V37 ^ V47;

  barrier(CLK_GLOBAL_MEM_FENCE);
}
__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search7(__global hash_t* hashes)
{
    uint gid = get_global_id(0);
    __global hash_t *hash = &(hashes[gid-get_global_offset(0)]);

    // cubehash.h1

    sph_u32 x0 = SPH_C32(0x2AEA2A61), x1 = SPH_C32(0x50F494D4), x2 = SPH_C32(0x2D538B8B), x3 = SPH_C32(0x4167D83E);
    sph_u32 x4 = SPH_C32(0x3FEE2313), x5 = SPH_C32(0xC701CF8C), x6 = SPH_C32(0xCC39968E), x7 = SPH_C32(0x50AC5695);
    sph_u32 x8 = SPH_C32(0x4D42C787), x9 = SPH_C32(0xA647A8B3), xa = SPH_C32(0x97CF0BEF), xb = SPH_C32(0x825B4537);
    sph_u32 xc = SPH_C32(0xEEF864D2), xd = SPH_C32(0xF22090C4), xe = SPH_C32(0xD0E5CD33), xf = SPH_C32(0xA23911AE);
    sph_u32 xg = SPH_C32(0xFCD398D9), xh = SPH_C32(0x148FE485), xi = SPH_C32(0x1B017BEF), xj = SPH_C32(0xB6444532);
    sph_u32 xk = SPH_C32(0x6A536159), xl = SPH_C32(0x2FF5781C), xm = SPH_C32(0x91FA7934), xn = SPH_C32(0x0DBADEA9);
    sph_u32 xo = SPH_C32(0xD65C8A2B), xp = SPH_C32(0xA5A70E75), xq = SPH_C32(0xB1C62456), xr = SPH_C32(0xBC796576);
    sph_u32 xs = SPH_C32(0x1921C8F7), xt = SPH_C32(0xE7989AF1), xu = SPH_C32(0x7795D246), xv = SPH_C32(0xD43E3B44);

    x0 ^= SWAP4(hash->h4[1]);
    x1 ^= SWAP4(hash->h4[0]);
    x2 ^= SWAP4(hash->h4[3]);
    x3 ^= SWAP4(hash->h4[2]);
    x4 ^= SWAP4(hash->h4[5]);
    x5 ^= SWAP4(hash->h4[4]);
    x6 ^= SWAP4(hash->h4[7]);
    x7 ^= SWAP4(hash->h4[6]);

    for (int i = 0; i < 13; i ++) {
        SIXTEEN_ROUNDS;

        if (i == 0) {
            x0 ^= SWAP4(hash->h4[9]);
            x1 ^= SWAP4(hash->h4[8]);
            x2 ^= SWAP4(hash->h4[11]);
            x3 ^= SWAP4(hash->h4[10]);
            x4 ^= SWAP4(hash->h4[13]);
            x5 ^= SWAP4(hash->h4[12]);
            x6 ^= SWAP4(hash->h4[15]);
            x7 ^= SWAP4(hash->h4[14]);
        } else if(i == 1) {
            x0 ^= 0x80;
        } else if (i == 2) {
            xv ^= SPH_C32(1);
        }
    }

    hash->h4[0] = x0;
    hash->h4[1] = x1;
    hash->h4[2] = x2;
    hash->h4[3] = x3;
    hash->h4[4] = x4;
    hash->h4[5] = x5;
    hash->h4[6] = x6;
    hash->h4[7] = x7;
    hash->h4[8] = x8;
    hash->h4[9] = x9;
    hash->h4[10] = xa;
    hash->h4[11] = xb;
    hash->h4[12] = xc;
    hash->h4[13] = xd;
    hash->h4[14] = xe;
    hash->h4[15] = xf;

  barrier(CLK_GLOBAL_MEM_FENCE);
}
__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search8(__global hash_t* hashes)
{
    uint gid = get_global_id(0);
    __global hash_t *hash = &(hashes[gid-get_global_offset(0)]);
    __local sph_u32 AES0[256], AES1[256], AES2[256], AES3[256];
    int init = get_local_id(0);
    int step = get_local_size(0);
    for (int i = init; i < 256; i += step)
    {
        AES0[i] = AES0_C[i];
        AES1[i] = AES1_C[i];
        AES2[i] = AES2_C[i];
        AES3[i] = AES3_C[i];
    }
    barrier(CLK_LOCAL_MEM_FENCE);

    // shavite
    {
    // IV
    sph_u32 h0 = SPH_C32(0x72FCCDD8), h1 = SPH_C32(0x79CA4727), h2 = SPH_C32(0x128A077B), h3 = SPH_C32(0x40D55AEC);
    sph_u32 h4 = SPH_C32(0xD1901A06), h5 = SPH_C32(0x430AE307), h6 = SPH_C32(0xB29F5CD1), h7 = SPH_C32(0xDF07FBFC);
    sph_u32 h8 = SPH_C32(0x8E45D73D), h9 = SPH_C32(0x681AB538), hA = SPH_C32(0xBDE86578), hB = SPH_C32(0xDD577E47);
    sph_u32 hC = SPH_C32(0xE275EADE), hD = SPH_C32(0x502D9FCD), hE = SPH_C32(0xB9357178), hF = SPH_C32(0x022A4B9A);

    // state
    sph_u32 rk00, rk01, rk02, rk03, rk04, rk05, rk06, rk07;
    sph_u32 rk08, rk09, rk0A, rk0B, rk0C, rk0D, rk0E, rk0F;
    sph_u32 rk10, rk11, rk12, rk13, rk14, rk15, rk16, rk17;
    sph_u32 rk18, rk19, rk1A, rk1B, rk1C, rk1D, rk1E, rk1F;

    sph_u32 sc_count0 = (64 << 3), sc_count1 = 0, sc_count2 = 0, sc_count3 = 0;

    rk00 = hash->h4[0];
    rk01 = hash->h4[1];
    rk02 = hash->h4[2];
    rk03 = hash->h4[3];
    rk04 = hash->h4[4];
    rk05 = hash->h4[5];
    rk06 = hash->h4[6];
    rk07 = hash->h4[7];
    rk08 = hash->h4[8];
    rk09 = hash->h4[9];
    rk0A = hash->h4[10];
    rk0B = hash->h4[11];
    rk0C = hash->h4[12];
    rk0D = hash->h4[13];
    rk0E = hash->h4[14];
    rk0F = hash->h4[15];
    rk10 = 0x80;
    rk11 = rk12 = rk13 = rk14 = rk15 = rk16 = rk17 = rk18 = rk19 = rk1A = 0;
    rk1B = 0x2000000;
    rk1C = rk1D = rk1E = 0;
    rk1F = 0x2000000;

    c512(buf);

    hash->h4[0] = h0;
    hash->h4[1] = h1;
    hash->h4[2] = h2;
    hash->h4[3] = h3;
    hash->h4[4] = h4;
    hash->h4[5] = h5;
    hash->h4[6] = h6;
    hash->h4[7] = h7;
    hash->h4[8] = h8;
    hash->h4[9] = h9;
    hash->h4[10] = hA;
    hash->h4[11] = hB;
    hash->h4[12] = hC;
    hash->h4[13] = hD;
    hash->h4[14] = hE;
    hash->h4[15] = hF;
    }

  barrier(CLK_GLOBAL_MEM_FENCE);
}
__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search9(__global hash_t* hashes)
{
    uint gid = get_global_id(0);
    __global hash_t *hash = &(hashes[gid-get_global_offset(0)]);

    // simd
    s32 q[256];
    unsigned char x[128];
    for(unsigned int i = 0; i < 64; i++)
  x[i] = hash->h1[i];
    for(unsigned int i = 64; i < 128; i++)
  x[i] = 0;

    u32 A0 = C32(0x0BA16B95), A1 = C32(0x72F999AD), A2 = C32(0x9FECC2AE), A3 = C32(0xBA3264FC), A4 = C32(0x5E894929), A5 = C32(0x8E9F30E5), A6 = C32(0x2F1DAA37), A7 = C32(0xF0F2C558);
    u32 B0 = C32(0xAC506643), B1 = C32(0xA90635A5), B2 = C32(0xE25B878B), B3 = C32(0xAAB7878F), B4 = C32(0x88817F7A), B5 = C32(0x0A02892B), B6 = C32(0x559A7550), B7 = C32(0x598F657E);
    u32 C0 = C32(0x7EEF60A1), C1 = C32(0x6B70E3E8), C2 = C32(0x9C1714D1), C3 = C32(0xB958E2A8), C4 = C32(0xAB02675E), C5 = C32(0xED1C014F), C6 = C32(0xCD8D65BB), C7 = C32(0xFDB7A257);
    u32 D0 = C32(0x09254899), D1 = C32(0xD699C7BC), D2 = C32(0x9019B6DC), D3 = C32(0x2B9022E4), D4 = C32(0x8FA14956), D5 = C32(0x21BF9BD3), D6 = C32(0xB94D0943), D7 = C32(0x6FFDDC22);

    FFT256(0, 1, 0, ll1);
    for (int i = 0; i < 256; i ++) {
        s32 tq;

        tq = q[i] + yoff_b_n[i];
        tq = REDS2(tq);
        tq = REDS1(tq);
        tq = REDS1(tq);
        q[i] = (tq <= 128 ? tq : tq - 257);
    }

    A0 ^= hash->h4[0];
    A1 ^= hash->h4[1];
    A2 ^= hash->h4[2];
    A3 ^= hash->h4[3];
    A4 ^= hash->h4[4];
    A5 ^= hash->h4[5];
    A6 ^= hash->h4[6];
    A7 ^= hash->h4[7];
    B0 ^= hash->h4[8];
    B1 ^= hash->h4[9];
    B2 ^= hash->h4[10];
    B3 ^= hash->h4[11];
    B4 ^= hash->h4[12];
    B5 ^= hash->h4[13];
    B6 ^= hash->h4[14];
    B7 ^= hash->h4[15];

    ONE_ROUND_BIG(0_, 0,  3, 23, 17, 27);
    ONE_ROUND_BIG(1_, 1, 28, 19, 22,  7);
    ONE_ROUND_BIG(2_, 2, 29,  9, 15,  5);
    ONE_ROUND_BIG(3_, 3,  4, 13, 10, 25);

    STEP_BIG(
        C32(0x0BA16B95), C32(0x72F999AD), C32(0x9FECC2AE), C32(0xBA3264FC),
        C32(0x5E894929), C32(0x8E9F30E5), C32(0x2F1DAA37), C32(0xF0F2C558),
        IF,  4, 13, PP8_4_);
    STEP_BIG(
        C32(0xAC506643), C32(0xA90635A5), C32(0xE25B878B), C32(0xAAB7878F),
        C32(0x88817F7A), C32(0x0A02892B), C32(0x559A7550), C32(0x598F657E),
        IF, 13, 10, PP8_5_);
    STEP_BIG(
        C32(0x7EEF60A1), C32(0x6B70E3E8), C32(0x9C1714D1), C32(0xB958E2A8),
        C32(0xAB02675E), C32(0xED1C014F), C32(0xCD8D65BB), C32(0xFDB7A257),
        IF, 10, 25, PP8_6_);
    STEP_BIG(
        C32(0x09254899), C32(0xD699C7BC), C32(0x9019B6DC), C32(0x2B9022E4),
        C32(0x8FA14956), C32(0x21BF9BD3), C32(0xB94D0943), C32(0x6FFDDC22),
        IF, 25,  4, PP8_0_);

    u32 COPY_A0 = A0, COPY_A1 = A1, COPY_A2 = A2, COPY_A3 = A3, COPY_A4 = A4, COPY_A5 = A5, COPY_A6 = A6, COPY_A7 = A7;
    u32 COPY_B0 = B0, COPY_B1 = B1, COPY_B2 = B2, COPY_B3 = B3, COPY_B4 = B4, COPY_B5 = B5, COPY_B6 = B6, COPY_B7 = B7;
    u32 COPY_C0 = C0, COPY_C1 = C1, COPY_C2 = C2, COPY_C3 = C3, COPY_C4 = C4, COPY_C5 = C5, COPY_C6 = C6, COPY_C7 = C7;
    u32 COPY_D0 = D0, COPY_D1 = D1, COPY_D2 = D2, COPY_D3 = D3, COPY_D4 = D4, COPY_D5 = D5, COPY_D6 = D6, COPY_D7 = D7;

    #define q SIMD_Q

    A0 ^= 0x200;

    ONE_ROUND_BIG(0_, 0,  3, 23, 17, 27);
    ONE_ROUND_BIG(1_, 1, 28, 19, 22,  7);
    ONE_ROUND_BIG(2_, 2, 29,  9, 15,  5);
    ONE_ROUND_BIG(3_, 3,  4, 13, 10, 25);
    STEP_BIG(
        COPY_A0, COPY_A1, COPY_A2, COPY_A3,
        COPY_A4, COPY_A5, COPY_A6, COPY_A7,
        IF,  4, 13, PP8_4_);
    STEP_BIG(
        COPY_B0, COPY_B1, COPY_B2, COPY_B3,
        COPY_B4, COPY_B5, COPY_B6, COPY_B7,
        IF, 13, 10, PP8_5_);
    STEP_BIG(
        COPY_C0, COPY_C1, COPY_C2, COPY_C3,
        COPY_C4, COPY_C5, COPY_C6, COPY_C7,
        IF, 10, 25, PP8_6_);
    STEP_BIG(
        COPY_D0, COPY_D1, COPY_D2, COPY_D3,
        COPY_D4, COPY_D5, COPY_D6, COPY_D7,
        IF, 25,  4, PP8_0_);
    #undef q

    hash->h4[0] = A0;
    hash->h4[1] = A1;
    hash->h4[2] = A2;
    hash->h4[3] = A3;
    hash->h4[4] = A4;
    hash->h4[5] = A5;
    hash->h4[6] = A6;
    hash->h4[7] = A7;
    hash->h4[8] = B0;
    hash->h4[9] = B1;
    hash->h4[10] = B2;
    hash->h4[11] = B3;
    hash->h4[12] = B4;
    hash->h4[13] = B5;
    hash->h4[14] = B6;
    hash->h4[15] = B7;

  barrier(CLK_GLOBAL_MEM_FENCE);
}

__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search10(__global hash_t* hashes, __global uint* output, const ulong target)
{
    uint gid = get_global_id(0);
    hash_t hash;

    __local sph_u32 AES0[256], AES1[256], AES2[256], AES3[256];
    int init = get_local_id(0);
    int step = get_local_size(0);
    for (int i = init; i < 256; i += step)
    {
        AES0[i] = AES0_C[i];
        AES1[i] = AES1_C[i];
        AES2[i] = AES2_C[i];
        AES3[i] = AES3_C[i];
    }
    barrier(CLK_LOCAL_MEM_FENCE);

    // copies hashes to "hash"
    uint offset = get_global_offset(0);
    for (int i = 0; i < 8; i++) {
      hash.h8[i] = hashes[gid-offset].h8[i];
    }

    // echo
    sph_u64 W00, W01, W10, W11, W20, W21, W30, W31, W40, W41, W50, W51, W60, W61, W70, W71, W80, W81, W90, W91, WA0, WA1, WB0, WB1, WC0, WC1, WD0, WD1, WE0, WE1, WF0, WF1;
    sph_u64 Vb00, Vb01, Vb10, Vb11, Vb20, Vb21, Vb30, Vb31, Vb40, Vb41, Vb50, Vb51, Vb60, Vb61, Vb70, Vb71;
    Vb00 = Vb10 = Vb20 = Vb30 = Vb40 = Vb50 = Vb60 = Vb70 = 512UL;
    Vb01 = Vb11 = Vb21 = Vb31 = Vb41 = Vb51 = Vb61 = Vb71 = 0;

    sph_u32 K0 = 512;
    sph_u32 K1 = 0;
    sph_u32 K2 = 0;
    sph_u32 K3 = 0;

    W00 = Vb00;
    W01 = Vb01;
    W10 = Vb10;
    W11 = Vb11;
    W20 = Vb20;
    W21 = Vb21;
    W30 = Vb30;
    W31 = Vb31;
    W40 = Vb40;
    W41 = Vb41;
    W50 = Vb50;
    W51 = Vb51;
    W60 = Vb60;
    W61 = Vb61;
    W70 = Vb70;
    W71 = Vb71;
    W80 = hash.h8[0];
    W81 = hash.h8[1];
    W90 = hash.h8[2];
    W91 = hash.h8[3];
    WA0 = hash.h8[4];
    WA1 = hash.h8[5];
    WB0 = hash.h8[6];
    WB1 = hash.h8[7];
    WC0 = 0x80;
    WC1 = 0;
    WD0 = 0;
    WD1 = 0;
    WE0 = 0;
    WE1 = 0x200000000000000;
    WF0 = 0x200;
    WF1 = 0;

    for (unsigned u = 0; u < 10; u ++) {
        BIG_ROUND;
    }

    Vb00 ^= hash.h8[0] ^ W00 ^ W80;
    Vb01 ^= hash.h8[1] ^ W01 ^ W81;
    Vb10 ^= hash.h8[2] ^ W10 ^ W90;
    Vb11 ^= hash.h8[3] ^ W11 ^ W91;
    Vb20 ^= hash.h8[4] ^ W20 ^ WA0;
    Vb21 ^= hash.h8[5] ^ W21 ^ WA1;
    Vb30 ^= hash.h8[6] ^ W30 ^ WB0;
    Vb31 ^= hash.h8[7] ^ W31 ^ WB1;

    bool result = (Vb11 <= target);
    if (result)
        output[atomic_inc(output+0xFF)] = SWAP4(gid);

    barrier(CLK_GLOBAL_MEM_FENCE);
}

#endif// DARKCOIN_MOD_CL
