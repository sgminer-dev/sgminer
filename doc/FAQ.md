# FAQ

Q: Why is the network difficulty wrong?
A: It is not wrong. Sharediff of 1 (historically) corresponds to a
network difficulty of 1/65536. Throughout the inteface, share difficulty
is displayed as whole numbers, not fractionals. Pools use the same
convention (with the notable exception of P2Pool). Until pools start
using true network difficulty to display share difficulty, there is no
reason to display difficulty differently. This is a vicious cycle and a
remnant of Bitcoin mining on GPUs.

Q: Can I mine on servers from different networks (eg litecoin and
dogecoin) at the same time?
A: No. `sgminer` keeps a database of the block it's working on to ensure
it does not work on stale blocks, and having different blocks from two
networks would make it invalidate the work from each other.

Q: Can I configure sgminer to mine with different login credentials or
pools for each separate device?
A: No.

Q: Can I put multiple pools in the config file?
A: Yes, check the `example.conf` file. Alternatively, set up everything
either on the command line or via the menu after startup and choose
`Settings -> Write config file`.

Q: The build fails with `gcc is unable to build a binary`.
A: Remove the "-march=native" component of your `CFLAGS` as your version
of gcc does not support it.

Q: Can you implement feature X?
A: I can, but time is limited, and people who donate are more likely to
get their feature requests implemented.

Q: Work keeps going to my backup pool even though my primary pool
hasn't failed?
A: sgminer checks for conditions where the primary pool is lagging and
will pass some work to the backup servers under those conditions. The
reason for doing this is to try its absolute best to keep the GPUs
working on something useful and not risk idle periods. You can disable
this behaviour with the option --failover-only.

Q: Is this a virus?
A: sgminer is being packaged with other trojan
scripts and some antivirus software is falsely accusing sgminer.exe as
being the actual virus, rather than whatever it is being packaged with.
If you had built sgminer yourself, then you do not have a virus on your
computer. Complain to your antivirus software company..

Q: Can you modify the display to include more of one thing in the output
and less of another, or can you change the quiet mode or can you add
yet another output mode?
A: Everyone will always have their own view of what's important to
monitor. The shipped NCurses TUI is intentionally ascetic, and is only
provided as a fallback. It is recomended to use an API client if you
want to customise the display.

Q: GUI version?
A: No. The API makes it possible for someone else to write one though.

Q: What are the best parameters to pass for pool / hardware / device?
A: See `doc/MINING.md` in your source distribution directory, or
[doc/MINING.md](https://github.com/veox/sgminer/blob/master/doc/MINING.md]
for an online version. Note that the latter is for the latest
development version, and arguments listed there are not necessarily
available in your local version.

Q: Is CPU mining supported?
A: No. Consider using [cpuminer](https://github.com/pooler/cpuminer).

Q: I'm having an issue. What debugging information should I provide in
the bug report?
A: See `doc/BUGS.md` in your source distribution directory, or
[doc/BUGS.md](https://github.com/veox/sgminer/blob/master/doc/BUGS.md]
for an online version.

Q: Why don't you provide binaries?
A: Binaries are a hassle to maintain. On Linux, they should be provided
by your distribution's package manager anyway. Runnning an unoptimised
binary gives a minor performance penalty. Running binaries from
untrusted providers is a security risk. There has not been sufficient
community interest to provide distributed determininstic builds.

Q: Is it better to mine on Linux or Windows?
A: It comes down to choice of operating system for their various
features. Linux offers specialised mining distributions, much better
long term stability, remote monitoring and security, while Windows
offers overclocking tools that can achieve much more than sgminer can do
on Linux. YMMV.

Q: Can I mine with sgminer on a Mac?
A: sgminer will compile on OSX, but the performance of GPU mining
is compromised due to the OpenCL implementation on OSX, there is no
temperature or fanspeed monitoring, and the cooling design will usually
not cope with constant usage leading to a high risk of thermal damage.
It is highly recommended not to mine on a Mac.

Q: I switch users on Windows and my mining stops working?
A: That's correct, it does. It's a permissions issue that there is no
known fix for due to monitoring of GPU fanspeeds and temperatures. If
you disable the monitoring with `--no-adl` it should switch okay.

Q: My network gets slower and slower and then dies for a minute?
A: Try the `--net-delay` option.

Q: How do I tune for P2Pool?
A: P2Pool has very rapid expiration of work and new blocks, it is
suggested you decrease intensity, decrease `scantime` and `expiry`,
and/or decrease GPU threads to 1 with `-g 1`. It is also recommended to
use `--failover-only` since the work is effectively a separate
blockchain.

Q: Are OpenCL kernels from other mining software usable in sgminer?
A: Most often no.

Q: How do I add my own kernel?
A: See `doc/KERNEL.md` in your source distribution directory, or
[doc/KERNEL.md](https://github.com/veox/sgminer/blob/master/doc/KERNEL.md]
for an online version.

Q: I run PHP on Windows to access the API with the example
`miner.php`. Why does it fail when PHP is installed properly but
I only get errors about Sockets not working in the logs?
A: http://us.php.net/manual/en/sockets.installation.php

Q: Will sgminer support FPGAs or ASICs?
A: No. sgminer will only support GPUs. It is bad software design
practice to try and support every gadget out there. Developers
for dedicated hardware products are better off creating standalone
software.

Q: What is stratum and how do I use it?
A: Stratum is a protocol designed for pooled mining in such a way as to
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

Q: Why don't the statistics add up: Accepted, Rejected, Stale, Hardware
Errors, Diff1 Work, etc. when mining greater than 1 difficulty shares?
A: As an example, if you look at 'Difficulty Accepted' in the RPC API,
the number of difficulty shares accepted does not usually exactly equal
the amount of work done to find them. If you are mining at 8 difficulty,
then you would expect on average to find one 8 difficulty share, per 8
single difficulty shares found. However, the number is actually random
and converges over time, it is an average, not an exact value, thus you
may find more or less than the expected average.

Q: Why do the scrypt diffs not match with the current difficulty target?
A: The current scrypt block difficulty is expressed in terms of how
many multiples of the BTC difficulty it currently is (eg 28) whereas
the shares of "difficulty 1" are actually 65536 times smaller than the
BTC ones. The diff expressed by sgminer is as multiples of difficulty 1
shares.

Q: Can I make a donation?
A: Yes, see AUTHORS.md for authors' donation addresses.

Q: What is Work Utility (WU)?
A: Work utility is the product of hashrate * luck and only stabilises
over a very long period of time. Luck includes hardware error rate,
share reject rate and other parameters. Therefore, it is often a better
indicator of hardware or software misconfiguration.
