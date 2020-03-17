class services::docker (
    String $version = $services::docker::params::version,
    Array $users    = $services::docker::params::users
) inherits services::php::params {
    info("Initialize")

    class { '::docker':
        version                    => $version,
        docker_users               => $users,
        ensure                     => present,
        service_overrides_template => false
    }

    class { 'docker::compose':
        ensure => present
    }
}
