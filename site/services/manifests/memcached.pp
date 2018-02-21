class services::memcached {
  info("Initialize")

  package {['memcached']:
    ensure => present,
  }
}