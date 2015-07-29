#
class yp::config {

  $domain = $::yp::domain

  case $::osfamily { # lint:ignore:case_without_default
    'OpenBSD': {
      file { '/etc/defaultdomain':
        ensure  => file,
        owner   => 0,
        group   => 0,
        mode    => '0644',
        content => "${domain}\n",
      }
    }
    'RedHat': {
      augeas { '/etc/sysconfig/network/NISDOMAIN':
        context => '/files/etc/sysconfig/network',
        changes => [
          'rm NISDOMAIN',
          "set NISDOMAIN ${domain}",
        ],
      }
    }
  }

  exec { "domainname ${domain}":
    path   => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
    unless => "domainname | grep -q ^${domain}\$",
  }

  file { $::yp::yp_dir:
    ensure => directory,
    owner  => 0,
    group  => 0,
    mode   => '0644',
  }
}
