# yp

Tested with Travis CI

[![Build Status](https://travis-ci.org/bodgit/puppet-yp.svg?branch=master)](https://travis-ci.org/bodgit/puppet-yp)
[![Coverage Status](https://coveralls.io/repos/bodgit/puppet-yp/badge.svg?branch=master&service=github)](https://coveralls.io/github/bodgit/puppet-yp?branch=master)
[![Puppet Forge](http://img.shields.io/puppetforge/v/bodgit/yp.svg)](https://forge.puppetlabs.com/bodgit/yp)
[![Dependency Status](https://gemnasium.com/bodgit/puppet-yp.svg)](https://gemnasium.com/bodgit/puppet-yp)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with yp](#setup)
    * [What yp affects](#what-yp-affects)
    * [Beginning with yp](#beginning-with-yp)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Classes and Defined Types](#classes-and-defined-types)
        * [Class: yp](#class-yp)
        * [Class: yp::bind](#class-ypbind)
        * [Class: yp::ldap](#class-ypldap)
        * [Class: yp::serv](#class-ypserv)
    * [Examples](#examples)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module manages YP/NIS.

## Module Description

This module can configure the YP/NIS domain, manage the `ypbind` daemon to
bind a client to a YP server and create and maintain master & slave YP servers
using `ypserv` and associated daemons. It can also in the special case of
OpenBSD manage the `ypldap` daemon to fetch YP maps from LDAP.

## Setup

### What yp affects

* The package(s) providing YP support.
* Managing the necessary configuration to bind a client to a YP domain.
* Updating the client to use the YP maps. Either:
  * Adding traditional `+::...` entries to the bottom of `/etc/passwd`,
    `/etc/group`.
  * Updating `/etc/nsswitch.conf` and PAM.
* Managing the necessary configuration for building YP maps on a standalone
  or master YP server.
* On a slave YP server transferring YP maps from a master YP server.
* The services controlling the `ypbind`, `ypserv` & `ypldap` daemons.

### Beginning with yp

```puppet
class { '::yp':
  domain => 'example.com',
}
```

## Usage

### Classes and Defined Types

#### Class: `yp`

**Parameters within `yp`:**

##### `domain`

The YP/NIS domain.

##### `yp_dir`

The base YP directory, usually `/var/yp`.

#### Class: `yp::bind`

**Parameters within `yp::bind`:**

##### `domain`

The YP/NIS domain.

##### `servers`

An array of YP servers to use, if left empty will default to broadcasting.

##### `manage_nsswitch`

Whether to manage a nsswitch.conf or not on supported systems.

##### `manage_package`

Whether to manage a package or not. Some operating systems have `ypbind` as
part of the base system.

##### `package_name`

The name of the package to install that provides the `ypbind` daemon.

##### `service_name`

The name of the service managing `ypbind`.

#### Class: `yp::ldap`

**Parameters within `yp::ldap`:**

##### `base_dn`

The base DN from which to perform all LDAP queries.

##### `domain`

The YP/NIS domain for which to provide maps fetched from LDAP.

##### `server`

The LDAP server to use.

##### `bind_dn`

The Distinguiѕhed Name to use to bind to the LDAP server.

##### `bind_pw`

The password to use when binding to the LDAP server.

##### `conf_file`

The location of the configuration file, usually `/etc/ypldap.conf`.

##### `fixed_attributes`

A hash of YP map attributes that should not be looked up from LDAP, but
hardcoded to a particular value. Keys should be one or more of `name`,
`passwd`, `uid`, `gid`, `gecos`, `home`, `shell`, `change`, `expire`, `class`,
`groupname`, `grouppasswd`, `groupgid`, or `groupmembers`. The defaults are:

```puppet
{
  'passwd'      => '*',
  'change'      => '0',
  'expire'      => '0',
  'class'       => 'ldap',
  'grouppasswd' => '*',
}
```

This blanks out any passwords, disables any account or password expiry and
places all users into the `ldap` login class.

Values in this parameter will be used in preference to any provided by
`ldap_attributes` or `list_attributes`.

##### `group_dn`

The base DN from which to perform group LDAP queries, if different from
`base_dn`.

##### `group_filter`

The LDAP search filter to use when searching for groups, defaults to
`(objectClass=posixGroup)`.

##### `interval`

How often to refresh the maps from LDAP, defaults to 60 seconds.

##### `ldap_attributes`

A hash of YP map attributes that should be looked up from regular LDAP
attributes. Keys should be one or more of `name`, `passwd`, `uid`, `gid`,
`gecos`, `home`, `shell`, `change`, `expire`, `class`, `groupname`,
`grouppasswd`, `groupgid`, or `groupmembers`. The defaults are:

```puppet
{
  'name'      => 'uid',
  'uid'       => 'uidNumber',
  'gid'       => 'gidNumber',
  'gecos'     => 'cn',
  'home'      => 'homeDirectory',
  'shell'     => 'loginShell',
  'groupname' => 'cn',
  'groupgid'  => 'gidNumber',
}
```

These map to the standard RFC 2307(bis) attributes.

Values in this parameter have the lowest precedence compared to
`fixed_attributes` and `list_attributes`.

##### `list_attributes`

A hash of YP map attributes that should be looked up from regular LDAP
attributes but in the case of multiple values should be joined together with
commas.  Keys should be one or more of `name`, `passwd`, `uid`, `gid`,
`gecos`, `home`, `shell`, `change`, `expire`, `class`, `groupname`,
`grouppasswd`, `groupgid`, or `groupmembers`. The defaults are:

```puppet
{
  'groupmembers' => 'memberUid',
}
```

This maps to the standard RFC 2307(bis) attributes.

Values in this parameter take precedence over any defined in `ldap_attributes`.

##### `maps`

The list of YP maps to provide based on LDAP searches. The defaults are
`passwd.byname`, `passwd.byuid`, `group.byname`, `group.bygid`, and
`netid.byname`.

##### `service_name`

The name of the service managing `ypldap`.

##### `user_filter`

The LDAP search filter to use when searching for users, defaults to
`(objectClass=posixAccount)`.

#### Class: `yp::serv`

**Parameters within `yp::serv`:**

##### `domain`

The YP/NIS domain.

##### `has_ypxfrd`

Does this platform provide a `ypxfrd` daemon to help map transfers.

##### `manage_package`

Whether to manage a package or not. Some operating systems have `ypserv` as
part of the base system.

##### `maps`

The YP maps to build, `passwd.byname`, `group.bygid`, etc. The default is to
try and build all supported maps which often includes some esoteric ones.

##### `map_extension`

The file extension added to compiled maps, often `.db`.

##### `master`

If this is a slave YP server, the IP address of the master.

##### `merge_group`

Whether to merge group passwords into the group maps.

##### `merge_passwd`

Whether to merge user passwords into the passwd maps, on some platforms this
allows a separate `shadow.byname` map to be created.

##### `minimum_gid`

Any GID lower than this will not be included in the group maps. Defaults to
1000.

##### `minimum_uid`

Any UID lower than this will not be included in the passwd maps. Defaults to
1000.

##### `package_name`

The name of the package to install that provides the `ypserv` daemon.

##### `yppasswdd_service_name`

The name of the service managing `yppasswdd`.

##### `ypserv_service_name`

The name of the service managing `ypserv`.

##### `ypxfrd_service_name`

The name of the service managing `ypxfrd`.

##### `slaves`

If this is a master server, specify the slaves which will be notified when a
map is updated.

##### `yp_dir`

The base YP directory, usually `/var/yp`.

### Examples

Set the YP domain:

```puppet
class { '::yp':
  domain => 'example.com',
}
```

Bind a client to a YP domain using three YP servers:

```puppet
include ::portmap

class { '::yp':
  domain => 'example.com',
}

class { '::yp::bind':
  domain  => 'example.com',
  servers => ['192.0.2.1', '192.0.2.2', '192.0.2.3'],
}

Class['::portmap'] ~> Class['::yp::bind'] <~ Class['::yp']
```

Create a standalone YP server:

```puppet
include ::portmap

class { '::yp':
  domain => 'example.com',
}

class { '::yp::serv':
  domain => 'example.com',
}

Class['::portmap'] ~> Class['::yp::serv'] <- Class['::yp']
```

Create a master YP server with two additional slaves:

```puppet
include ::portmap

class { '::yp':
  domain => 'example.com',
}

class { '::yp::serv':
  domain => 'example.com',
  maps   => [
    'passwd.byname',
    'passwd.byuid',
    'group.bygid',
    'group.byname',
    'netid.byname',
  ],
  slaves => ['192.0.2.2', '192.0.2.3'],
}

Class['::portmap'] ~> Class['::yp::serv'] <- Class['::yp']
```

Create a slave YP server pointing at the above master YP server:

```puppet
include ::portmap

class { '::yp':
  domain => 'example.com',
}

class { '::yp::serv':
  domain => 'example.com',
  maps   => [
    'passwd.byname',
    'passwd.byuid',
    'group.bygid',
    'group.byname',
    'netid.byname',
  ],
  master => '192.0.2.1',
}

class { '::yp::bind':
  domain => 'example.com',
}

Class['::portmap'] ~> Class['::yp::serv'] <- Class['::yp']
Class['::yp::serv'] -> Class['::yp::bind'] <~ Class['::yp']
```

For OpenBSD only, set up `ypldap` to create YP maps from an LDAP server and
also bind to it. This is the equivalent to PAM/LDAP:

```puppet
include ::portmap

class { '::yp::ldap':
  base_dn => 'dc=example,dc=com',
  bind_dn => 'cn=ypldap,dc=example,dc=com',
  bind_pw => 'password',
  domain  => 'example.com',
  server  => '192.0.2.1',
}

class { '::yp':
  domain => 'example.com',
}

class { '::yp::bind':
  domain => 'example.com',
}

Class['::portmap'] ~> Class['::yp::ldap'] ~> Class['::yp::bind'] <~ Class['::yp']
```

## Reference

### Classes

#### Public Classes

* [`yp`](#class-yp): Main class for configuring the YP/NIS domain.
* [`yp::bind`](#class-ypbind): Main class for installing and managing `ypbind` daemon.
* [`yp::ldap`](#class-ypldap): Main class for installing and managing `ypldap` daemon.
* [`yp::serv`](#class-ypserv): Main class for installing and managing `ypserv` daemon.

#### Private Classes

* `yp::config`: Handles YP/NIS configuration.
* `yp::params`: Different configuration data for different systems.
* `yp::bind::config`: Handles `ypbind` configuration.
* `yp::bind::install`: Handles `ypbind` installation.
* `yp::bind::service`: Handles starting the `ypbind` daemon.
* `yp::ldap::config`: Handles `ypldap` configuration.
* `yp::ldap::service`: Handles starting the `ypldap` daemon.
* `yp::serv::config`: Handles `ypserv` configuration.
* `yp::serv::install`: Handles `ypserv` installation.
* `yp::serv::service`: Handles starting the `ypserv` daemon.

### Defined Types

#### Private Defined Types

* `yp::serv::map`: Handles creating or transferring YP maps.

## Limitations

This module was primarily written with deploying `ypldap` on OpenBSD in mind
however to do that I realised I had classes for everything bar `ypserv` so I
added that and made sure it was portable enough to work on one other OS. It
works however I don't expect many people to still be using traditional YP/NIS.

This module has been built on and tested against Puppet 3.0 and higher.

The module has been tested on:

* OpenBSD 5.7/5.8/5.9
* RedHat/CentOS Enterprise Linux 7

Testing on other platforms has been light and cannot be guaranteed.

## Development

Please log issues or pull requests at
[github](https://github.com/bodgit/puppet-yp).
