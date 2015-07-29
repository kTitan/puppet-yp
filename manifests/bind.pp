#
class yp::bind (
  $domain,
  $servers        = [],
  $manage_package = $::yp::params::bind_manage_package,
  $package_name   = $::yp::params::bind_package_name,
  $service_name   = $::yp::params::bind_service_name,
) inherits ::yp::params {

  validate_string($domain)
  validate_array($servers)
  validate_bool($manage_package)
  if $manage_package {
    validate_string($package_name)
  }
  validate_string($service_name)

  include ::yp::bind::install
  include ::yp::bind::config
  include ::yp::bind::service

  anchor { 'yp::bind::begin': }
  anchor { 'yp::bind::end': }

  Anchor['yp::bind::begin'] -> Class['::yp::bind::install']
    -> Class['::yp::bind::config'] ~> Class['::yp::bind::service']
    -> Anchor['yp::bind::end']
}
