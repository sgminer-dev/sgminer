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

void set_algorithm(algorithm_t* algo, const char* newname) {
    strncpy(algo->name, newname, sizeof(algo->name));
    algo->name[sizeof(algo->name) - 1] = '\0';

    if ((strcmp(algo->name, "adaptive-n-factor") == 0) ||
	(strcmp(algo->name, "adaptive-nfactor")  == 0) ||
	(strcmp(algo->name, "nscrypt")           == 0) ) {
	set_algorithm_nfactor(algo, 11);
    } else {
	set_algorithm_nfactor(algo, 10);
    }

    return;
}

void set_algorithm_nfactor(algorithm_t* algo, const uint8_t nfactor) {
    algo->nfactor = nfactor;
    algo->n = (1 << nfactor);

    return;
}

bool cmp_algorithm(algorithm_t* algo1, algorithm_t* algo2) {
    return (strcmp(algo1->name, algo2->name) == 0) &&
          (algo1->nfactor == algo2->nfactor);
}
