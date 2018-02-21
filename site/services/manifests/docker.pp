class services::docker {
  info("Initialize")

  class { 'docker':
    version => 'latest',
    ensure => present,
    service_overrides_template => false
  }

  class {'docker::compose':
    ensure => present
  }
}