# profile_update_os

![pdk-validate](https://github.com/ncsa/puppet-profile_update_os/workflows/pdk-validate/badge.svg)
![yamllint](https://github.com/ncsa/puppet-profile_update_os/workflows/yamllint/badge.svg)

NCSA Common Puppet Profiles - configure update of os packages

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with profile_update_os](#setup)
    * [What profile_update_os affects](#what-profile_update_os-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with profile_update_os](#beginning-with-profile_update_os)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This puppet profile customizes a host to apply OS package updates. Optionally allows to set a scheduled reboot cycle, or install kpatch and kpatch-patch packages

## Setup

Include profile_update_os in a puppet profile file:
```
include ::profile_update_os
```

## Usage

### kpatch

Currently only supported on Redhat hosts (centos/rocky do not appear to publish kpatch-patch packages)

kpatch allows patching for kernel vulnerabilities without rebooting (host stays on current kernel version but gets a package which makes the old kernel safe).

Setting `profile_update_os::kpatch::enabled` to `true` will install the kpatch package and start the kpatch service. This will not mitigate anything, but will make the host ready to install a kpatch-patch if needed. Default for this setting is `true`.

Setting `profile_update_os::kpatch::install_kpatch_patches` to `true` will install the kpatch-patch for the current kernel (kpatch installs an "empty" kpatch-patch if there are no existing kpatch-patches available). Default for this setting is `false`. See [REFERENCE.md](REFERENCE.md) for using `profile_update_os::kpatch::kpatch_patch_version` if you need to lock kpatch-patch to a particular version.

In general the default kpatch settings should be fine. When there is a vulnerability that needs patching with a kpatch you'd just change `profile_update_os::kpatch::install_kpatch_patches` to `true` until your hosts are on a kernel that is fixed, at which point you can then revert back to the default `profile_update_os::kpatch::install_kpatch_patches: false`.

## Reference

See: [REFERENCE.md](REFERENCE.md)

## Limitations

n/a

## Development

This Common Puppet Profile is managed by NCSA for internal usage.
