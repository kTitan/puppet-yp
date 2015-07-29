#
class yp::ldap (
  $base_dn,
  $domain,
  $server,
  $bind_dn          = undef,
  $bind_pw          = undef,
  $conf_file        = $::yp::params::ldap_conf_file,
  $fixed_attributes = {
    'passwd'      => '*',
    'change'      => '0',
    'expire'      => '0',
    'class'       => 'ldap',
    'grouppasswd' => '*',
  },
  $group_dn         = undef,
  $group_filter     = '(objectClass=posixGroup)',
  $interval         = 60,
  $ldap_attributes  = {
    'name'      => 'uid',
    'uid'       => 'uidNumber',
    'gid'       => 'gidNumber',
    'gecos'     => 'cn',
    'home'      => 'homeDirectory',
    'shell'     => 'loginShell',
    'groupname' => 'cn',
    'groupgid'  => 'gidNumber',
  },
  $list_attributes  = {
    'groupmembers' => 'memberUid',
  },
  $maps             = $::yp::params::ldap_maps,
  $service_name     = $::yp::params::ldap_service_name,
  $user_filter      = '(objectClass=posixAccount)',
) inherits ::yp::params {

  if $::osfamily != 'OpenBSD' {
    fail("The yp::ldap class is not supported on ${::osfamily} based systems.") # lint:ignore:80chars
  }

  if defined(Class['::yp::serv']) {
    fail('yp::serv and yp::ldap are mutually exclusive.')
  }

  validate_array($maps)

  include ::yp::ldap::config
  include ::yp::ldap::service

  anchor { 'yp::ldap::begin': }
  anchor { 'yp::ldap::end': }

  Anchor['yp::ldap::begin'] -> Class['::yp::ldap::config']
    ~> Class['::yp::ldap::service'] -> Anchor['yp::ldap::end']
}
