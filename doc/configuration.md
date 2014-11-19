# Configuration and command-line options

*Work in progress!*

### Table of contents

* [Configuration Settings Order](#configuration-settings-order)
* [Globals and the Default Profile](#globals-and-the-default-profile)
* [Working with Profiles and Pool Specific Settings](#working-with-profiles-and-pool-specific-settings)
* [Include and Includes](#include-and-includes)
* [Events](#events)
* [CLI Only options](#cli-only-options)
* [Config-file and CLI options](#config-file-and-cli-options)
* [Event options](#event-options)
* [Event Types](#event-types)

---

## Configuration Settings Order

The configuration settings in sgminer are applied in this order:

```
Command Line > Config File Globals > Default Profile > Pool's Profile > Pool-Specific Settings
```

[Top](#configuration-and-command-line-options)

## Globals and the Default Profile

The default profile contains the settings that are to be used as defaults throughout sgminer. Typically, unless you specify `default-profile`, those settings will be read from the global level of the config file or use sgminer's core defaults if nothing is at the global level. The pool or profile level settings will override the default profile's settings.

The example below has `algorithm` set at the global level. Anytime a pool or profile doesn't specify `algorithm`, "darkcoin-mod" will be used.
```
{
  "pools": [...],
  "algorithm":"darkcoin-mod",
  "intensity":"19",
  ...
```

In the example below, `algorithm` is not specified at the global level and no profile is used as `default-profile`. This means that the default profile's `algorithm` will be set to sgminer's core default: "scrypt".
```
{
  "pools": [
    {
      "url":"poolA:8334",
      ...
      "profile":"A"
    },
    {
      "url":"poolB:8334",
      ...
    }
  ],
  "profiles":[
    {
      "name":"A",
      "algorithm":"darkcoin-mod"
    }
  ],
  "intensity":"19"
}
```
When using the first pool, Profile A will be applied, so `algorithm` will be set to "darkcoin-mod". When using the second pool, the default profile is applied, and `algorithm` will be set to "scrypt". `intensity`, being set at the global level, will be the default profile's `intensity` value. `intensity` will be set to "19" for both pools, because it is never specified in the pool or profile settings.

When `default-profile` is specified, any settings contained in that profile will override globals. For example:
```
{
  "pools": [
    {
      "url":"poolA:8334",
      ...
      "profile":"A"
    },
    {
      "url":"poolB:8334",
      ...
    }
  ],
  "profiles":[
    {
      "name":"A",
      "algorithm":"darkcoin-mod"
    },
    {
      "name":"B",
      "algorithm":"ckolivas"
    }
  ],
  "default-profile":"B",
  "algorithm":"marucoin-mod",
  "intensity":"19"
}
```
Profile B will be used to set the default profile's settings, which means `algorithm` will be set to "ckolivas" and the global value of "marucoin-mod" will be discarded. The first pool will use Profile A's "darkcoin-mod" and the second pool will use the default profile's "ckolivas".

See the [configuration settings order](#configuration-settings-order) for more information about the order in which settings are applied.

[Top](#configuration-and-command-line-options)

## Working with Profiles and Pool Specific Settings

Profiles have been added assist in specifying different GPU and/or algorithm settings that could be (re-)used by one or more pools. Pool-specific settings will override profile settings, and profile settings will override the default profile/globals.

See the [configuration settings order](#configuration-settings-order) for more information about the order in which settings are applied.

```
{
  "pools": [
    {
      "url":"poolA:8334",
      ...
      "profile":"A"
    },
    {
      "url":"poolB:8334",
      ...
      "profile":"A",
      "gpu-engine":"1000"
    },
    {
      "url":"poolC:8334",
      ...
      "intensity":"13"
    }
  ],
  "profiles":[
    {
      "name":"A",
      "algorithm":"darkcoin-mod",
      "gpu-engine":"1050"
    },
    {
      "name":"B",
      "algorithm":"ckolivas"
    }
  ],
  "default-profile":"B",
  "intensity":"19",
  "gpu-engine":"1100"
}
```
In the example above, when using the second pool, Profile A is applied, which sets the `algorithm` to "darkcoin-mod", but since a `gpu-engine` of "1000" is specified in the pool, the value of "1050" is discarded.

A similar situation occurs in the third pool. No profile is specified so the default `algorithm` "ckolivas" is set along with the default `gpu-engine` of "1100". Because `intensity` is set to "13" in the pool, the default profile's value of "19" is discarded.

The end result of the above would look like this:
```
{
  "pools": [
    {
      "url":"poolA:8334",
      ...
      "algorithm":"darkcoin-mod",
      "intensity":"19",
      "gpu-engine":"1050"
    },
    {
      "url":"poolB:8334",
      ...
      "algorithm":"darkcoin-mod",
      "intensity":"19",
      "gpu-engine":"1000"
    },
    {
      "url":"poolC:8334",
      ...
      "algorithm":"ckolivas"
      "intensity":"13"
      "gpu-engine":"1100"
    }
  ]
}
```

[Top](#configuration-and-command-line-options)

## Include and Includes

`include` and `includes` are special keywords only available in the configuration file. You can include json-formatted files at any level of the configuration parsing. The values read in the included
files are applied to the current object being parsed.

`include` is used to include one single file. If you want to include multiple files, use `includes`, which is an array of filenames.

As with config files, these files can be web URLs pointing to remote files.

```
/etc/pool.ip.credentials:
{
    "user":"user",
    "pass":"x"
}

sgminer.conf:
...
"pools":[
    {
        "url":"stratum+tcp://pool.ip:8334",
        "include":"/etc/pool.ip.credentials"
    }
],
...
```

In the example above, the parser will include the contents of the file `/etc/pool.ip.credentials` directly where it was called from. This will produce the following result:

```
sgminer.conf:
...
"pools":[
    {
        "url":"stratum+tcp://pool.ip:8334",
        "user":"user",
        "pass":"x"
    }
],
...
```

The example below shows how you could breakdown your config across multiple smaller files:

```
sgminer.conf:
"includes":[
    "/etc/pools.conf",
    "/etc/profiles.conf",
    "/etc/gpus.conf"
],
...
```

There is no limit as to how includes can be used as long as they follow proper json syntax.

[Top](#configuration-and-command-line-options)

---

## Events

Users can now execute commands or perform certain tasks when pre-defined events occur while mining. 

For example, one might want their miner to email them via a script when the miner goes idle and reboot the computer when a GPU goes dead. This gives users a little more flexibility controlling their mining uptime without necessarily resorting to external watchdog programs that, in some cases, can be troublesome.

Here is a configuration example of the above scenario:
```
...
"events":[
  {
    "on":"idle",
    "runcmd":"/bin/mailscript \"Miner Idle\" \"Hey! My miner went idle!\""
  },
  {
    "on":"gpu_dead",
    "reboot":"yes"
  }
],
...
```

For more details on configuration options, see [Event Options](#event-options) below.

[Top](#configuration-and-command-line-options)

---

## CLI Only options

* [config](#config) `--config` or `-c`
* [default-config](#default-config) `--default-config`
* [help](#help) `--help` or `-h`
* [ndevs](#ndevs) `-ndevs` or `-n`
* [version](#version) `--version` or `-V`

---

### config

Load a JSON-formatted configuration file. See `example.conf` for an example configuration file.

The filename can also be a web or ftp url for remote configuration files. The file will be downloaded locally before being loaded. **Note:** If a file by the same name exists, it will be overwritten. If you modify and save your configuration, the changes will only be made locally and future downloads will overwrite your changes. **Also note** that the remote configuration files are only available with `libcurl`.

Note that the configuration file's settings will override any settings passed via command line. For more information, see [Configuration Settings Order](#configuration-settings-order).

*Syntax:* `--config <value>` or `-c <value>`

*Argument:* `string` Filename or URL

*Example:*

```
# ./sgminer -c example.conf
```

```
# ./sgminer -c http://www.mysite.com/configfiles/myconfig.conf
```

[Top](#configuration-and-command-line-options) :: [CLI Only options](#cli-only-options)

### default-config

Specifies the name of the default configuration file to be loaded at start up and also used to save any settings changes during operation.

*Syntax:* `--default-config <value>`

*Argument:* `string` Filename

*Example:*

```
# ./sgminer --default_config defaultconfig.conf
```

[Top](#configuration-and-command-line-options) :: [CLI Only options](#cli-only-options)

### help

Displays the current sgminer version string, followed by the command line syntax help and then exits.

*Syntax:* `--help` or `-h`

*Example:*

```
# ./sgminer -h
sgminer 4.2.1-116-g2e8b-dirty
Usage: ./sgminer [-DdEgXKlLmpPQqUsTouvwOchnV]
Options for both config file and command line:
--algorithm <arg>   Set mining algorithm and most common defaults, default: scrypt
--api-allow <arg>   Allow API access only to the given list of [G:]IP[/Prefix] addresses[/subnets]
--api-description <arg> Description placed in the API status header, default: sgminer version
--api-groups <arg>  API one letter groups G:cmd:cmd[,P:cmd:*...] defining the cmds a groups can use
--api-listen        Enable API, default: disabled

...

```

[Top](#configuration-and-command-line-options) :: [CLI Only options](#cli-only-options)

### ndevs

Displays the number of GPUs detected, Open CL/ADL platform information and then exits.

*Syntax:* `--ndevs` or `-n`

*Example:*

```
# ./sgminer -n
[10:16:04] CL Platform vendor: Advanced Micro Devices, Inc.
[10:16:04] CL Platform name: AMD Accelerated Parallel Processing
[10:16:04] CL Platform version: OpenCL 1.2 AMD-APP (1348.5)
[10:16:04] Platform devices: 2
[10:16:04]      0       Tahiti
[10:16:04]      1       Tahiti
[10:16:04] Number of ADL devices: 2
[10:16:04] ATI ADL Overdrive5 API found.
[10:16:04] ATI ADL Overdrive6 API found.
[10:16:04] Found 12 logical ADL adapters

...

```

[Top](#configuration-and-command-line-options) :: [CLI Only options](#cli-only-options)

### version

Displays the current sgminer version string and exits.

*Syntax:* `--version` or `-V`

*Example:*

```
# ./sgminer -V
sgminer 4.2.1-116-g2e8b-dirty
```

[Top](#configuration-and-command-line-options) :: [CLI Only options](#cli-only-options)

---

## Config-file and CLI options

* [API Options](#api-options)
  * [api-allow](#api-allow)
  * [api-description](#api-description)
  * [api-groups](#api-groups)
  * [api-listen](#api-listen)
  * [api-mcast](#api-mcast)
  * [api-mcast-addr](#api-mcast-addr)
  * [api-mcast-code](#api-mcast-code)
  * [api-mcast-des](#api-mcast-des)
  * [api-mcast-port](#api-mcast-port)
  * [api-network](#api-network)
  * [api-port](#api-port)
* [Algorithm Options](#algorithm-options)
  * [algorithm](#algorithm)
  * [lookup-gap](#lookup-gap)
  * [nfactor](#nfactor)
  * [blake-compact](#blake-compact)
  * [hamsi-expand-big](#hamsi-expand-big)
  * [hamsi-short](#hamsi-short)
  * [keccak-unroll](#keccak-unroll)
  * [luffa-parallel](#luffa-parallel)
  * [shaders](#shaders)
  * [thread-concurrency](#thread-concurrency)
  * [worksize](#worksize)
* [GPU Options](#gpu-options)
  * [auto-fan](#auto-fan)
  * [auto-gpu](#auto-gpu)
  * [gpu-dyninterval](#gpu-dyninterval)
  * [gpu-engine](#gpu-engine)
  * [gpu-platform](#gpu-platform)
  * [gpu-threads](#gpu-threads)
  * [gpu-fan](#gpu-fan)
  * [gpu-map](#gpu-map)
  * [gpu-memclock](#gpu-memclock)
  * [gpu-memdiff](#gpu-memdiff)
  * [gpu-powertune](#gpu-powertune)
  * [gpu-reorder](#gpu-reorder)
  * [gpu-threads](#gpu-threads)
  * [gpu-vddc](#gpu-vddc)
  * [intensity](#intensity)
  * [no-adl](#no-adl)
  * [no-restart](#no-restart)
  * [rawintensity](#rawintensity)
  * [temp-cutoff](#temp-cutoff)
  * [temp-hysteresis](#temp-hysteresis)
  * [temp-overheat](#temp-overheat)
  * [temp-target](#temp-target)
  * [xintensity](#xintensity)
* [Pool Options](#pool-options)
  * [algorithm](#algorithm)
  * [description](#description)
  * [device](#device)
  * [gpu-engine](#gpu-engine)
  * [gpu-fan](#gpu-fan)
  * [gpu-memclock](#gpu-memclock)
  * [gpu-powertune](#gpu-powertune)
  * [gpu-threads](#gpu-threads)
  * [gpu-vddc](#gpu-vddc)
  * [intensity](#intensity)
  * [lookup-gap](#lookup-gap)
  * [name](#pool-name)
  * [nfactor](#nfactor)
  * [no-extranonce](#no-extranonce)
  * [pass](#pass)
  * [priority](#priority)
  * [profile](#profile)
  * [quota](#quota)
  * [rawintensity](#rawintensity)
  * [shaders](#shaders)
  * [state](#state)
  * [thread-concurrency](#thread-concurrency)
  * [url](#url)
  * [user](#user)
  * [userpass](#userpass)
  * [worksize](#worksize)
  * [xintensity](#xintensity)
* [Pool Strategy Options](#pool-strategy-options)
  * [balance](#balance)
  * [disable-rejecting](#disable-rejecting)
  * [failover-only](#failover-only)
  * [failover-switch-delay](#failover-switch-delay)
  * [load-balance](#load-balance)
  * [rotate](#rotate)
  * [round-robin](#round-robin)
* [Profile Options](#profile-options)
  * [algorithm](#algorithm)
  * [device](#device)
  * [gpu-engine](#gpu-engine)
  * [gpu-fan](#gpu-fan)
  * [gpu-memclock](#gpu-memclock)
  * [gpu-powertune](#gpu-powertune)
  * [gpu-threads](#gpu-threads)
  * [gpu-vddc](#gpu-vddc)
  * [intensity](#intensity)
  * [lookup-gap](#lookup-gap)
  * [name](#profile-name)
  * [nfactor](#nfactor)
  * [rawintensity](#rawintensity)
  * [shaders](#shaders)
  * [thread-concurrency](#thread-concurrency)
  * [worksize](#worksize)
  * [xintensity](#xintensity)
* [Miscellaneous Options](#miscellaneous-options)
  * [compact](#compact)
  * [debug](#debug)
  * [debug-log](#debug-log)
  * [default-profile](#default-profile)
  * [device](#device)
  * [difficulty-multiplier](#difficulty-multiplier)
  * [expiry](#expiry)
  * [fix-protocol](#fix-protocol)
  * [incognito](#incognito)
  * [kernel-path](#kernel-path)
  * [log](#log)
  * [log-file](#log-file)
  * [log-show-date](#log-show-date)
  * [lowmem](#lowmem)
  * [monitor](#monitor)
  * [more-notices](#more-notices)
  * [net-delay](#net-delay)
  * [no-client-reconnect](#no-client-reconnect)
  * [per-device-stats](#per-device-stats)
  * [protocol-dump](#protocol-dump)
  * [queue](#queue)
  * [quiet](#quiet)
  * [real-quiet](#real-quiet)
  * [remove-disabled](#remove-disabled)
  * [scan-time](#scan-time)
  * [sched-start](#sched-start)
  * [sched-stop](#sched-stop)
  * [sharelog](#sharelog)
  * [shares](#shares)
  * [socks-proxy](#socks-proxy)
  * [show-coindiff](#show-coindiff)
  * [syslog](#syslog)
  * [tcp-keepalive](#tcp-keepalive)
  * [text-only](#text-only)
  * [verbose](#verbose)
  * [worktime](#worktime)

---

## API Options

### api-allow

Specifies the API access list.

*Available*: Global

*Config File Syntax:* `"api-allow":"<value>"`

*Command Line Syntax:* `--api-allow "<value>"`

*Argument:* `comma (,) delimited list` Format: `[<Group ID>:]<IP>[/Prefix] <Addresses>[/subnets][,...]`

*Default:* None

*Example:*

```
"api-allow":"W:127.0.0.1,W:192.168.0.10"
```

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [API Options](#api-options)

### api-description

Description placed in the API status header.

*Available*: Global

*Config File Syntax:* `"api-description":"<value>"`

*Command Line Syntax:* `--api-description "<value>"`

*Argument:* `string`

*Default:* `sgminer version`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [API Options](#api-options)

### api-groups

Sets API groups which restrict group members to only a certain set of commands. The list of groups is comma(,) delimited and each entry has its parameters colon(:) delimited. The first parameter of an entry is always the Group Identifier, which consists of one letter. When defining a group, you can use the asterisk (*) to refer to all non-priviledged functions.

Two groups are pre-defined and may not be used with this option:
* `R` Access to all non-priviledged functions
* `W` Access to all priviledged and non-priviledged functions

Group Members are specified in [api-allow](#api-allow) where they are associated with a group by their IP address.

*Available*: Global

*Config File Syntax:* `"api-groups":"<value>"`

*Command Line Syntax:* `--api-groups "<value>"`

*Argument:* `comma (,) delimited list` Format: `<Group ID>:<command>:<command>[:*][:...][,...]`

*Default:* `R` Access to all non-priviledged functions `W` Access to all functions

*Example:*

```
"api-groups":"A:addpool:*,B:addpool:removepool:switchpool:gpurestart:gpuenable:gpudisable:save:quit",
"api-allow":"A:192.168.0.10,B:127.0.0.1"
```

The above example grants users of group A access to the addpool function as well as all non-priviledged functions.
Group B users only have access to the following functions: addpool, removepool, switchpool, gpurestart, gpuenable, gpudisable, save, quit.

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [API Options](#api-options)

### api-listen

Enables the API.

*Available*: Global

*Config File Syntax:* `"api-listen":true`

*Command Line Syntax:* `--api-listen`

*Argument:* None

*Default:* `false` (disabled)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [API Options](#api-options)

### api-mcast

Enables the API over multicast.

*Available*: Global

*Config File Syntax:* `"api-mcast":true`

*Command Line Syntax:* `--api-mcast`

*Argument:* None

*Default:* `false` (disabled)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [API Options](#api-options)

### api-mcast-addr

Set the API multicast address.

*Available*: Global

*Config File Syntax:* `"api-mcast-addr":"<value>"`

*Command Line Syntax:* `--api-mcast-addr <value>`

*Argument:* `string` IP Address

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [API Options](#api-options)

### api-mcast-code

Code to use in API multicast messages. **Do not use the dash (-)**

*Available*: Global

*Config File Syntax:* `"api-mcast-code":"<value>"`

*Command Line Syntax:* `--api-mcast-code "<value>"`

*Argument:* `string`

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [API Options](#api-options)

### api-mcast-des

Description appended to API multicast replies.

*Available*: Global

*Config File Syntax:* `"api-mcast-des":"<value>"`

*Command Line Syntax:* `--api-mcast-des "<value>"`

*Argument:* `string`

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [API Options](#api-options)

### api-mcast-port

Port to use for API multicast.

*Available*: Global

*Config File Syntax:* `"api-mcast-port":"<value>"`

*Command Line Syntax:* `--api-mcast-port <value>`

*Argument:* `number` Port Number between 1 and 65535

*Default:* `4028`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [API Options](#api-options)

### api-network

**Needs clarification** Allows API (if enabled) to listen on/for any address.

*Available*: Global

*Config File Syntax:* `"api-network":true`

*Command Line Syntax:* `--api-network`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [API Options](#api-options)

### api-port

Port to use for API.

*Available*: Global

*Config File Syntax:* `"api-port":"<value>"`

*Command Line Syntax:* `--api-port <value>`

*Argument:* `number` Port Number between 1 and 65535

*Default:* `4028`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [API Options](#api-options)

---

## Algorithm Options

### algorithm

**Formerly the kernel option.** Sets the algorithm to use for mining.

*Available*: Global, Pool, Profile

*Config File Syntax:* `"algorithm":"<value>"`

*Command Line Syntax:* `--algorithm <value>` `--pool-algorithm <value>` `--profile-algorithm <value>`

*Argument:* `string`

*Default:* `ckolivas`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Algorithm Options](#algorithm-options)

### lookup-gap

Set GPU lookup gap for scrypt mining.

*Available*: Global, Pool, Profile

*Algorithms*: `scrypt` `nscrypt`

*Config File Syntax:* `"lookup-gap":"<value>"`

*Command Line Syntax:* `--lookup-gap "<value>"` `--pool-lookup-gap "<value>"` `--profile-lookup-gap "<value>"`

*Argument:* `One value or a comma (,) delimited list` GPU lookup gap

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Algorithm Options](#algorithm-options)

### nfactor

Overrides the default scrypt parameter N, specified as the factor of 2 (`N = 2^nfactor`).

*Available*: Global, Pool, Profile

*Algorithms*: `nscrypt`

*Config File Syntax:* `"nfactor":"<value>"`

*Command Line Syntax:* `--nfactor <value>` `--pool-nfactor <value>` `--profile-nfactor <value>`

*Argument:* `number` Nfactor 1 or greater

*Default:* `10`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Algorithm Options](#algorithm-options)

### blake-compact

Sets SPH\_COMPACT\_BLAKE64 for Xn derived algorithms. Changing this may improve hashrate. Which value is better depends on GPU type and even manufacturer (i.e. exact GPU model).

*Available*: Global

*Algorithms*: `X11` `X13` `X14` `X15`

*Config File Syntax:* `"blake-compact":true`

*Command Line Syntax:* `--blake-compact`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Algorithm Options](#algorithm-options)

### hamsi-expand-big

Sets SPH\_HAMSI\_EXPAND\_BIG for X13 derived algorithms. Values `"4"` and `"1"` are commonly used. Changing this may improve hashrate. Which value is better depends on GPU type and even manufacturer (i.e. exact GPU model).

*Available*: Global

*Algorithms*: `X13` `X14` `X15`

*Config File Syntax:* `"hamsi-expand-big":"<value>"`

*Command Line Syntax:* `--hamsi-expand-big <value>`

*Argument:* `number` (`1` or `4` are common)

*Default:* `1` (`4` for kernels labeled "old")

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Algorithm Options](#algorithm-options)

### hamsi-short

Sets SPH\_HAMSI\_SHORT for X13 derived algorithms. Changing this may improve hashrate. Which value is better depends on GPU type and even manufacturer (i.e. exact GPU model).

*Available*: Global

*Algorithms*: `X13` `X14` `X15`

*Config File Syntax:* `"hamsi-short":true`

*Command Line Syntax:* `--hamsi-short`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Algorithm Options](#algorithm-options)

### keccak-unroll

Sets SPH\_KECCAK\_UNROLL for Xn derived algorithms. Changing this may improve hashrate. Which value is better depends on GPU type and even manufacturer (i.e. exact GPU model).

*Available*: Global

*Algorithms*: `X11` `X13` `X14` `X15`

*Config File Syntax:* `"keccak-unroll":"<value>"`

*Command Line Syntax:* `--keccak-unroll <value>`

*Argument:* `number`

*Default:* `0`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Algorithm Options](#algorithm-options)

### luffa-parallel

Sets SPH\_LUFFA\_PARALLEL for Xn derived algorithms. Changing this may improve hashrate. Which value is better depends on GPU type and even manufacturer (i.e. exact GPU model).

*Available*: Global

*Algorithms*: `X11` `X13` `X14` `X15`

*Config File Syntax:* `"luffa-parallel":true`

*Command Line Syntax:* `--luffa-parallel`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Algorithm Options](#algorithm-options)

### shaders

Number of shaders per GPU for algorithm tuning. This is used to calculate `thread-concurrency` if not specified.

*Available*: Global, Pool, Profile

*Algorithms*: `scrypt` `nscrypt`

*Config File Syntax:* `"shaders":"<value>"`

*Command Line Syntax:* `--shaders "<value>"` `--pool-shaders "<value>"` `--profile-shaders "<value>"`

*Argument:* `One value or a comma (,) delimited list` GPU shaders

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Algorithm Options](#algorithm-options)

### thread-concurrency

Number of concurrent threads per GPU for mining.

*Available*: Global, Pool, Profile

*Algorithms*: `scrypt` `nscrypt`

*Config File Syntax:* `"thread-concurrency":"<value>"`

*Command Line Syntax:* `--thread-concurrency "<value>"` `--pool-thread-concurrency "<value>"` `--profile-thread-concurrency "<value>"`

*Argument:* `One value or a comma (,) delimited list` GPU thread concurrency

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Algorithm Options](#algorithm-options)

### worksize

Amount of work handled by GPUs per work request.

*Available*: Global, Pool, Profile

*Algorithms*: `all`

*Config File Syntax:* `"worksize":"<value>"`

*Command Line Syntax:* `--worksize "<value>"` `-w "<value>"` `--pool-worksize "<value>"` `--profile-worksize "<value>"`

*Argument:* `One value or a comma (,) delimited list` GPU worksize

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Algorithm Options](#algorithm-options)

---

## GPU Options

### auto-fan

Automatically adjust all GPU fan speeds to maintain a target temperature.

Used with [temp-target](#temp-target), [temp-cutoff](#temp-cutoff), [temp-overheat](#temp-overheat) and [temp-hysteresis](#temp-hysteresis).

*Available*: Global

*Config File Syntax:* `"auto-fan":true`

*Command Line Syntax:* `--auto-fan`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### auto-gpu

Automatically adjust all GPU engine clock speeds to maintain a target temperature.

Used with [temp-target](#temp-target), [temp-cutoff](#temp-cutoff), [temp-overheat](#temp-overheat) and [temp-hysteresis](#temp-hysteresis).

*Available*: Global

*Config File Syntax:* `"auto-gpu":true`

*Command Line Syntax:* `--auto-gpu`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### gpu-dyninterval

**Need clarification** Refresh interval in milliseconds (ms) for GPUs using dynamic intensity.

*Available*: Global

*Config File Syntax:* `"gpu-dyninterval":"<value>"`

*Command Line Syntax:* `--gpu-dyninterval <value>`

*Argument:* `number` Number of milliseconds from 1 to 65535.

*Default:* `7`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### gpu-engine

Set the GPU core clock range in Mhz.

*Available*: Global, Pool, Profile

*Config File Syntax:* `"gpu-engine":"<value>"`

*Command Line Syntax:* `--gpu-engine "<value>"` `--pool-gpu-engine "<value>"` `--profile-gpu-engine "<value>"`

*Argument:* `One value, range and/or comma (,) separated list` GPU engine clocks in Mhz

*Default:* None

*Example:*

```
"gpu-engine":"1000,950-1100,1050-1050"
```

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### gpu-fan

Set the GPU fan percentage range.

*Available*: Global, Pool, Profile

*Config File Syntax:* `"gpu-fan":"<value>"`

*Command Line Syntax:* `--gpu-fan "<value>"` `--pool-gpu-fan "<value>"` `--profile-gpu-fan "<value>"`

*Argument:* `One value, range and/or comma (,) separated list` GPU fan speed percentage

*Default:* None

*Example:*

```
"gpu-fan":"75-85,100,50-50"
```

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### gpu-map

Manually map OpenCL to ADL devices.

*Available*: Global

*Config File Syntax:* `"gpu-map":"<value>"`

*Command Line Syntax:* `--gpu-map "<value>"`

*Argument:* `comma (,) delimited list` Format: `<OpenCL ID>:<ADL ID>,<OpenCL ID>:<ADL ID>[,...]`

*Default:* None

*Example:*

```
"gpu-map":"1:0,2:1,3:2"
```

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### gpu-memclock

Set the GPU memory clock in Mhz.

*Available*: Global, Pool, Profile

*Config File Syntax:* `"gpu-memclock":"<value>"`

*Command Line Syntax:* `--gpu-memclock "<value>"` `--pool-gpu-memclock "<value>"` `--profile-gpu-memclock "<value>"`

*Argument:* `one value and/or comma (,) delimited list` GPU memory clocks in Mhz

*Default:* None

*Example:*

```
"gpu-memclock":"1500,1250,1000"
```

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### gpu-memdiff

Set a fixed difference between the GPU core clock and memory clock while in auto-gpu mode.

*Available*: Global

*Config File Syntax:* `"gpu-memdiff":"<value>"`

*Command Line Syntax:* `--gpu-memdiff "<value>"`

*Argument:* `number` Clock difference in Mhz

*Default:* None

*Example:*

```
"auto-gpu":true,
"gpu-engine":"900-1100",
"gpu-memclock":"400"
```
With the above, memory clock would range between 1300Mhz and 1500Mhz.

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### gpu-platform

**Need clarification** Select the OpenCL platform ID to use for GPU mining.

*Available*: Global

*Config File Syntax:* `"gpu-platform":"<value>"`

*Command Line Syntax:* `--gpu-platform <value>`

*Argument:* `number` OpenCL Platform ID number between 0 and 9999.

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### gpu-powertune

Set the GPU Powertune percentage.

*Available*: Global, Pool, Profile

*Config File Syntax:* `"gpu-powertune":"<value>"`

*Command Line Syntax:* `--gpu-powertune "<value>"` `-g "<value>"` `--pool-gpu-powertune "<value>"` `--profile-gpu-powertune "<value>"`

*Argument:* `one value or a comma (,) delimited list` GPU Powertune percentages

*Default:* `0`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### gpu-reorder

Attempts to reorder the GPUs according to their PCI Bus ID.

*Available*: Global

*Config File Syntax:* `"gpu-reorder":true`

*Command Line Syntax:* `--gpu-reorder`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### gpu-threads

Number of mining threads per GPU.

*Available*: Global, Pool, Profile

*Config File Syntax:* `"gpu-threads":"<value>"`

*Command Line Syntax:* `--gpu-threads "<value>"` `-g "<value>"` `--pool-gpu-threads "<value>"` `--profile-gpu-threads "<value>"`

*Argument:* `one value or (,) delimited list` GPU threads

*Default:* `1`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### gpu-vddc

Set the GPU voltage in Volts.

*Available*: Global, Pool, Profile

*Config File Syntax:* `"gpu-vddc":"<value>"`

*Command Line Syntax:* `--gpu-vddc "<value>"` `--pool-gpu-vddc "<value>"` `--profile-gpu-vddc "<value>"`

*Argument:* `one value or comma (,) delimited list` GPU voltage in Volts

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### intensity

Intensity of GPU scanning.

Overridden by [xintensity](#xintensity) and [rawintensity](#rawintensity).

*Available*: Global, Pool, Profile

*Config File Syntax:* `"intensity":"<value>"`

*Command Line Syntax:* `--intensity "<value>"` `-I "<value>"` `--pool-intensity "<value>"` `--profile-intensity "<value>"`

*Argument:* `one value or a comma (,) delimited list` GPU Intensity between 8 and 31. Use `d` instead of a number to maintain desktop interactivity.

*Default:* `d`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### no-adl

Disable the AMD ADL library. **Note that without ADL, all GPU monitoring is disabled and all GPU parameter functions will not work.**

*Available*: Global

*Config File Syntax:* `"no-adl":true`

*Command Line Syntax:* `--no-adl`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### no-restart

Do not attempt to restart GPUs that hang.

*Available*: Global

*Config File Syntax:* `"no-restart":true`

*Command Line Syntax:* `--no-restart`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### rawintensity

Raw intensity of GPU scanning.

Overriddes by [intensity](#intensity) and [xintensity](#xintensity).

*Available*: Global, Pool, Profile

*Config File Syntax:* `"rawintensity":"<value>"`

*Command Line Syntax:* `--rawintensity "<value>"` `--pool-rawintensity "<value>"` `--profile-rawintensity "<value>"`

*Argument:* `one value or a comma (,) delimited list` GPU Raw intensity between 1 and 2147483647.

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### temp-cutoff

Temperature at which a GPU will be disabled at.

Used with [auto-fan](#auto-fan) and [auto-gpu](#auto-gpu).

*Available*: Global

*Config File Syntax:* `"temp-cutoff":"<value>"`

*Command Line Syntax:* `--temp-cutoff "<value>"`

*Argument:* `one value or a comma (,) delimited list` Temperature in Celcius

*Default:* `95`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### temp-cutoff

Set the allowable temperature fluctuation a GPU can operate outside of limits.

Used with [auto-fan](#auto-fan) and [auto-gpu](#auto-gpu).

*Available*: Global

*Config File Syntax:* `"temp-hysteresis":"<value>"`

*Command Line Syntax:* `--temp-hysteresis <value>`

*Argument:* `number` Temperature in Celcius between 0 and 10

*Default:* `3`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### temp-overheat

Temperature at which a GPU will be throttled.

Used with [auto-fan](#auto-fan) and [auto-gpu](#auto-gpu).

*Available*: Global

*Config File Syntax:* `"temp-overheat":"<value>"`

*Command Line Syntax:* `--temp-overheat "<value>"`

*Argument:* `one value or a comma (,) delimited list` Temperature in Celcius

*Default:* `85`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### temp-target

Temperature at which a GPU should stay at.

Used with [auto-fan](#auto-fan) and [auto-gpu](#auto-gpu).

*Available*: Global

*Config File Syntax:* `"temp-target":"<value>"`

*Command Line Syntax:* `--temp-target "<value>"`

*Argument:* `one value or a comma (,) delimited list` Temperature in Celcius

*Default:* `75`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

### xintensity

Shader based intensity of GPU scanning.

Overridden by [rawintensity](#rawintensity) and overrides [intensity](#intensity).

*Available*: Global, Pool, Profile

*Config File Syntax:* `"xintensity":"<value>"`

*Command Line Syntax:* `--xintensity "<value>"` `-X "<value>"` `--pool-xintensity "<value>"` `--profile-xintensity "<value>"`

*Argument:* `one value or a comma (,) delimited list` GPU Xintensity between 1 and 9999.

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [GPU Options](#gpu-options)

---

## Pool Options

### [pool-]algorithm

See [algorithm](#algorithm)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### description

Set the pool's description

*Available*: Pool

*Config File Syntax:* `"description":"<value>"`

*Command Line Syntax:* `--pool-description "<value>"`

*Argument:* `string`

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]device

See [device](#device).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]gpu-engine

See [gpu-engine](#gpu-engine)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]gpu-fan

See [gpu-fan](#gpu-fan)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]gpu-memclock

See [gpu-memclock](#gpu-memclock)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]gpu-powertune

See [gpu-powertune](#gpu-powertune)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]gpu-threads

See [gpu-threads](#gpu-threads)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]gpu-vddc

See [gpu-vddc](#gpu-vddc)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]intensity

See [intensity](#intensity)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]lookup-gap

See [lookup-gap](#lookup-gap)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]name

Set a name for a pool.

*Available*: Pool

*Config File Syntax:* `"name":"<value>"`

*Command Line Syntax:* `--name "<value>"` `--pool-name "<value>"`

*Argument:* `string` Name of the pool

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]nfactor

See [nfactor](#nfactor)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### no-extranonce

Disable 'extranonce' stratum subscribe for pool.

*Available*: Pool

*Config File Syntax:* `"no-extranonce":true`

*Command Line Syntax:* `--no-extranonce` `--pool-no-extranonce`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### pass

Set pool password.

*Available*: Pool

*Config File Syntax:* `"pass":"<value>"`

*Command Line Syntax:* `--pass "<value>"` `-p "<value>"` `--pool-pass "<value>"`

*Argument:* `string` Pool password

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### priority

Set the priority of the pool other than the order it is entered in the pool list.

*Available*: Pool

*Config File Syntax:* `"priority":"<value>"`

*Command Line Syntax:* `--priority <value>` `--pool-priority <value>`

*Argument:* `number` Pool priority

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### profile

Set the profile to use for this pool's settings.

*Available*: Pool

*Config File Syntax:* `"profile":"<value>"`

*Command Line Syntax:* `--pool-profile "<value>"`

*Argument:* `string` Pool profile name

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### quota

Replaces the pool [url](#url) when using the load-balance multipool strategy and enables setting a quota percentage for the pool.

*Available*: Pool

*Config File Syntax:* `"quota":"<value>"`

*Command Line Syntax:* `--quota "<value>"` `--pool-quota "<value>"` `-U "<value>"`

*Argument:* `string` Pool quota and url in the form `<quota percent>;<pool url>`

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]rawintensity

See [rawintensity](#rawintensity)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]shaders

See [shaders](#shaders)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### state

Set the pool state at startup.

*Available*: Pool

*Config File Syntax:* `"state":"<value>"`

*Command Line Syntax:* `--state "<value>"` `--pool-state "<value>"`

*Argument:* `string` Pool state. Possible values: `enabled` `disabled` `hidden` `rejecting`

*Default:* `enabled`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]thread-concurrency

See [thread-concurrency](#thread-concurrency)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### url

Set the Pool URL.

*Available*: Pool

*Config File Syntax:* `"url":"<value>"`

*Command Line Syntax:* `--url "<value>"` `--pool-url "<value>"` `-o "<value>"`

*Argument:* `string` Pool URL

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### user

Set the Pool username.

*Available*: Pool

*Config File Syntax:* `"user":"<value>"`

*Command Line Syntax:* `--user "<value>"` `--pool-user "<value>"` `-u "<value>"`

*Argument:* `string` Pool username

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### userpass

Set the Pool username and password.

*Available*: Pool

*Config File Syntax:* `"userpass":"<value>"`

*Command Line Syntax:* `--userpass "<value>"` `--pool-userpass "<value>"` `-O "<value>"`

*Argument:* `string` Pool username and password `<user>:<pass>`

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]worksize

See [worksize](#worksize)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

### [pool-]xintensity

See [intensity](#xintensity)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Options](#pool-options)

---

## Pool Strategy Options

### balance

Changes the multipool strategy to even share balance.

*Available*: Global

*Config File Syntax:* `"balance":true`

*Command Line Syntax:* `--balance`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Strategy Options](#pool-strategy-options)

### disable-rejecting

Automatically disable a pool that continually reject shares.

*Available*: Global

*Config File Syntax:* `"disable-rejecting":true`

*Command Line Syntax:* `--disable-rejecting`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Strategy Options](#pool-strategy-options)

### failover-only

Use the first pool alive based on pool priority.

*Available*: Global

*Config File Syntax:* `"failover-only":true`

*Command Line Syntax:* `--failover-only`

*Argument:* None

*Default:* `true`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Strategy Options](#pool-strategy-options)

### failover-switch-delay

Number of seconds to wait before switching back to a previously failed pool.

*Available*: Global

*Config File Syntax:* `"failover-switch-delay":"<value>"`

*Command Line Syntax:* `--failover-switch-delay <value>`

*Argument:* `number` Number of seconds between 1 and 65535.

*Default:* `60`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Strategy Options](#pool-strategy-options)

### load-balance

Changes the multipool strategy to quota based balance.

**Note:** Use [quota](#quota) instead of [url](#url) in pool settings when using this multipool strategy.

*Available*: Global

*Config File Syntax:* `"load-balance":true`

*Command Line Syntax:* `--load-balance`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Strategy Options](#pool-strategy-options)

### rotate

Changes the multipool strategy to rotate between pools after a certain amount of time in seconds.

*Available*: Global

*Config File Syntax:* `"rotate":"<value>"`

*Command Line Syntax:* `--rotate <value>`

*Argument:* `number` Number of seconds between 0 and 9999 before switching to the next pool

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Strategy Options](#pool-strategy-options)

### round-robin

Changes the multipool strategy to round-robin.

*Available*: Global

*Config File Syntax:* `"round-robin":true`

*Command Line Syntax:* `--round-robin`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Pool Strategy Options](#pool-strategy-options)

---

## Profile Options

### [profile-]algorithm

See [algorithm](#algorithm)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]device

See [device](#device).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]gpu-engine

See [gpu-engine](#gpu-engine).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]gpu-fan

See [gpu-fan](#gpu-fan).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]gpu-memclock

See [gpu-memclock](#gpu-memclock).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]gpu-powertune

See [gpu-powertune](#gpu-powertune).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]gpu-threads

See [gpu-threads](#gpu-threads).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]gpu-vddc

See [gpu-vddc](#gpu-vddc).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]intensity

See [intensity](#intensity).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]lookup-gap

See [lookup-gap](#lookup-gap).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]name

Set a name for a profile.

**Note** if no profile name is set, the profile name defaults to the profile number in the order that
it was entered starting with `0`.

*Available*: Profile

*Config File Syntax:* `"name":"<value>"`

*Command Line Syntax:* `--profile-name "<value>"`

*Argument:* `string` Name of the profile

*Default:* `Profile number`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]nfactor

See [nfactor](#nfactor).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]rawintensity

See [rawintensity](#rawintensity).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]shaders

See [shaders](#shaders)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]thread-concurrency

See [thread-concurrency](#thread-concurrency)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]worksize

See [worksize](#worksize)

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

### [profile-]xintensity

See [xintensity](#xintensity).

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Profile Options](#profile-options)

---

## Miscellaneous Options

### compact

Use a compact display, without per device statistics.

*Available*: Global

*Config File Syntax:* `"compact":true`

*Command Line Syntax:* `--compact`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### debug

Enable debug output.

*Available*: Global

*Config File Syntax:* `"debug":true`

*Command Line Syntax:* `--debug` or `-D`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### debug-log

Enable debug logging when stderr is redirected to file.

*Available*: Global

*Config File Syntax:* `"debug-log":false`

*Command Line Syntax:* `--debug-log`

*Argument:* None

*Default:* `true`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### default-profile

Use this profile for sgminer's default settings.

*Available*: Global

*Config File Syntax:* `"default-profile":"<value>"`

*Command Line Syntax:* `--default-profile <value>`

*Argument:* `string` Profile name

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### device

Select devices to use.

**Note:** if you assign per-profile or per-pool devices to be turned on or off, it is recommended to specify `"device":"*"` on the other pools or profiles that should use all devices.

*Available*: Global, Pool, Profile

*Config File Syntax:* `"device":"<value>"`

*Command Line Syntax:* `--device "<value>"` `-d "<value>"` `--pool-device "<value>"` `--profile-device "<value>"`

*Argument:* `one value, range and/or a comma (,) separated list with a combination of both` To enable all devices use the asterisk (*) or the word "all".

*Default:* None (all devices enabled)

*Example:*

```
{
"pools":[
    {
        "url":"stratum+tcp://pool.ip:8334",
        "user":"user",
        "pass":"x"
    },
    {
        "url":"stratum+tcp://pool2.ip:3333",
        "user":"user",
        "pass":"x",
        "profile":"x11"
    }
],
"profiles":[
    {
        "name":"x11",
        "algorithm":"darkcoin-mod",
        "devices":"*"
    }
],
...
"algorithm":"ckolivas",
"device":"0,2-5"
...
}
```

The above would start mining `scrypt` on `pool.ip` with devices `0, 2, 3, 4, 5`. Upon switching to `pool2.ip`, all devices would be enabled to mine `x11`.

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### difficulty-multiplier

**DEPRECATED** Set the difficulty multiplier for jobs received from stratum pools.

*Available*: Global

*Config File Syntax:* `"difficulty-multiplier":"<value>"`

*Command Line Syntax:* `--difficulty-multiplier <value>`

*Argument:* `number` Decimal multiplier

*Default:* `0.0`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### expiry

Set how many seconds to wait after getting work before sgminer considers it a stale share.

*Available*: Global

*Config File Syntax:* `"expiry":"<value>"`

*Command Line Syntax:* `--expiry <value>` or `-E <value>`

*Argument:* `number` Number of seconds between 0 and 9999.

*Default:* `28`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### fix-protocol

**Need clarification** Do not redirect to a different getwork protocol (e.g. stratum).

*Available*: Global

*Config File Syntax:* `"fix-protocol":true`

*Command Line Syntax:* `--fix-protocol`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### incognito

Do not display user name in status window.

*Available*: Global

*Config File Syntax:* `"incognito":true`

*Command Line Syntax:* `--incognito`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### kernel-path

Path to where the kernel files are.

*Available*: Global

*Config File Syntax:* `"kernel-path":"<value>"`

*Command Line Syntax:* `--kernel-path "<value>"` `-K "<value>"`

*Argument:* `string` Path to kernel files

*Default:* `/path/to/sgminer`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### log

Set the interval in seconds between log outputs.

*Available*: Global

*Config File Syntax:* `"log":"<value>"`

*Command Line Syntax:* `--log <value>` `-l <value>`

*Argument:* `number` Number of seconds between 0 and 9999.

*Default:* `5`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### log-file

Log stderr to file.

*Available*: Global

*Config File Syntax:* `"log-file":"<path>"`

*Command Line Syntax:* `--log-file <path>`

*Argument:* `path` Path to log file, or FD number, or `-` to redirect to stdout.

*Default:* will log to stderr

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### log-show-date

Show a timestamp on every log line.

*Available*: Global

*Config File Syntax:* `"log-show-date":true`

*Command Line Syntax:* `--log-show-date` `-L`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### lowmem

Minimize caching of shares for low memory systems.

*Available*: Global

*Config File Syntax:* `"lowmem":true`

*Command Line Syntax:* `--lowmem`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### monitor

Use custom pipe command for output messages. **Only available on unix based operating systems.**

*Available*: Global

*Config File Syntax:* `"monitor":"<value>"`

*Command Line Syntax:* `--monitor "<value>"` `-m "<value>"`

*Argument:* `string` Command to pipe messages through.

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### more-notices

Display work restart and new block notices.

*Available*: Global

*Config File Syntax:* `"more-notices":true`

*Command Line Syntax:* `--more-notices`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### net-delay

Set small delays in networking not to overload slower routers.

*Available*: Global

*Config File Syntax:* `"net-delay":true`

*Command Line Syntax:* `--net-delay`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### no-client-reconnect

Disabled the 'client.reconnect' stratum functionality.

*Available*: Global

*Config File Syntax:* `"no-client-reconnect":true`

*Command Line Syntax:* `--no-client-reconnect`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### no-submit-stale

Do not submit shares that are detected as stale.

*Available*: Global

*Config File Syntax:* `"no-submit-stale":true`

*Command Line Syntax:* `--no-submit-stale`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### per-device-stats

Force output of per-device statistics.

*Available*: Global

*Config File Syntax:* `"per-device-stats":true`

*Command Line Syntax:* `--per-device-stats`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### protocol-dump

Force output of protocol-level activities.

*Available*: Global

*Config File Syntax:* `"protocol-dump":true`

*Command Line Syntax:* `--protocol-dump` `-P`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### queue

Minimum number of work items to have queued.

*Available*: Global

*Config File Syntax:* `"queue":"<value>"`

*Command Line Syntax:* `--queue <value>` `-Q <value>`

*Argument:* `number` Work items to have queued 0 to 9999

*Default:* `1`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### quiet

Disables logging output, display status and errors.

*Available*: Global

*Config File Syntax:* `"quiet":true`

*Command Line Syntax:* `--quiet` `-q`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### real-quiet

Disables all output.

*Available*: Global

*Config File Syntax:* `"real-quiet":true`

*Command Line Syntax:* `--real-quiet`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### remove-disabled

Remove disabled devices completely as if they never existed.

*Available*: Global

*Config File Syntax:* `"remove-disabled":true`

*Command Line Syntax:* `--remove-disabled`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### scan-time

Set how many seconds to spend scanning for current work.

*Available*: Global

*Config File Syntax:* `"scan-time":"<value>"`

*Command Line Syntax:* `--scan-time <value>` or `-s <value>`

*Argument:* `number` Number of seconds between 0 and 9999.

*Default:* `7`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### sched-start

Set a time of day to start mining at. Used with [sched-stop](#sched-stop).

*Available*: Global

*Config File Syntax:* `"sched-start":"<value>"`

*Command Line Syntax:* `--sched-start "<value>"`

*Argument:* `string` Time of day `HH:MM`

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### sched-stop

Set a time of day to stop mining at. Used with [sched-start](#sched-start).

*Available*: Global

*Config File Syntax:* `"sched-stop":"<value>"`

*Command Line Syntax:* `--sched-stop "<value>"`

*Argument:* `string` Time of day `HH:MM`

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### sharelog

Appends share log to file.

*Available*: Global

*Config File Syntax:* `"sharelog":"<value>"`

*Command Line Syntax:* `--sharelog "<value>"`

*Argument:* `string` Filename of log

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### shares

Quit after mining a certain amount of shares.

*Available*: Global

*Config File Syntax:* `"shares":"<value>"`

*Command Line Syntax:* `--shares <value>`

*Argument:* `number` Number of shares

*Default:* `Unlimited`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### socks-proxy

Use a socks4 proxy.

*Available*: Global

*Config File Syntax:* `"socks-proxy":"<value>"`

*Command Line Syntax:* `--socks-proxy "<value>"`

*Argument:* `string` Socks proxy settings `<host>:<port>`

*Default:* None

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### show-coindiff

Display the coin difficulty rather than the hash value of a share.

*Available*: Global

*Config File Syntax:* `"show-coindiff":true`

*Command Line Syntax:* `--show-coindiff`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### syslog

Output messages to syslog. **Note:** only available on operating systems with `syslogd`.

*Available*: Global

*Config File Syntax:* `"syslog":true`

*Command Line Syntax:* `--syslog`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### tcp-keepalive

Set the TCP keepalive packet idle timeout in seconds. **Note:** only available with libcurl and keepalive enabled.

*Available*: Global

*Config File Syntax:* `"tcp-keepalive":"<value>"`

*Command Line Syntax:* `--tcp-keepalive <value>`

*Argument:* `number` Number of seconds between 0 and 9999.

*Default:* `30`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### text-only

Disables the ncurses formatted screen output and user interface.

*Available*: Global

*Config File Syntax:* `"text-only":true`

*Command Line Syntax:* `--text-only` `-T`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### verbose

Outputs log and status to stderr. **Note:** only available on unix based operating systems.

*Available*: Global

*Config File Syntax:* `"verbose":true`

*Command Line Syntax:* `--verbose` `-v`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

### worktime

Displays extra work time debug information.

*Available*: Global

*Config File Syntax:* `"worktime":true`

*Command Line Syntax:* `--worktime`

*Argument:* None

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Config-file and CLI options](#config-file-and-cli-options) :: [Miscellaneous Options](#miscellaneous-options)

---

## Event options

* [on](#on)
* [runcmd](#runcmd)
* [reboot](#reboot)
* [reboot-delay](#reboot-delay)
* [quit](#quit)
* [quit-message](#quit-message)

### on

Specify which event type to respond on. See below for a list of supported [event types](#event-types)

*Available*: Events

*Config File Syntax:* `"on":"<value>"`

*Command Line Syntax:* `--event-on <value>`

*Argument:* `string` Name of the event type

*Default:* None

[Top](#configuration-and-command-line-options) :: [Event options](#event-options)

### runcmd

Specify a command to run when the event occurs. Please remember to properly escape quotes (") with backslashes (\\) if you need to specify multi-word parameters enclosed in quotes (") for your commands: `\"`

*Available*: Events

*Config File Syntax:* `"runcmd":"<value>"`

*Command Line Syntax:* `--event-runcmd <value>`

*Argument:* `string` Command to execute on event

*Default:* None

[Top](#configuration-and-command-line-options) :: [Event options](#event-options)

### reboot

Reboot when event occurs.

*Available*: Events

*Config File Syntax:* `"reboot":"<value>"`

*Command Line Syntax:* `--event-reboot <value>`

*Argument:* `string` Yes: `"true"` `"yes"` `"1"` or No: `"false"` `"no"` `"0"`

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Event options](#event-options)

### reboot-delay

Wait a number of seconds before rebooting when event occurs. This is useful if you also want to fire off a script via `runcmd` prior to rebooting, giving it extra seconds to finish.

*Available*: Events

*Config File Syntax:* `"reboot-delay":"<value>"`

*Command Line Syntax:* `--event-reboot-delay <value>`

*Argument:* `number` Seconds to wait before reboot

*Default:* `0`

[Top](#configuration-and-command-line-options) :: [Event options](#event-options)

### quit

Exit sgminer when event occurs.

*Available*: Events

*Config File Syntax:* `"quit":"<value>"`

*Command Line Syntax:* `--event-quit <value>`

*Argument:* `string` Yes: `"true"` `"yes"` `"1"` or No: `"false"` `"no"` `"0"`

*Default:* `false`

[Top](#configuration-and-command-line-options) :: [Event options](#event-options)

### quit-message

Message to display on sgminer exit when event occurs.

*Available*: Events

*Config File Syntax:* `"quit-message":"<value>"`

*Command Line Syntax:* `--event-quit-message "<value>"`

*Argument:* `string` Message

*Default:* `event_type`

[Top](#configuration-and-command-line-options) :: [Event options](#event-options)

---

## Event Types

* `idle` Occurs when a GPU goes idle for not performing any work or when no work has been received in 10 minutes.
* `gpu_sick` Occurs when a GPU fails to respond for 2 minutes
* `gpu_dead` Occurs when a GPU fails to respond for 10 minutes

[Top](#configuration-and-command-line-options)