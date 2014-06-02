# Kernels

## Available OpenCL kernels

See directory `kernel`.

## Parameter configuration

### Common

In general, switching kernels requires reconfiguring mining parameters,
such as (but not necessarily limited to) `thread-concurrency`, `intensity`,
`gpu-engine` and `gpu-memclock`.

A description of how to do this is available in `doc/MINING.md`.


### Scrypt kernels

#### alexkarnew

Alexey Karimov's optimised kernel, based on `ckolivas`. For Catalyst >=13.4.

Only supports `vectors=1`.

[Announcement](https://litecointalk.org/index.php?topic=4082.0).


#### alexkarold

Alexey Karimov's optimised kernel, based on `ckolivas`. For Catalyst <13.4.

Only supports `vectors=1`.

[Announcement](https://litecointalk.org/index.php?topic=4082.0).


#### bufius

Bufius' optimised kernel, based on `ckolivas`. Merged from vertminer.

Only supports `vectors=1` and `lookup-gap` 2, 4 or 8.


#### ckolivas

The original Colin Percival `scrypt` kernel, maintained for a long time by
Con Kolivas in `cgminer` and renamed to reflect the fact.

Only supports `vectors=1`.


#### psw

Pavel Semjanov optimised kernel, SHA256 speedups.

[Announcement](https://bitcointalk.org/index.php?topic=369858.0).


#### zuikkis

Zuikkis' optimised kernel, based on `ckolivas`.

Only supports `vectors=1` and `lookup-gap=2`.

[Announcement](https://litecointalk.org/index.php?topic=6058.msg90873#msg90873).

### Other kernels

#### darkcoin
#### darkcoin-mod
#### animecoin
#### fuguecoin
#### groestlcoin
#### inkcoin
#### marucoin
#### marucoin-mod
#### myriadcoin-groestl
#### quarkcoin
#### qubitcoin
#### sifcoin
#### twecoin
#### maxcoin

## Submitting new kernels

### Requirements

* OpenCL source code only, licenced under GPLv3 (or later).
* Not hard-coded for a specific GPU model or manufacturer.
* Known limitations and any specific configuration quirks must be
  mentioned.


### Procedure

* Copy the kernel you wish to modify, make sure the character encoding is
UTF-8 and commit it without any further modifications.

This way, it is easy to verify that there are no hidden changes. Note in
the commit message which kernel is used as a base.

* Make changes to the kernel. Commit them.

This allows to produce a diff that makes sense.

* Recompile and test that the kernel actually works.

* Add yourself to the "kernels" section in `AUTHORS.md`. Keep it short.

* Submit a pull request on GitHub, file it at the issue tracker, or mail
it.

Outline the changes made, known limitations, and tested GPUs. List
your git repository and branch name. The current repository and issue
tracker links should be in `README.md`.
