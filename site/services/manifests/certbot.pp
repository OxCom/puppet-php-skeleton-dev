class services::certbot {
    info("Initialize certbot")

    package { 'certbot':
        ensure => present,
    }

    package { 'python3-certbot-nginx':
        ensure  => present,
        require => Package['certbot'],
    }
}

