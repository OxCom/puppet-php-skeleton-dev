class services::docker (
    String $version = $services::docker::params::version,
    Array $users    = $services::docker::params::users
) inherits services::php::params {
    info("Initialize")

    # docker repo lags behind new Ubuntu releases; fall back to noble until supported
    $docker_release = $facts['os']['distro']['codename'] ? {
        'resolute' => 'noble',
        default    => $facts['os']['distro']['codename'],
    }

    # Clean up stale docker.sources left by distro upgrade tooling
    file { '/etc/apt/sources.list.d/docker.sources':
        ensure => absent,
        before => Class['::docker'],
    }

    # --- Corporate CA workaround ---
    # puppetlabs/docker uses apt::keyring { source => 'https://download.docker.com/...' }
    # internally.  Puppet's file provider always re-checks the HTTPS source for metadata
    # even when the file already exists, so the corporate MITM proxy breaks it.
    # Fix: download the key with system wget (which honours the OS CA bundle already
    # containing Crytek-CA-SelfSigned) to a local temp file, then use a resource collector
    # to redirect the inner File resource's source away from the HTTPS URL.
    exec { 'apt-keyring-docker':
        command => '/usr/bin/wget -q "https://download.docker.com/linux/ubuntu/gpg" -O /tmp/puppet-docker.asc',
        creates => '/tmp/puppet-docker.asc',
    }

    # Intercept the File resource that apt::keyring[docker.asc] creates inside the
    # docker module and point its source at the locally downloaded copy.
    File <| title == '/usr/share/keyrings/docker.asc' |> {
        source  => '/tmp/puppet-docker.asc',
        require => Exec['apt-keyring-docker'],
    }

    class { '::docker':
        version                    => $version,
        docker_users               => $users,
        ensure                     => present,
        service_overrides_template => false,
        docker_ce_release          => $docker_release,
    }

    class { 'docker::compose':
        ensure => present
    }
}
