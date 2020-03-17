class services::php::composer {
    info("Initialize")

    # TODO: parameters

    exec { 'composer-install':
        command     => "/usr/bin/wget --no-check-certificate -O ${composer_full_path} ${target}",
        environment => [ "COMPOSER_HOME=${target_dir}" ],
        user        => $user,
        unless      => $unless,
        timeout     => $download_timeout,
        require     => Package['wget'],
    }

    file { "${target_dir}/${command_name}":
        ensure  => file,
        owner   => $user,
        mode    => '0755',
        group   => $group,
        require => Exec['composer-install'],
    }

    $ensure = $auto_update ? { true => present, false => absent }
    cron { 'composer-update':
        ensure  => $ensure,
        command => "COMPOSER_HOME=${target_dir} ${composer_full_path} self-update -q",
        hour    => 0,
        minute  => fqdn_rand(60),
        user    => $user,
        require => File[$composer_full_path],
    }
}
