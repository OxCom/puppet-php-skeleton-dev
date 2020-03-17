class services::nginx (
    Array $versions = $services::nginx::params::versions,
    Hash $projects  = $services::nginx::params::projects,
    String $domain  = $services::nginx::params::domain
) inherits services::nginx::params {
    info("Initialize")

    require services::nginx::package

    class { 'services::nginx::php_fpm':
        versions => $versions,
        projects => $projects
    }

    class { 'services::nginx::www':
        versions => $versions,
        projects => $projects,
        domain   => $domain,
    }
}
