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
#include <string.h>

typedef struct algorithm_t {
    char    name[20]; /* Human-readable identifier */
    uint8_t nfactor;  /* N factor (CPU/Memory tradeoff parameter) */
} algorithm_t;

void set_algorithm(algorithm_t* algo, char* newname) {
    strncpy(algo->name, newname, sizeof(algo->name));
    algo->name[sizeof(algo->name) - 1] = '\0';

    if (strcmp(algo->name, "adaptive-nfactor") == 0) {
	algo->nfactor = 11;
    } else {
	algo->nfactor = 10;
    }
}

void set_algorithm_nfactor(algorithm_t* algo, uint8_t nfactor) {
    algo->nfactor = nfactor;
}
