class services::php::ppa {
    info("Initialize")

    include apt

    exec { 'apt-update-php':
        command => 'apt-get update',
        path    => '/bin:/usr/bin',
        timeout => 0
    }

    # ondrej/php PPA lags behind new Ubuntu releases; fall back to noble until supported
    $php_ppa_dist = $facts['os']['distro']['codename'] ? {
        'resolute' => 'noble',
        default    => $facts['os']['distro']['codename'],
    }

    apt::ppa { 'ppa:ondrej/php':
        dist   => $php_ppa_dist,
        before => Exec['apt-update-php'],
    }
}
