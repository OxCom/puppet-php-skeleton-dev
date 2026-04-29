class services::ghostty::package {
  info("Initialize")

  package { 'snapd':
    ensure => present,
  }

  exec { 'install-ghostty-snap':
    command => '/usr/bin/snap install ghostty',
    path    => '/bin:/usr/bin:/snap/bin',
    unless  => '/bin/bash -o pipefail -c "snap list ghostty >/dev/null 2>&1"',
    require => Package['snapd'],
  }

  exec { 'set-default-terminal-ghostty':
    command => '/bin/bash -o pipefail -c "update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /snap/bin/ghostty 70 && update-alternatives --set x-terminal-emulator /snap/bin/ghostty"',
    path    => '/bin:/usr/bin',
    unless  => '/bin/bash -o pipefail -c \'test "$(readlink -f /etc/alternatives/x-terminal-emulator 2>/dev/null || true)" = "/snap/bin/ghostty"\'',
    require => Exec['install-ghostty-snap'],
  }
}
