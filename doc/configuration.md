# Configuration and command-line options

*Work in progress!*


## Config-file and CLI options

### algorithm

Allows choosing between the few mining algorithms for incompatible
cryptocurrencies.

Requires a string.

Currently supported:

* `adaptive-nfactor` - Vertcoin-style adaptive N-factor scrypt.
N-factor defaults to 11.
* everything else - Litecoin-style static N-factor scrypt.


### nfactor

Overrides the default N-factor scrypt parameter.

Requires an unsigned integer.
