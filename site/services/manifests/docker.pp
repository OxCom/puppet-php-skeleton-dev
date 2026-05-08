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
