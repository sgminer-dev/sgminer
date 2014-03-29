# Release news

## Version 4.2.0 - TBA

* There are now two mailing lists (on SourceForge), see `README.md`.
* Adaptive-N-factor algorithm support (by _Bufius_, _Zuikkis_ and
  _veox_). For details on choosing the algorithm, see
  `doc/configuration.md`.
* Allowed kernel names are no longer hard-coded. It is now possible to
  use any `.cl` file.
* Configuration parameter `poolname` has been renamed to `name`.
  `poolname` is deprecated and will be removed in a future version.
* Multiple `--name` parsing should now work as expected (by _troky_).
* `--coin` configuration parameter to specify a freeform pool
  description (by _troky_).
* Forward-port changes from `ckolivas/cgminer` slightly after 3.12.3
  (up to 133252175b90159d18151b004bf767d5a43812ea).


## Version 4.1.153 - 14th March 2014

* Display pool URL instead of "Pool N" if no `poolname` specified.
* Incognito mode to hide user name in NCurses interface - useful for
  publishing screenshots. To enable, use `--incognito` on command line,
  `incognito` in config or `[D][I]` in NCurses interface.
* Support building in Microsoft Visual Studio 2010, perhaps other
  versions as well (by _troky_). Documentation in `winbuild/README.txt`.
* Support building in Cygwin (by _markuspeloquin_). Documentation in
  `doc/cygwin-build.txt`.
* Forward-port changes from `ckolivas/cgminer` up to 3.12.3.
* Allow setting `worksize` for kernel `zuikkis`.
* More log messages in pool handling.
* Updated `doc/FAQ.md`.
* Updated `example.conf`.


## Version 4.1.0 - 7th February 2014

* Writing configuration file from NCurses interface is broken!
* Commandline option parsing may be broken!
* MinGW building may be broken!
* Bug reporting documentation: `doc/BUGS.md`.
* Kernel selection and integration: `doc/KERNEL.md`.
* Several updates to other documentation files.
* Warn if `GPU_*` environment variables are not set.
* Maximum `intensity` lowered to 31 (anything above that gives an overflow
  anyway).
* Experimental `xintensity` setting (by _Kalroth_), see
  [commit message](https://github.com/veox/sgminer/commit/7aeae40af22e6108aab8b68a229eea25a639d650).
* Experimental `rawintensity` setting (by _Kalroth_), see
  [commit message](https://github.com/veox/sgminer/commit/d11df698d141988491494aa1f29c7d3595e9712b).
* `-v` is now a shorthand for `--verbose`, not `--vectors`.
* Default `scantime` and `expiry` changed to 7 and 28 (tests run by
  _MissedOutOnBTC_).
* Increased precision of `API_MHS`; added `API_KHS`.
* Pulled in kernels: `alexkarold`, `alexkarnew`, `psw`, `zuikkis`; renamed
  `scrypt` to `ckolivas`; all kernels now reside in directory `kernel`.
  Kernels can be chosen at startup only, by specifying `kernel`.
* Small optimisation to `ckolivas` kernel (by _gdevenyi_).
* Named pools via `poolname` (by _Kalroth_).
* Failover pool switching back delay is configurable via
  `failover-switch-delay` (by _Kalroth_).
* Pool `state`: `enabled`, `disabled`, and `hidden` (by _Joe4782_).
* Allow all pools to be set `disabled`.
* Use RPM in ADL `get-fanspeed` requests (from `bfgminer`, by _luke-jr_).
* Verbose ADL failure messages (by _Joe4782_ and _deba12_).
* Use `git` version string if available.
* Allow bypassing ADL checks during build with `--disable-adl-checks`.
* MinGW build checks (by _tonobitc_).
* Experimental Microsoft Visual Studio 2010 building support in branch
  `build-msvs2010-upd` (by _troky_).


## Version 4.0.0 - 15th January 2014

* Fork `veox/sgminer` from `ckolivas/cgminer` version 3.7.2.
* Remove code referencing SHA256d mining, FPGAs and ASICS. Leftovers most
  probably still remain.
* AMD ADL crash fix on R9 chipsets by Benjamin Herrenschmidt.
* Maximum allowed intensity increased to 42.
* Move documentation to directory `doc`.
* `--gpu-threads` support for comma-separated values by Martin Danielsen
  (_Kalroth_).
* AMD ADL SDK 5 mandatory, preparation for ADL Overdrive 6 support by
  _Kalroth_.
* Allow changing TCP keepalive packet idle time using `--tcp-keepalive`.
* Automatic library presence detection by `configure`.
* `--scrypt` option removed (no other choice now).
* `--vectors` option removed (current kernel only supports 1).
* Display per-GPU reject percentage instead of absolute values by _Kalroth_.
* Do not show date in log by default (switch with `--log-show-date`).
* Fix network difficulty display to resemble that of `cgminer` 3.1.1.
* Forward-port relevant bugfixes form `ckolivas/cgminer`, up to `cgminer`
  version 3.10.0.


Previous NEWS file available [here](https://github.com/veox/sgminer/blob/829f0687bfd0ddb0cf12a9a8588ae2478dfe8d99/NEWS).
