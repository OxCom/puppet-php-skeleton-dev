class services::nginx::ppa {
  info("Initialize")

  include apt

  exec { 'apt-update-nginx':
    command => 'apt-get update',
    path    => '/bin:/usr/bin',
    timeout => 0
  }

  apt::ppa { 'ppa:ondrej/nginx-mainline':
    before => Exec['apt-update-nginx']
  }
}