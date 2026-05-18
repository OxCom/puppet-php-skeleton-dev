class services::mysql {
    info("Initialize")

    $password = lookup('db.mariadb.root_password', String, 'first', 'root')
    $remove = lookup('db.mariadb.remove_default_accounts', Boolean, 'first', true)
    $options = lookup('db.mariadb.override_options', Hash, 'first', {})
    $version = lookup('db.mariadb.mariadb_version', String, 'first', '11.4')

    include apt

    # MariaDB repo may lag behind new Ubuntu releases; fall back to noble until supported
    $mariadb_release = $facts['os']['distro']['codename'] ? {
        'resolute' => 'noble',
        default    => $facts['os']['distro']['codename'],
    }

    # Use wget (system tool / OS CA bundle) instead of Puppet's file provider so the
    # corporate self-signed proxy CA is trusted without needing to rebuild Puppet's CA store.
    exec { 'apt-keyring-mariadb':
        command => '/usr/bin/wget -q "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x177F4010FE56CA3336300305F1656F24C74CD1D8" -O /etc/apt/keyrings/mariadb.asc',
        creates => '/etc/apt/keyrings/mariadb.asc',
        require => Class['apt'],
    }

    apt::source { 'mariadb':
        location     => "https://mirror.mariadb.org/repo/$version/ubuntu",
        release      => $mariadb_release,
        repos        => 'main',
        architecture => 'amd64',
        keyring      => '/etc/apt/keyrings/mariadb.asc',
        include      => {
            src => false,
            deb => true,
        },
        require      => Exec['apt-keyring-mariadb'],
    }

    class { '::mysql::server':
        package_name            => 'mariadb-server',
        root_password           => $password,
        remove_default_accounts => $remove,
        override_options        => $options
    }

    Apt::Source['mariadb']
        ~> Class['apt::update']
        -> Class['::mysql::server']
        -> file { '/etc/mysql/mariadb.conf.d/50-server.cnf':
            ensure => present,
        }
        -> file_line { 'Expose mariadb on all interfaces':
            path => '/etc/mysql/mariadb.conf.d/50-server.cnf',
            line => '# bind-address            = 127.0.0.1',
            match   => "^bind-address.*$",
        }
}
