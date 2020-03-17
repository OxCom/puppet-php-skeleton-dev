class services::nginx::php_fpm (
    Array $versions = $services::nginx::params::versions,
    Hash $projects  = $services::nginx::params::projects
) inherits services::nginx::params {
    info("Initialize")

    file { "/etc/nginx/conf.d/":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        require => [
            Package['nginx-full']
        ]
    }

    file { '/etc/nginx/conf.d/php-upstreams.conf':
        ensure  => file,
        content => template('services/nginx/php-upstreams.conf.erb'),
        notify  => Service["nginx"],
        require => [
            File["/etc/nginx/conf.d/"]
        ]
    }
}
