class services::npm {
    info("Initialize")

    class { 'nodejs':
      repo_url_suffix => '21.7',
    }
    
    class { 'yarn': }

    Package['nodejs'] -> Package['yarn']
}
