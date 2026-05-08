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

  apt::keyring { 'nginx.asc':
    source => 'https://nginx.org/keys/nginx_signing.key',
  }

  apt::source { 'nginx':
    location     => 'https://nginx.org/packages/ubuntu',
    release      => $nginx_release,
    repos        => 'nginx',
    architecture => 'amd64',
    keyring      => '/etc/apt/keyrings/nginx.asc',
    before       => Exec['apt-update-nginx'],
    require      => Apt::Keyring['nginx.asc'],
  }
}
