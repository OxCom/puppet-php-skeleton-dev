class services::wezterm::package {
  info("Initialize")

  require services::wezterm::ppa

  package { 'wezterm':
    ensure  => present,
    require => Class['services::wezterm::ppa'],
  }
}
