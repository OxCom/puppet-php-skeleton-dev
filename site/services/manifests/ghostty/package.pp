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

  $ghostty_keybinding_path    = '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ghostty/'
  $ghostty_custom_keybindings = "['${ghostty_keybinding_path}']"
  $ghostty_media_keys_schema  = 'org.gnome.settings-daemon.plugins.media-keys'
  $ghostty_binding_schema     = "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${ghostty_keybinding_path}"
  $gsettings_available_check  = '/bin/bash -o pipefail -c "command -v gsettings >/dev/null 2>&1"'

  if $facts['user_home_accounts'].is_a(Array) and !empty($facts['user_home_accounts']) {
    $facts['user_home_accounts'].each |Hash $account| {
      $desktop_user = $account['user']

      exec { "set-ghostty-media-keybinding-${desktop_user}":
        command => "/bin/bash -o pipefail -c \"runuser -u ${desktop_user} -- dbus-run-session -- gsettings set ${ghostty_media_keys_schema} terminal '@as []' && runuser -u ${desktop_user} -- dbus-run-session -- gsettings reset ${ghostty_media_keys_schema} custom-keybindings && runuser -u ${desktop_user} -- dbus-run-session -- gsettings set ${ghostty_media_keys_schema} custom-keybindings \\\"${ghostty_custom_keybindings}\\\" && runuser -u ${desktop_user} -- dbus-run-session -- gsettings set ${ghostty_binding_schema} name 'Ghostty' && runuser -u ${desktop_user} -- dbus-run-session -- gsettings set ${ghostty_binding_schema} command '/snap/bin/ghostty' && runuser -u ${desktop_user} -- dbus-run-session -- gsettings set ${ghostty_binding_schema} binding '<Control><Alt>t'\"",
        unless  => "/bin/bash -o pipefail -c \"runuser -u ${desktop_user} -- dbus-run-session -- gsettings get ${ghostty_media_keys_schema} terminal | grep -Fx '@as []' >/dev/null && runuser -u ${desktop_user} -- dbus-run-session -- gsettings get ${ghostty_media_keys_schema} custom-keybindings | grep -Fx \\\"${ghostty_custom_keybindings}\\\" >/dev/null && runuser -u ${desktop_user} -- dbus-run-session -- gsettings get ${ghostty_binding_schema} name | grep -Fx \\\"'Ghostty'\\\" >/dev/null && runuser -u ${desktop_user} -- dbus-run-session -- gsettings get ${ghostty_binding_schema} command | grep -Fx \\\"'/snap/bin/ghostty'\\\" >/dev/null && runuser -u ${desktop_user} -- dbus-run-session -- gsettings get ${ghostty_binding_schema} binding | grep -Fx \\\"'<Control><Alt>t'\\\" >/dev/null\"",
        onlyif  => $gsettings_available_check,
        path    => '/bin:/usr/bin',
        require => Exec['set-default-terminal-ghostty'],
      }
    }
  }
}
