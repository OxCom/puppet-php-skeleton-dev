class services::nginx (
    Array $versions = $services::nginx::params::versions,
    Hash $projects  = $services::nginx::params::projects,
    String $domain  = $services::nginx::params::domain
) inherits services::nginx::params {
    info("Initialize")

    require services::nginx::package

    class { 'services::nginx::php_fpm':
        versions => $versions,
        projects => $projects,
    }

    class { 'services::nginx::www':
        versions => $versions,
        projects => $projects,
        domain   => $domain,
    }

    info("Generate snippets")
    info("[Snippet]: SSL")
    file { '/etc/nginx/snippets/ssl.conf':
        ensure  => file,
        content => template('services/nginx/snippet/ssl.conf.erb'),
        notify  => Service["nginx"],
        owner   => 'root',
        group   => 'root',
        require => [
            File['/etc/nginx/snippets']
        ]
    }

    info("[Snippet]: Static")
    file { '/etc/nginx/snippets/static.conf':
        ensure  => file,
        content => template('services/nginx/snippet/static.conf.erb'),
        notify  => Service["nginx"],
        owner   => 'root',
        group   => 'root',
        require => [
            File['/etc/nginx/snippets']
        ]
    }

    info("Generate conf.d")
    info("[conf.d]: GZip")
    file { '/etc/nginx/conf.d/01-gzip.conf':
        ensure  => file,
        content => template('services/nginx/conf.d/gzip.conf.erb'),
        notify  => Service["nginx"],
        owner   => 'root',
        group   => 'root',
        require => [
            File['/etc/nginx/conf.d']
        ]
    }

    info("[conf.d]: performance")
    file { '/etc/nginx/conf.d/01-perf.conf':
        ensure  => file,
        content => template('services/nginx/conf.d/perf.conf.erb'),
        notify  => Service["nginx"],
        owner   => 'root',
        group   => 'root',
        require => [
            File['/etc/nginx/conf.d']
        ]
    }
}
