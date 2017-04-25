#
class yp::bind::config {

  $domain  = $::yp::bind::domain
  $servers = $::yp::bind::servers

  case $::osfamily { # lint:ignore:case_without_default
    'OpenBSD': {
      file { '/etc/yp':
        ensure  => directory,
        owner   => 0,
        group   => 0,
        mode    => '0644',
        purge   => true,
        recurse => true,
      }

      if size($servers) > 0 {
        file { "/etc/yp/${domain}":
          ensure  => file,
          owner   => 0,
          group   => 0,
          mode    => '0644',
          content => template('yp/domain.erb'),
        }
      }

      # Use augeas to add the '+:*::::::::' record to /etc/master.passwd
      augeas { '/etc/master.passwd/nisdefault':
        context => '/files/etc/master.passwd',
        changes => [
          'clear @nisdefault',
          'set @nisdefault/password "*"',
          'set @nisdefault/uid ""',
          'set @nisdefault/gid ""',
          'clear @nisdefault/class',
          'set @nisdefault/change_date ""',
          'set @nisdefault/expire_date ""',
          'clear @nisdefault/name',
          'clear @nisdefault/home',
          'clear @nisdefault/shell',
        ],
      }

      exec { 'pwd_mkdb -p /etc/master.passwd':
        path        => ['/usr/sbin'],
        refreshonly => true,
        subscribe   => Augeas['/etc/master.passwd/nisdefault'],
      }

      # Use augeas to add the '+:::' record to /etc/group
      augeas { '/etc/group/nisdefault':
        context => '/files/etc/group',
        changes => [
          'clear @nisdefault',
          'set @nisdefault/password "*"',
          'set @nisdefault/gid ""',
        ],
      }

      if versioncmp($::augeasversion, '1.4.0') < 0 {
        file { '/usr/local/share/augeas/lenses/passwd.aug':
          ensure  => file,
          owner   => 0,
          group   => 0,
          mode    => '0644',
          content => file('yp/passwd.aug'),
        }
      }

      if versioncmp($::augeasversion, '1.5.0') < 0 {
        file { '/usr/local/share/augeas/lenses/masterpasswd.aug':
          ensure  => file,
          owner   => 0,
          group   => 0,
          mode    => '0644',
          content => file('yp/masterpasswd.aug'),
          before  => Augeas['/etc/master.passwd/nisdefault'],
        }

        file { '/usr/local/share/augeas/lenses/group.aug':
          ensure  => file,
          owner   => 0,
          group   => 0,
          mode    => '0644',
          content => file('yp/group.aug'),
          before  => Augeas['/etc/group/nisdefault'],
        }
      }
    }
    'RedHat': {
      file { '/etc/yp.conf':
        ensure  => file,
        owner   => 0,
        group   => 0,
        mode    => '0644',
        content => template('yp/yp.conf.erb'),
      }

      if $::yp::bind::manage_nsswitch {
        class { '::nsswitch':
          passwd    => ['files', 'nis', 'sss'],
          shadow    => ['files', 'nis', 'sss'],
          group     => ['files', 'nis', 'sss'],
          hosts     => ['files', 'nis', 'dns'],
          netgroup  => ['files', 'nis', 'sss'],
          automount => ['files', 'nis'],
        }
      }

      pam { 'nis':
        ensure    => present,
        service   => 'system-auth-ac',
        type      => 'password',
        control   => 'sufficient',
        module    => 'pam_unix.so',
        arguments => [
          'md5',
          'shadow',
          'nis',
          'nullok',
          'try_first_pass',
          'use_authtok',
        ],
      }
    }
  }
}
