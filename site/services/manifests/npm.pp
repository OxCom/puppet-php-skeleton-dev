class services::npm {
    info("Initialize")

    class { 'nodejs':
      repo_url_suffix => '14.x',
    }
    
    class { 'yarn': }

    Package['nodejs'] -> Package['yarn']
}
