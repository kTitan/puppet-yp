#
class yp::serv (
  $domain,
  $has_ypxfrd             = $::yp::params::serv_has_ypxfrd,
  $manage_package         = $::yp::params::serv_manage_package,
  $maps                   = $::yp::params::serv_maps,
  $map_extension          = $::yp::params::serv_map_extension,
  $master                 = undef,
  $merge_group            = $::yp::params::serv_merge_group,
  $merge_passwd           = $::yp::params::serv_merge_passwd,
  $minimum_gid            = $::yp::params::serv_minimum_gid,
  $minimum_uid            = $::yp::params::serv_minimum_uid,
  $package_name           = $::yp::params::serv_package_name,
  $yppasswdd_service_name = $::yp::params::serv_yppasswdd_service_name,
  $ypserv_service_name    = $::yp::params::serv_ypserv_service_name,
  $ypxfrd_service_name    = $::yp::params::serv_ypxfrd_service_name,
  $slaves                 = [],
  $yp_dir                 = $::yp::params::yp_dir,
) inherits ::yp::params {

  if defined(Class['::yp::ldap']) {
    fail('yp::ldap and yp::serv are mutually exclusive.')
  }

  validate_string($domain)
  validate_bool($has_ypxfrd)
  validate_bool($manage_package)
  validate_array($maps)
  if $master {
    validate_string($master)
  }
  validate_bool($merge_group)
  validate_bool($merge_passwd)
  if $manage_package {
    validate_string($package_name)
  }
  validate_integer($minimum_gid)
  validate_integer($minimum_uid)
  validate_string($yppasswdd_service_name)
  validate_string($ypserv_service_name)
  if $has_ypxfrd {
    validate_string($ypxfrd_service_name)
  }
  validate_array($slaves)
  validate_absolute_path($yp_dir)

  include ::yp::serv::install
  include ::yp::serv::config
  include ::yp::serv::service

  anchor { 'yp::serv::begin': }
  anchor { 'yp::serv::end': }

  Anchor['yp::serv::begin'] -> Class['::yp::serv::install']
    -> Class['::yp::serv::config'] ~> Class['::yp::serv::service']
    -> Anchor['yp::serv::end']
}
