class services::php::composer {
    info("Initialize")

    # TODO: parameters
    $web_path = 'https://getcomposer.org/composer-stable.phar'
    $install_path = '/usr/local/bin'
    $composer_path = "$install_path/composer"
    $owner = 'root'
    $group = 'root'

    info("Fetch latest stable version")
    exec { 'composer-install':
        command     => "/usr/bin/wget --no-check-certificate -O $composer_path $web_path",
        environment => [ "COMPOSER_HOME=$install_path" ],
        user        => $owner,
        unless      => "/usr/bin/test -f $composer_path && $composer_path -V",
        require     => Package['wget'],
    }

    file { "$composer_path":
        ensure  => file,
        owner   => $owner,
        mode    => '0755',
        group   => $group,
        require => Exec['composer-install'],
    }

    info("Setup cron job for autoupdate")
    cron::job { 'composer-update':
        minute      => '0',
        hour        => '*',
        date        => '*',
        month       => '*',
        weekday     => '*',
        user        => $owner,        
        command     => "COMPOSER_HOME=$install_path $composer_path self-update -q",
        description => 'Composer auto-update',
        require     => File[$composer_path],
    }
}
