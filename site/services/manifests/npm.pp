class services::npm {
    info("Initialize")

    class { 'nodejs':
      repo_version => '21',
    }
    
    class { 'yarn': }

    Package['nodejs'] -> Package['yarn']
}
