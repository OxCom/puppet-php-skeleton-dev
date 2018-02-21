class services::bind9::package {
  info("Initialize")

  package { 'bind9':
    ensure  => present
  }

  service { "bind9":
    ensure  => "running",
    enable  => "true",
    require => Package["bind9"],
  }
}