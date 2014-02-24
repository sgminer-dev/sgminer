# FAQ

## Why don't you provide binaries?

Binaries are a hassle to maintain. On Linux, they should be provided
by your distribution's package manager anyway. Running an unoptimised
binary gives a minor performance penalty. Running binaries from
untrusted providers is a security risk. There has not been sufficient
community interest to provide distributed determininstic builds.


## It would be nice to have step-by-step installation instructions for Linux.

These instructions cannot be specific enough, since it depends a lot
on the GNU/Linux distribution you're using. It should be handled by the
package manager anyway. Otherwise, such instructions will constantly
be out-of-date. AMD does not allow redistribution of their SDKs'
source code, so providing packages can be difficult for some GNU/Linux
distributions.


## Why is the network difficulty wrong?

It is not wrong. Sharediff of 1 (historically) corresponds to a
network difficulty of 1/65536. Throughout the inteface, share difficulty
is displayed as whole numbers, not fractionals. Pools use the same
convention (with the notable exception of P2Pool). Until pools start
using true network difficulty to display share difficulty, there is no
reason to display difficulty differently. This is a vicious cycle and a
remnant of Bitcoin mining on GPUs.


## Will sgminer support FPGAs or ASICs?

No. sgminer will only support GPUs. It is bad software design
practice to try and support every gadget out there. Developers
for dedicated hardware products are better off creating standalone
software.


## Will there be scrypt-jane/Keccak/SHA-3 support?

Perhaps eventually, if it can be implemented without code bloat.


## Can you modify the display...

...to include more of one thing in the output
and less of another, or can you change the quiet mode or can you add
yet another output mode?

Probably not. Everyone will always have their own view of what's
important to monitor. The shipped NCurses TUI is intentionally ascetic,
and is only provided as a fallback. It is recomended to use an API
client if you want to customise the display.


## Can I mine on servers from different networks...

...(e.g. litecoin and dogecoin) at the same time?

No. `sgminer` keeps a database of the block it's working on to ensure
it does not work on stale blocks, and having different blocks from two
networks would make it invalidate the work from each other.


## Can I mine with different login credentials or pools for each separate device?

No. Run per-device instances with `-d`.


## Can I put multiple pools in the config file?

Yes, check the `example.conf` file. Alternatively, set up everything
either on the command line or via the menu after startup and choose
`Settings -> Write config file`.


## The build fails with `gcc is unable to build a binary`.

Remove the `-march=native` component of your `CFLAGS` as your version
of gcc does not support it.


## Can you implement feature X?

I can, but time is limited, and people who donate are more likely to
get their feature requests implemented.


## Work keeps going to my backup pool...

...even though my primary pool hasn't failed!

`sgminer` checks for conditions where the primary pool is lagging and
will pass some work to the backup servers under those conditions. The
reason for doing this is to try its absolute best to keep the GPUs
working on something useful and not risk idle periods. You can disable
this behaviour with the option --failover-only.


## Is this a virus?

`sgminer` may be packaged with other trojan scripts and some antivirus
software is falsely accusing sgminer.exe as being the actual virus,
rather than whatever it is being packaged with. If you had built sgminer
yourself, then you do not have a virus on your computer. Complain to
your antivirus software company..


## GUI version?

No. The API makes it possible for someone else to write one though.


## What are the best parameters to pass for pool / hardware / device?

See `doc/MINING.md` in your source distribution directory, or
[doc/MINING.md](https://github.com/veox/sgminer/blob/master/doc/MINING.md]
for an online version. Note that the latter is for the latest
development version, and arguments listed there are not necessarily
available in your local version.


## Is CPU mining supported?

No. Consider using [cpuminer](https://github.com/pooler/cpuminer).


## I'm having an issue. What should I provide in the bug report?

See `doc/BUGS.md` in your source distribution directory, or
[doc/BUGS.md](https://github.com/veox/sgminer/blob/master/doc/BUGS.md)
for an online version.


## Is it better to mine on Linux or Windows?

It comes down to choice of operating system for their various
features. Linux offers specialised mining distributions, much better
long term stability, remote monitoring and security, while Windows
offers overclocking tools that can achieve much more than sgminer can do
on Linux. YMMV.


## Can I mine with sgminer on a Mac?

`sgminer` will compile on OSX, but the performance of GPU mining
is compromised due to the OpenCL implementation on OSX, there is no
temperature or fanspeed monitoring, and the cooling design will usually
not cope with constant usage leading to a high risk of thermal damage.
It is highly recommended not to mine on a Mac.


## I switch users on Windows and my mining stops working?

That's correct, it does. It's a permissions issue that there is no
known fix for due to monitoring of GPU fanspeeds and temperatures. If
you disable the monitoring with `--no-adl` it should switch okay.


## My network gets slower and slower and then dies for a minute?

Try the `--net-delay` option.


## How do I tune for P2Pool?

P2Pool has very rapid expiration of work and new blocks, it is
suggested you decrease intensity, decrease `scantime` and `expiry`,
and/or decrease GPU threads to 1 with `-g 1`. It is also recommended to
use `--failover-only` since the work is effectively a separate
blockchain.


## Are OpenCL kernels from other mining software usable in sgminer?

Most often no.


## How do I add my own kernel?

See `doc/KERNEL.md` in your source distribution directory, or
[doc/KERNEL.md](https://github.com/veox/sgminer/blob/master/doc/KERNEL.md)
for an online version.


## I run PHP on Windows to access the API with the example

`miner.php`. Why does it fail when PHP is installed properly but
I only get errors about Sockets not working in the logs?
See [this](http://us.php.net/manual/en/sockets.installation.php).


## What is stratum and how do I use it?

Stratum is a protocol designed for pooled mining in such a way as to
minimise the amount of network communications, yet scale to hardware
of any speed. If a pool has stratum support (and most public ones do),
sgminer will automatically detect it and switch to the support as
advertised if it can. If you input the stratum port directly into your
configuration, or use the special prefix `stratum+tcp://` instead of
`http://`, sgminer will ONLY try to use stratum protocol mining. The
advantages of stratum to the miner are no delays in getting more work
for the miner, less rejects across block changes, and far less network
communications for the same amount of mining hashrate. If you do not
wish sgminer to automatically switch to stratum protocol even if it is
detected, add the `--fix-protocol` option.


## Why don't the statistics add up?..

...Accepted, Rejected, Stale, Hardware Errors, Diff1 Work, etc. when
mining greater than 1 difficulty shares?

As an example, if you look at 'Difficulty Accepted' in the RPC API,
the number of difficulty shares accepted does not usually exactly equal
the amount of work done to find them. If you are mining at 8 difficulty,
then you would expect on average to find one 8 difficulty share, per 8
single difficulty shares found. However, the number is actually random
and converges over time, it is an average, not an exact value, thus you
may find more or less than the expected average.


## Can I make a donation?

Yes, see AUTHORS.md for authors' donation addresses.


## What is Work Utility (WU)?

Work utility is the product of hashrate * luck and only stabilises
over a very long period of time. Luck includes hardware error rate,
share reject rate and other parameters. Therefore, it is often a better
indicator of hardware or software misconfiguration.
