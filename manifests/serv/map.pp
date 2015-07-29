#
define yp::serv::map (
  $domain,
  $extension,
  $master,
  $yp_dir,
) {

  if $master {
    exec { "ypxfr -h ${master} -c -d ${domain} ${name}":
      path    => [
        '/sbin',
        '/usr/sbin',
        '/bin',
        '/usr/bin',
        '/usr/lib/yp',
        '/usr/lib64/yp',
      ],
      creates => "${yp_dir}/${domain}/${name}${extension}",
      require => File["${yp_dir}/${domain}"],
    }
  } else {
    $target = yp_map_to_make_target($name)

    case $::osfamily { # lint:ignore:case_without_default
      'OpenBSD': {
        $make     = "make ${target}"
        $makefile = "${yp_dir}/${domain}/Makefile"
      }
      'RedHat': {
        $make     = "make -f ../Makefile ${target}"
        $makefile = "${yp_dir}/Makefile"
      }
    }

    # The exec is created and tested against the first map generated from the
    # associated database, i.e. for passwd.byname and passwd.byuid, the exec
    # will be created to only check that passwd.byname.db is created on disk
    if ! defined(Exec[$make]) {
      exec { $make:
        path    => [
          '/sbin',
          '/usr/sbin',
          '/bin',
          '/usr/bin',
          '/usr/lib/yp',
          '/usr/lib64/yp',
        ],
        cwd     => "${yp_dir}/${domain}",
        creates => "${yp_dir}/${domain}/${name}${extension}",
        require => File[$makefile],
      }
    }
  }
}
