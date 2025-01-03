class services::npm {
    info("Initialize")

    class { 'nodejs':
      repo_version => '20',
    }
    
    class { 'yarn': }

    Package['nodejs'] -> Package['yarn']
}
