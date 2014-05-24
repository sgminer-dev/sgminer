# Bug reporting

First and foremost, see `README.md` and other documentation in `doc`.
Although the documentation might be outdated, a lot of it is still
relevant.

The [issue tracker](https://github.com/veox/sgminer/issues) is there
specifically for reporting bugs, issues and proposed improvements. Other
communication channels are not necessarily monitored.

Search the issue list to see if it has already been reported.

Make the title of your report informative.

Information that may be relevant, depending on the nature of your issue:

* OS version;
* Catalyst driver version;
* AMD APP SDK version;
* AMD ADL version;
* GPUs used (`sgminer --ndevs`);
* whether you're using a pre-compiled binary or built from source;
* `sgminer` version (`sgminer --version` and/or `git describe`);
* contents of the configuration file and pool connection info;
* launch procedure (manual or via script);
* steps to repeat;
* expected result;
* actual result;
* debug output (`sgminer --text-only --debug --verbose`).

Be careful when posting the contents of your configuration file: although
pool connection and protocol information is relevant in a certain sub-class
of issues, login credentials (username and password) are most often not. Run
with `--incognito` if possible.

If there is a need to provide more than a screenfull of log
data, it is preferred that a link is given instead. Try
[gist](https://gist.github.com).
