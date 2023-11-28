class services::mysql {
    info("Initialize")

    $password = lookup('db.mariadb.root_password', String, 'first', 'root')
    $remove = lookup('db.mariadb.remove_default_accounts', Boolean, 'first', true)
    $options = lookup('db.mariadb.override_options', Hash, 'first', {})
    $version = lookup('db.mariadb.mariadb_version', String, 'first', '11.3')

    include apt
    apt::source { 'mariadb':
        location => "http://sfo1.mirrors.digitalocean.com/mariadb/repo/$version/ubuntu",
        # release  => 'impish',
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
