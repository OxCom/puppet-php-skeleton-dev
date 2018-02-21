class services::php::ppa {
  info("Initialize")

  include apt

  exec { 'apt-update-php':
    command => 'apt-get update',
    path    => '/bin:/usr/bin',
    timeout => 0
  }

  apt::ppa { 'ppa:ondrej/php':
    before => Exec['apt-update-php']
  }
}