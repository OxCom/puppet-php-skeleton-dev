class services::php::ppa {
    info("Initialize")

    include apt

    exec { 'apt-update-php':
        command => 'apt-get update',
        path    => '/bin:/usr/bin',
        timeout => 0
    }

    # ppa:ondrej/php is frozen ("PPA for PHP (deprecated)"); packages moved to
    # packages.sury.org/php, which publishes native builds for jammy, noble and resolute.
    $php_repo_dist = $facts['os']['distro']['codename']

    # Remove the frozen Launchpad PPA: stale add-apt-repository files and the old apt::source
    ['resolute', 'noble'].each |String $dist| {
        file { "/etc/apt/sources.list.d/ondrej-ubuntu-php-${dist}.list":
            ensure => absent,
            before => Exec['apt-update-php'],
        }
        file { "/etc/apt/sources.list.d/ondrej-ubuntu-php-${dist}.sources":
            ensure => absent,
            before => Exec['apt-update-php'],
        }
    }

    apt::source { 'ondrej-php':
        ensure => absent,
        before => Exec['apt-update-php'],
    }

    file { '/etc/apt/keyrings/ondrej-php.asc':
        ensure => absent,
    }

    # Use wget (system tool / OS CA bundle) instead of Puppet's file provider so the
    # corporate self-signed proxy CA is trusted without needing to rebuild Puppet's CA store.
    # The keyring package installs /usr/share/keyrings/debsuryorg-archive-keyring.gpg.
    exec { 'apt-keyring-sury-php':
        # Download to root-owned /var/cache, not /tmp: with fs.protected_regular=2 root
        # cannot overwrite a file another user left in sticky /tmp, and wget fails.
        command  => '/usr/bin/wget -q https://packages.sury.org/debsuryorg-archive-keyring.deb -O /var/cache/debsuryorg-archive-keyring.deb && DEBIAN_FRONTEND=noninteractive /usr/bin/dpkg -i /var/cache/debsuryorg-archive-keyring.deb',
        provider => shell,
        path     => '/bin:/usr/bin:/sbin:/usr/sbin',
        creates  => '/usr/share/keyrings/debsuryorg-archive-keyring.gpg',
        require  => Class['apt'],
    }

    apt::source { 'sury-php':
        location     => 'https://packages.sury.org/php/',
        release      => $php_repo_dist,
        repos        => 'main',
        architecture => 'amd64',
        keyring      => '/usr/share/keyrings/debsuryorg-archive-keyring.gpg',
        before       => Exec['apt-update-php'],
        require      => Exec['apt-keyring-sury-php'],
    }
}
