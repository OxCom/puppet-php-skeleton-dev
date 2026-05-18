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

  # Use wget (system tool / OS CA bundle) instead of Puppet's file provider so the
  # corporate self-signed proxy CA is trusted without needing to rebuild Puppet's CA store.
  exec { 'apt-keyring-nginx':
    command => '/usr/bin/wget -q "https://nginx.org/keys/nginx_signing.key" -O /etc/apt/keyrings/nginx.asc',
    creates => '/etc/apt/keyrings/nginx.asc',
    require => Class['apt'],
  }

  apt::source { 'nginx':
    location     => 'https://nginx.org/packages/ubuntu',
    release      => $nginx_release,
    repos        => 'nginx',
    architecture => 'amd64',
    keyring      => '/etc/apt/keyrings/nginx.asc',
    before       => Exec['apt-update-nginx'],
    require      => Exec['apt-keyring-nginx'],
  }
}
