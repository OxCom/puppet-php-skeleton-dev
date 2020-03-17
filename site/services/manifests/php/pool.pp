class services::php::pool (
  Array $versions = [],
  Hash $pools     = {}
) {
  # Вуафгде pool named 'www'
  # Additional pools will be created per projects for all versions
  # Each array with string key thatcontains nesting array will be converted to folder
  info("Initialize")

  $versions.each |Integer $index, String $version| {
    $num = regsubst($version, 'php', '');

    service { "$version-fpm":
      ensure  => "running",
      enable  => "true",
      require => Package["$version-fpm"],
    }

    $pools.each |String $project, Array $list| {
      $dir = "/etc/php/$num/fpm/pool.d/$project.d/"

      file { $dir:
        ensure  => directory,
        recurse => true,
      }

      file_line { "$version-fpm-$project-config":
        ensure  => present,
        path    => "/etc/php/$num/fpm/php-fpm.conf",
        line    => "include=/etc/php/$num/fpm/pool.d/$project.d/*.conf",
        notify  => Service["$version-fpm"],
        require => [
          Package["$version-fpm"],
          File[$dir],
        ]
      }

      $list.each |Integer $index, Hash $pool| {
        $name = $pool['name'];
        $file = "/etc/php/$num/fpm/pool.d/$project.d/$name.conf"

        file { $file:
          ensure  => file,
          content => epp('services/php/pool.conf.epp', {
            'version' => $version,
            'project' => $project,
            'pool'    => $name
          }),
          notify  => Service["$version-fpm"],
          require => [
            Package["$version-fpm"],
            File[$dir]
          ]
        }
      }
    }
  }
}
