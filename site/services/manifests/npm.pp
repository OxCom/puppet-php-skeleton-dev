class services::npm {
    info("Initialize")

    class { 'nodejs': }
    class { 'yarn': }

    Package['nodejs'] -> Package['yarn']
}
