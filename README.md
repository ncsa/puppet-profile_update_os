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

This puppet profile customizes a host to apply OS package updates.

## Setup

Include profile_update_os in a puppet profile file:
```
include ::profile_update_os
```

## Usage

The goal is that no paramters are required to be set. The default paramters should work for most NCSA deployments out of the box.

## Reference

See: [REFERENCE.md](REFERENCE.md)

## Limitations

n/a

## Development

This Common Puppet Profile is managed by NCSA for internal usage.
