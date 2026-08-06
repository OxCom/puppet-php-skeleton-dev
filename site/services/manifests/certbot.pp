class services::certbot {
    info("Initialize certbot")

    # Use Snap-installed Certbot (official recommended distribution) to get
    # the latest releases. The snapd service is already included globally via the
    # default profile. We install certbot as a classic snap and create a convenient
    # /usr/bin/certbot symlink. We also refresh all snaps to ensure we're running
    # the latest version (e.g., 5.6.0 or later).

    require services::snapd

    exec { 'install-certbot-snap':
      command => '/usr/bin/snap install --classic certbot',
      path    => ['/usr/bin','/bin','/usr/sbin','/sbin'],
      unless  => '/usr/bin/snap list certbot >/dev/null 2>&1',
      require => Exec['ensure-snap-core'],
    }

    # Refresh all snaps to ensure we're on the latest certbot version.
    # This is essential because snap caches older releases; refresh pulls
    # the latest from the store (e.g., 5.6.0 instead of 2.9.0).
    exec { 'refresh-certbot-snap':
      command => '/usr/bin/snap refresh certbot',
      path    => ['/usr/bin','/bin','/usr/sbin','/sbin'],
      require => Exec['install-certbot-snap'],
    }

    exec { 'verify-certbot-version':
      command => '/bin/bash -c "/usr/bin/certbot --version | grep -E \"(5\.[6-9]|[6-9]\.[0-9])\" || (/usr/bin/certbot --version && exit 1)"',
      path    => ['/usr/bin','/bin','/usr/sbin','/sbin'],
      require => Exec['refresh-certbot-snap'],
    }

    # Create a symlink so scripts/cronjobs referencing /usr/bin/certbot still work
    exec { 'ensure-certbot-symlink':
      command => '/bin/ln -sf /snap/bin/certbot /usr/bin/certbot',
      path    => ['/usr/bin','/bin','/usr/sbin','/sbin'],
      unless  => 'test -x /usr/bin/certbot || [ -L /usr/bin/certbot ]',
      require => Exec['refresh-certbot-snap'],
    }

    # Note: nginx plugin is provided by the certbot snap. If you need DNS plugins
    # (route53, cloudflare, etc.) install the relevant snap plugins such as
    # certbot-dns-route53.
}

