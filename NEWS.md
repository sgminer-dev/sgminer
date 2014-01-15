Version 4.0.0 - 15th January 2014

* Fork `veox/sgminer` from `ckolivas/cgminer` version 3.7.2.
* Remove code referencing SHA256d mining, FPGAs and ASICS. Leftovers most probably still remain.
* AMD ADL crash fix on R9 chipsets by Benjamin Herrenschmidt.
* Maximum allowed intensity increased to 42.
* Move documentation to directory `doc`.
* `--gpu-threads` support for comma-separated values by Martin "Kalroth" Danielsen.
* AMD ADL SDK 5 mandatory, preparation for ADL Overdrive 6 support by Martin.
* Allow changing TCP keepalive packet idle time using `--tcp-keepalive`.
* Automatic library presence detection by `configure`.
* `--scrypt` option removed (no other choice now).
* `--vectors` option removed (current kernel only supports 1).
* Display per-GPU reject percentage instead of absolute values by Martin.
* Do not show date in log by default (switch with `--log-show-date`).
* Fix network difficulty display to resemble that of cgminer 3.1.1.
* Forward-port relevant bugfixes form `ckolivas/cgminer`, up to cgminer version 3.10.0.

Previous NEWS file available [here](https://github.com/veox/sgminer/blob/829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/NEWS).
