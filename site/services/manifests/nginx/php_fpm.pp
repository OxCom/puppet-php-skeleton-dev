class services::nginx::php_fpm (
    Array $versions = $services::nginx::params::versions,
    Hash $projects  = $services::nginx::params::projects
) inherits services::nginx::params {
    info("Initialize")

    file { '/etc/nginx/conf.d/php-upstreams.conf':
        ensure  => file,
        content => template('services/nginx/php-upstreams.conf.erb'),
        notify  => Service["nginx"],
        require => [
            File["/etc/nginx/conf.d"]
        ]
    }
}
