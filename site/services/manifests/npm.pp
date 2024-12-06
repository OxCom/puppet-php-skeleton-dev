class services::npm {
    info("Initialize")

    class { 'nodejs':
      repo_version => '23',
    }
    
    class { 'yarn': }

    Package['nodejs'] -> Package['yarn']
}
