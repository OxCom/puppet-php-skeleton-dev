class services::npm {
    info("Initialize")

    class { 'nodejs': }

    # class { '::nodejs':
    #     npm_package_ensure => 'present',
    # }
}
