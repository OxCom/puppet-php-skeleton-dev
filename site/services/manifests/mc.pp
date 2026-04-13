class services::mc {
  info('Initialize')

  stdlib::ensure_packages(['mc'])

  $home_user_accounts = $facts['user_home_accounts'] ? {
    Undef   => [],
    default => $facts['user_home_accounts'],
  }

  $managed_user_accounts = $home_user_accounts + [{
    'user'  => 'root',
    'group' => 'root',
    'home'  => '/root',
  }]

  $managed_user_accounts.each |Hash $account| {
    $user  = $account['user']
    $group = $account['group']
    $home  = $account['home']

    $local_dir        = "${home}/.local"
    $local_share_dir  = "${home}/.local/share"
    $mc_share_dir     = "${home}/.local/share/mc"
    $mc_skins_dir     = "${home}/.local/share/mc/skins"
    $config_dir       = "${home}/.config"
    $mc_config_dir    = "${home}/.config/mc"
    $mc_ini_file      = "${home}/.config/mc/ini"

    file { [
      $local_dir,
      $local_share_dir,
      $mc_share_dir,
      $mc_skins_dir,
      $config_dir,
      $mc_config_dir,
    ]:
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => '0755',
      require => Package['mc'],
    }

    file { "${mc_skins_dir}/dracula.ini":
      ensure  => file,
      owner   => $user,
      group   => $group,
      mode    => '0644',
      content => epp('services/mc/dracula.ini.epp'),
      require => File[$mc_skins_dir],
    }

    file { $mc_ini_file:
      ensure  => file,
      owner   => $user,
      group   => $group,
      mode    => '0644',
      require => File[$mc_config_dir],
    }

    ini_setting { "mc-skin-${user}":
      ensure  => present,
      path    => $mc_ini_file,
      section => 'Midnight-Commander',
      setting => 'skin',
      value   => 'dracula',
      require => File[$mc_ini_file],
    }
  }
}
