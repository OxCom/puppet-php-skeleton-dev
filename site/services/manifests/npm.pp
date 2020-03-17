class services::npm {
    info("Initialize")

    class { '::nodejs':
        manage_package_repo       => true,
        nodejs_dev_package_ensure => 'present',
        npm_package_ensure        => 'present',
    }
}
