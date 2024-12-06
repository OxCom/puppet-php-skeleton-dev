class services::npm {
    info("Initialize")

    class { 'nodejs':
      repo_url_suffix => '22.x',
    }
    
    class { 'yarn': }

    Package['nodejs'] -> Package['yarn']
}
