class services::npm {
    info("Initialize")

    class { 'nodejs':
      repo_url_suffix => '23.x',
    }
    
    class { 'yarn': }

    Package['nodejs'] -> Package['yarn']
}
