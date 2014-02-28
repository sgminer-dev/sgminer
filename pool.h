#ifndef POOL_H
#define POOL_H

#include "miner.h"

#define POOL_NAME_INCOGNITO "<incognito>"
#define POOL_USER_INCOGNITO "<incognito>"

extern char* get_pool_name(struct pool *pool);
extern char* get_pool_user(struct pool *pool);

#endif /* POOL_H */
