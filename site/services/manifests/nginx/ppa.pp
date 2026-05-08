class services::nginx::ppa {
  info("Initialize")

  include apt

  exec { 'apt-update-nginx':
    command => 'apt-get update',
    path    => '/bin:/usr/bin',
    timeout => 0
  }

  # nginx repo lags behind new Ubuntu releases; fall back to noble until supported
  $nginx_release = $facts['os']['distro']['codename'] ? {
    'resolute' => 'noble',
    default    => $facts['os']['distro']['codename'],
  }

  apt::source { 'nginx':
    location => 'https://nginx.org/packages/ubuntu',
    release  => $nginx_release,
    repos    => 'nginx',
    key      => {
      id     => '8540A6F18833A80E9C1653A42FD21310B49F6B46',
      source => 'https://nginx.org/keys/nginx_signing.key',
    },
    before   => Exec['apt-update-nginx'],
  }
}
