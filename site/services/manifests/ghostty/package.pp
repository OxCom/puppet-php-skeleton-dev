class services::ghostty::package {
  info("Initialize")

  package { 'ghostty':
    ensure => present,
  }

  exec { 'set-default-terminal-ghostty':
    command => '/bin/bash -o pipefail -c "update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/ghostty 70 && update-alternatives --set x-terminal-emulator /usr/bin/ghostty"',
    path    => '/bin:/usr/bin',
    unless  => '/bin/bash -o pipefail -c \'test "$(readlink -f /etc/alternatives/x-terminal-emulator 2>/dev/null || true)" = "/usr/bin/ghostty"\'',
    require => Package['ghostty'],
  }
}
