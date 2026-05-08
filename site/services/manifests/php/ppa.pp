class services::php::ppa {
    info("Initialize")

    include apt

    exec { 'apt-update-php':
        command => 'apt-get update',
        path    => '/bin:/usr/bin',
        timeout => 0
    }

    # ondrej/php PPA lags behind new Ubuntu releases; fall back to noble until supported.
    # Uses apt::source instead of apt::ppa — add-apt-repository always uses the system
    # codename from /etc/os-release and ignores any dist override passed by Puppet.
    $php_ppa_dist = $facts['os']['distro']['codename'] ? {
        'resolute' => 'noble',
        default    => $facts['os']['distro']['codename'],
    }

    # Clean up stale files left by add-apt-repository from previous apt::ppa runs
    ['resolute', 'noble'].each |String $dist| {
        file { "/etc/apt/sources.list.d/ondrej-ubuntu-php-${dist}.list":
            ensure => absent,
            before => Apt::Source['ondrej-php'],
        }
        file { "/etc/apt/sources.list.d/ondrej-ubuntu-php-${dist}.sources":
            ensure => absent,
            before => Apt::Source['ondrej-php'],
        }
    }

    apt::keyring { 'ondrej-php.asc':
        source => 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x71DAEAAB4AD4CAB6',
    }

    apt::source { 'ondrej-php':
        location     => 'https://ppa.launchpadcontent.net/ondrej/php/ubuntu',
        release      => $php_ppa_dist,
        repos        => 'main',
        architecture => 'amd64',
        keyring      => '/etc/apt/keyrings/ondrej-php.asc',
        before       => Exec['apt-update-php'],
        require      => Apt::Keyring['ondrej-php.asc'],
    }
}
