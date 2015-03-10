/* $Id: groestl.c 260 2011-07-21 01:02:38Z tp $ */
/*
 * Groestl256
 *
 * ==========================(LICENSE BEGIN)============================
 * Copyright (c) 2014 djm34
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
#define B64_0(x)    ((x) & 0xFF)
#define B64_1(x)    (((x) >> 8) & 0xFF)
#define B64_2(x)    (((x) >> 16) & 0xFF)
#define B64_3(x)    (((x) >> 24) & 0xFF)
#define B64_4(x)    (((x) >> 32) & 0xFF)
#define B64_5(x)    (((x) >> 40) & 0xFF)
#define B64_6(x)    (((x) >> 48) & 0xFF)
#define B64_7(x)    ((x) >> 56)
#define R64         SPH_ROTL64
#define PC64(j, r)  ((sph_u64)((j) + (r)))
#define QC64(j, r)  (((sph_u64)(r) << 56) ^ SPH_T64(~((sph_u64)(j) << 56)))

__constant static const sph_u64 T0[] = {
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

__constant static const sph_u64 T4[] = {
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

#define RSTT(d, a, b0, b1, b2, b3, b4, b5, b6, b7)   do { \
		t[d] = T0[B64_0(a[b0])] \
			^ R64(T0[B64_1(a[b1])],  8) \
			^ R64(T0[B64_2(a[b2])], 16) \
			^ R64(T0[B64_3(a[b3])], 24) \
			^ T4[B64_4(a[b4])] \
			^ R64(T4[B64_5(a[b5])],  8) \
			^ R64(T4[B64_6(a[b6])], 16) \
			^ R64(T4[B64_7(a[b7])], 24); \
		} while (0)

#define ROUND_SMALL_P(a, r)   do { \
		a[0] ^= PC64(0x00, r); \
		a[1] ^= PC64(0x10, r); \
		a[2] ^= PC64(0x20, r); \
		a[3] ^= PC64(0x30, r); \
		a[4] ^= PC64(0x40, r); \
		a[5] ^= PC64(0x50, r); \
		a[6] ^= PC64(0x60, r); \
		a[7] ^= PC64(0x70, r); \
		RSTT(0, a, 0, 1, 2, 3, 4, 5, 6, 7); \
		RSTT(1, a, 1, 2, 3, 4, 5, 6, 7, 0); \
		RSTT(2, a, 2, 3, 4, 5, 6, 7, 0, 1); \
		RSTT(3, a, 3, 4, 5, 6, 7, 0, 1, 2); \
		RSTT(4, a, 4, 5, 6, 7, 0, 1, 2, 3); \
		RSTT(5, a, 5, 6, 7, 0, 1, 2, 3, 4); \
		RSTT(6, a, 6, 7, 0, 1, 2, 3, 4, 5); \
		RSTT(7, a, 7, 0, 1, 2, 3, 4, 5, 6); \
		a[0] = t[0]; \
		a[1] = t[1]; \
		a[2] = t[2]; \
		a[3] = t[3]; \
		a[4] = t[4]; \
		a[5] = t[5]; \
		a[6] = t[6]; \
		a[7] = t[7]; \
		} while (0)

#define ROUND_SMALL_Pf(a, r)   do { \
		a[0] ^= PC64(0x00, r); \
		a[1] ^= PC64(0x10, r); \
		a[2] ^= PC64(0x20, r); \
		a[3] ^= PC64(0x30, r); \
		a[4] ^= PC64(0x40, r); \
		a[5] ^= PC64(0x50, r); \
		a[6] ^= PC64(0x60, r); \
		a[7] ^= PC64(0x70, r); \
		RSTT(7, a, 7, 0, 1, 2, 3, 4, 5, 6); \
		a[7] = t[7]; \
			} while (0)

#define ROUND_SMALL_Q(a, r)   do { \
		a[0] ^= QC64(0x00, r); \
		a[1] ^= QC64(0x10, r); \
		a[2] ^= QC64(0x20, r); \
		a[3] ^= QC64(0x30, r); \
		a[4] ^= QC64(0x40, r); \
		a[5] ^= QC64(0x50, r); \
		a[6] ^= QC64(0x60, r); \
		a[7] ^= QC64(0x70, r); \
		RSTT(0, a, 1, 3, 5, 7, 0, 2, 4, 6); \
		RSTT(1, a, 2, 4, 6, 0, 1, 3, 5, 7); \
		RSTT(2, a, 3, 5, 7, 1, 2, 4, 6, 0); \
		RSTT(3, a, 4, 6, 0, 2, 3, 5, 7, 1); \
		RSTT(4, a, 5, 7, 1, 3, 4, 6, 0, 2); \
		RSTT(5, a, 6, 0, 2, 4, 5, 7, 1, 3); \
		RSTT(6, a, 7, 1, 3, 5, 6, 0, 2, 4); \
		RSTT(7, a, 0, 2, 4, 6, 7, 1, 3, 5); \
		a[0] = t[0]; \
		a[1] = t[1]; \
		a[2] = t[2]; \
		a[3] = t[3]; \
		a[4] = t[4]; \
		a[5] = t[5]; \
		a[6] = t[6]; \
		a[7] = t[7]; \
		} while (0)

#define PERM_SMALL_P(a)   do { \
		for (int r = 0; r < 10; r ++) \
			ROUND_SMALL_P(a, r); \
		} while (0)

#define PERM_SMALL_Pf(a)   do { \
		for (int r = 0; r < 9; r ++) { \
			ROUND_SMALL_P(a, r);} \
            ROUND_SMALL_Pf(a,9); \
			} while (0)

#define PERM_SMALL_Q(a)   do { \
		for (int r = 0; r < 10; r ++) \
			ROUND_SMALL_Q(a, r); \
		} while (0)

