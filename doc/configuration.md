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

### nfactor

Overrides the default scrypt parameter N, specified as the factor of 2
(`N = 2^nfactor`).

If specified in a pool section in the configuration file, sets the
option for that pool only. Otherwise sets the default.

*Argument:* whole number (>1).

*Default:* depends on `algorithm`; otherwise `10`.

### hamsi-expand-big

Sets SPH_HAMSI_EXPAND_BIG for X13 algorithms. Values `"4"` and `"1"` are
commonly used. Changing this may improve hashrate. Which value is better
depends on GPU type and even manufacturer (i.e. exact GPU model).

*Argument:* `"4"` or `"1"`
*Default:* `"4"`

## Pool-specific configuration

If you use any of these options for a pool, then **you must** set that option
for every pool. This is necessary due to current poor implementation of
sgminer config parser.

Options that can be configured have a `pool-` prefix and work the same as the
global settings:

* pool-algorithm
* pool-nfactor
* pool-intensity
* pool-xintensity
* pool-rawintensity
* pool-gpu-engine
* pool-gpu-memclock
* pool-gpu-threads
* pool-thread-concurrency
* pool-gpu-fan

## CLI-only options

*TODO*
