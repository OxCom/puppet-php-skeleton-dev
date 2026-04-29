class services::wezterm::package {
  info("Initialize")

  require services::wezterm::ppa

  package { 'wezterm':
    ensure => absent,
  }

  package { 'wezterm-nightly':
    ensure  => present,
    require => [
      Class['services::wezterm::ppa'],
      Package['wezterm'],
    ],
  }

  exec { 'wezterm-fc-cache':
    command => 'fc-cache -fv',
    path    => '/bin:/usr/bin',
    timeout => 0,
    require => Package['wezterm-nightly'],
  }
}
