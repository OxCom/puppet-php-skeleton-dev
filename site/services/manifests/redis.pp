class services::redis {
  info("Initialize")

  package {['redis-server', 'redis-tools']:
    ensure => present,
  }
}