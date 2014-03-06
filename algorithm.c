/*
 * Copyright 2014 sgminer developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or (at
 * your option) any later version.  See COPYING for more details.
 */

#include "algorithm.h"

#include <inttypes.h>

typedef struct algorithm_t {
    char    name[32]; /* Human-readable identifier */
    uint8_t nfactor;  /* N factor (CPU/Memory tradeoff parameter) */
} algorithm_t;
