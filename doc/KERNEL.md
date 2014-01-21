# Kernels

## Available OpenCL kernels

See directory `kernel`.


## Submitting new kernels

### Requirements

TODO


### Procedure

1. Copy the kernel you wish to modify and commit it verbatim.

This way, it is easy to verify that there are no hidden changes. Note in
the commit message which kernel is used as a base.

2. Make changes to the kernel. Commit them.

This way, it can be easily shown what was changed.

3. Search for KL_CKOLIVAS and CKOLIVAS_KERNNAME in the top-level source
directory and make additions to the listed files in order to integrate
the new kernel.

Now it can be selected when starting via the `--kernel` argument or
`kernel` configuration option.

4. Add yourself to the "kernels" section in `AUTHORS.md`. Keep it short.

5. Submit a pull request on GitHub, or file it at the issue tracker,
listing your git repository and branch name. The current repository and
issue tracker links should be in `README.md`.
