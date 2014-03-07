# Configuration and command-line options

*Work in progress!*


## Config-file and CLI options

### algorithm

Allows choosing between the few mining algorithms for incompatible
cryptocurrencies.

*Argument:* string

*Default:* `default`

*Supported:*

* `adaptive-nfactor` - Vertcoin-style adaptive N-factor scrypt.
N-factor defaults to 11.
* everything else - Litecoin-style static N-factor scrypt.


### nfactor

Overrides the default scrypt parameter N, specified as the factor of 2
(`N = 2^nfactor`).

*Argument:* whole number (>1).

*Default:* depends on `algorithm`; otherwise `10`.


## CLI-only options

*TODO*
