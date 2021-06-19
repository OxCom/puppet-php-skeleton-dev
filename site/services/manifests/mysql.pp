class services::mysql {
    info("Initialize")

    $password = lookup('db.mariadb.root_password', String, 'first', 'root')
    $remove = lookup('db.mariadb.remove_default_accounts', Boolean, 'first', true)
    $options = lookup('db.mariadb.override_options', Hash, 'first', {})

    include apt
    apt::source { 'mariadb':
        location => 'http://ams2.mirrors.digitalocean.com/mariadb/repo/10.5/ubuntu',
        release  => $::lsbdistcodename,
        repos    => 'main',
        architecture => 'amd64',
        key      => {
            id     => '177F4010FE56CA3336300305F1656F24C74CD1D8',
            server => 'hkp://keyserver.ubuntu.com:80',
        },
        include  => {
            src => false,
            deb => true,
        }
    }

    class { '::mysql::server':
        package_name            => 'mariadb-server',
        root_password           => $password,
        remove_default_accounts => $remove,
        override_options        => $options
    }

    Apt::Source['mariadb'] ~> Class['apt::update'] -> Class['::mysql::server']
}
