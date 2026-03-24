class services::wezterm::ppa {
  info("Initialize")

  include apt

  if !defined(Package['curl']) {
    package { 'curl':
      ensure => present,
    }
  }

  if !defined(Package['gnupg']) {
    package { 'gnupg':
      ensure => present,
    }
  }

  exec { 'wezterm-add-key':
    command => 'curl -fsSL https://apt.fury.io/wez/gpg.key | gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg',
    path    => '/bin:/usr/bin',
    creates => '/usr/share/keyrings/wezterm-fury.gpg',
    require => [
      Package['curl'],
      Package['gnupg'],
    ],
  }

  file { '/usr/share/keyrings/wezterm-fury.gpg':
    ensure  => file,
    mode    => '0644',
    require => Exec['wezterm-add-key'],
  }

  file { '/etc/apt/sources.list.d/wezterm.list':
    ensure  => file,
    mode    => '0644',
    content => "deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *\n",
    require => File['/usr/share/keyrings/wezterm-fury.gpg'],
  }

  exec { 'apt-update-wezterm':
    command => 'apt-get update',
    path    => '/bin:/usr/bin',
    timeout => 0,
    require => File['/etc/apt/sources.list.d/wezterm.list'],
  }
}
