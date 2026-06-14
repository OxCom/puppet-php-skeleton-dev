class services::nginx::package {
    info("Initialize")

    require services::nginx::ppa

    # Drop apache and free 80 port
    package { 'apache2':
        ensure => 'purged',
    }

    # Purge Ubuntu-repo nginx packages before installing from nginx.org official repo.
    # The Ubuntu packages split stream support into libnginx-mod-stream; the official
    # nginx.org package ships as a monolithic build with stream included.
    $ubuntu_nginx_packages = [
        'nginx-common',
        'nginx-core',
        'nginx-full',
        'nginx-light',
        'nginx-extras',
    ]
    package { $ubuntu_nginx_packages:
        ensure => 'purged',
        before => Package['nginx'],
    }

    package { 'nginx':
        ensure  => present,
        require => [
            Package['apache2'],
            Package[$ubuntu_nginx_packages],
            Class['services::nginx::ppa'],
        ]
    }

    service { "nginx":
        ensure  => "running",
        enable  => "true",
        require => Package["nginx"],
    }

    user { 'vagrant':
        ensure  => present,
        groups  => ['www-data'],
        require => Package["nginx"],
    }

    # Explicitly manage the base directory so all subdirectory resources have a
    # guaranteed parent, even after purging Ubuntu's nginx-common (which owned it).
    file { '/etc/nginx':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['nginx'],
    }

    file { '/etc/nginx/snippets':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => File['/etc/nginx'],
    }

    file { '/etc/nginx/conf.d':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => File['/etc/nginx'],
    }

    file { '/etc/nginx/ssl':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => File['/etc/nginx'],
    }

    file { '/etc/nginx/sites-available':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/etc/nginx'],
    }

    file { '/etc/nginx/sites-enabled':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/etc/nginx'],
    }

    file { '/etc/nginx/nginx.conf':
        notify  => Service["nginx"],
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => epp("services/nginx/nginx.conf.epp"),
        require => File['/etc/nginx'],
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
        require => File['/etc/nginx/snippets']
    }

    info("[conf.d]: GZip")
    file { '/etc/nginx/conf.d/01-gzip.conf':
        ensure  => file,
        content => template('services/nginx/conf.d/gzip.conf.erb'),
        notify  => Service["nginx"],
        owner   => 'root',
        group   => 'root',
        require => File['/etc/nginx/conf.d']
    }

    info("[conf.d]: performance")
    file { '/etc/nginx/conf.d/01-perf.conf':
        ensure  => file,
        content => template('services/nginx/conf.d/perf.conf.erb'),
        notify  => Service["nginx"],
        owner   => 'root',
        group   => 'root',
        require => File['/etc/nginx/conf.d']
    }
}
