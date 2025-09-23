class services::npm {
    info("Initialize")

    class { 'nodejs':
      repo_version => '22',
    }
}
