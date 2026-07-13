class services::snapd {
  info("Initialize snapd - snap package manager")

  package { 'snapd':
    ensure => present,
  }

  # Ensure core snap is installed (required for snap to function properly)
  exec { 'ensure-snap-core':
    command => '/usr/bin/snap install core',
    path    => ['/usr/bin', '/bin', '/usr/sbin', '/sbin'],
    unless  => '/usr/bin/snap list core >/dev/null 2>&1',
    require => Package['snapd'],
  }
}

