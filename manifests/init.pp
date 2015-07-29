#
class yp (
  $domain,
  $yp_dir = $::yp::params::yp_dir,
) inherits ::yp::params {

  validate_string($domain)

  include ::yp::config

  anchor { 'yp::begin': }
  anchor { 'yp::end': }

  Anchor['yp::begin'] -> Class['::yp::config'] -> Anchor['yp::end']
}
