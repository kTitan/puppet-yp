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

  validate_string($base_dn)
  validate_ldap_dn($base_dn)
  validate_string($domain)
  validate_string($server)
  if $bind_dn {
    validate_string($bind_dn)
    validate_ldap_dn($bind_dn)
  }
  validate_string($bind_pw)
  validate_absolute_path($conf_file)
  validate_hash($fixed_attributes)
  if $group_dn {
    validate_string($group_dn)
    validate_ldap_dn($group_dn)
  }
  validate_string($group_filter)
  validate_ldap_filter($group_filter)
  validate_integer($interval, '', 1)
  validate_hash($ldap_attributes)
  validate_hash($list_attributes)
  validate_array($maps)
  validate_string($service_name)
  validate_string($user_filter)
  validate_ldap_filter($user_filter)

  include ::yp::ldap::config
  include ::yp::ldap::service

  anchor { 'yp::ldap::begin': }
  anchor { 'yp::ldap::end': }

  Anchor['yp::ldap::begin'] -> Class['::yp::ldap::config']
    ~> Class['::yp::ldap::service'] -> Anchor['yp::ldap::end']
}
