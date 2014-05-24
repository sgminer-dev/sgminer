# Configuration and command-line options

*Work in progress!*


## Config-file and CLI options

### algorithm

Allows choosing between the few mining algorithms for incompatible
cryptocurrencies.

If specified in a pool section in the configuration file, sets the
option for that pool only. Otherwise sets the default.

*Argument:* string

*Default:* `scrypt`

*Supported:*

* `adaptive-n-factor` - Vertcoin-style adaptive N-factor scrypt.
  N-factor defaults to 11. Aliases: `adaptive-nfactor` (to be removed
  in future versions) and `nscrypt`.
* `scrypt` - Litecoin-style static N-factor scrypt.
* everything else - currently defaults to `scrypt`, subject to change
  without warning.


### pool-algorithm

Allows choosing the algorithm for a specific pool. See `algorithm`.


### nfactor

Overrides the default scrypt parameter N, specified as the factor of 2
(`N = 2^nfactor`).

If specified in a pool section in the configuration file, sets the
option for that pool only. Otherwise sets the default.

*Argument:* whole number (>1).

*Default:* depends on `algorithm`; otherwise `10`.


### pool-nfactor

Overrides the default scrypt parameter N for a specific pool.
See `nfactor`.


## CLI-only options

*TODO*
