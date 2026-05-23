class services::nginx::package {
    info("Initialize")

    require services::nginx::ppa

    # Drop apache and free 80 port
    package { 'apache2':
        ensure => 'purged',
    }

    package { 'nginx':
        ensure  => present,
        require => [
            Package['apache2'],
            Class['services::nginx::ppa']
        ]
    }

    # Required for the stream {} block in nginx.conf.
    # nginx.org packages ship this as a separate dynamic module.
    package { 'nginx-module-stream':
        ensure  => present,
        require => Package['nginx'],
        notify  => Service['nginx'],
    }

    # nginx.org packages don't create modules-enabled; create it explicitly
    file { '/etc/nginx/modules-enabled':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['nginx'],
    }

    # Activate the stream dynamic module via the include already in nginx.conf
    file { '/etc/nginx/modules-enabled/50-mod-stream.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => "load_module modules/ngx_stream_module.so;\n",
        require => [
            Package['nginx-module-stream'],
            File['/etc/nginx/modules-enabled'],
        ],
        notify  => Service['nginx'],
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

    file { '/etc/nginx/snippets':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['nginx']
    }

    file { '/etc/nginx/conf.d':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['nginx']
    }

    file { "/etc/nginx/ssl":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['nginx']
    }

    file { "/etc/nginx/nginx.conf":
        notify  => Service["nginx"],
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => epp("services/nginx/nginx.conf.epp"),
        require => Package['nginx']
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
