class services::nginx::package {
    info("Initialize")

    require services::nginx::ppa

    # Drop apache and free 80 port
    package { 'apache2':
        ensure => 'purged',
    }

    package { 'nginx-full':
        ensure  => present,
        require => [
            Package['apache2'],
            Class['services::nginx::ppa']
        ]
    }

    service { "nginx":
        ensure  => "running",
        enable  => "true",
        require => Package["nginx-full"],
    }

    user { 'vagrant':
        ensure  => present,
        groups  => ['www-data'],
        require => Package["nginx-full"],
    }
}
