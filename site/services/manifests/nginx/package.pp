class services::nginx::package {
  info("Initialize")

  # add PPA for php
  require services::nginx::ppa

  # drop apache and free 80 port
  package { 'apache2':
    ensure => 'purged',
  }

  package { 'nginx-full':
    ensure  => present,
    require => [
      Package['apache2'],
      Class['services::nginx::ppa']
    ]
  }

  service { "nginx":
    ensure  => "running",
    enable  => "true",
    require => Package["nginx-full"],
  }
}