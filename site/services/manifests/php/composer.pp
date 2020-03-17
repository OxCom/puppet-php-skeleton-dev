class services::php::composer {
    info("Initialize")

    # $web_path = 'https://getcomposer.org/download/${version}/composer.phar'
    # $install_path = '/usr/local/bin'
    # $composer_path = "$install_path/composer"
    # $owner = 'root'
    #
    # # TODO: parameters
    # exec { 'composer-install':
    #     command     => "/usr/bin/wget --no-check-certificate -O $composer_path $web_path",
    #     environment => [ "COMPOSER_HOME=$install_path" ],
    #     user        => $owner,
    #     unless      => "/usr/bin/test -f ${composer_full_path} && ${composer_full_path} -V |grep -q ${version}",
    #     timeout     => $download_timeout,
    #     require     => Package['wget'],
    # }
    #
    # file { "${target_dir}/${command_name}":
    #     ensure  => file,
    #     owner   => $user,
    #     mode    => '0755',
    #     group   => $group,
    #     require => Exec['composer-install'],
    # }
    #
    # $ensure = $auto_update ? { true => present, false => absent }
    # cron { 'composer-update':
    #     ensure  => $ensure,
    #     command => "COMPOSER_HOME=${target_dir} ${composer_full_path} self-update -q",
    #     hour    => 0,
    #     minute  => fqdn_rand(60),
    #     user    => $user,
    #     require => File[$composer_full_path],
    # }
}
