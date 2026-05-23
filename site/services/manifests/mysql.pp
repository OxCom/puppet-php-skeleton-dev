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

    # --- Root grants for every bind-address host ---
    # ::mysql::server already manages root@localhost and root@127.0.0.1.
    # Parse the bind-address option and create root user + ALL PRIVILEGES for
    # each additional IP so containers / services on those interfaces can connect.
    $bind_address_raw = dig($options, 'mysqld', 'bind-address')
    $all_bind_hosts = $bind_address_raw ? {
        undef   => [],
        default => $bind_address_raw.split(',').map |$h| { strip($h) },
    }
    # Deduplicate and skip hosts that ::mysql::server already handles
    $default_hosts = ['127.0.0.1', 'localhost', '::1']
    $extra_hosts   = unique($all_bind_hosts).filter |$h| { !($h in $default_hosts) }

    $extra_hosts.each |$host| {
        mysql_user { "root@${host}":
            ensure        => present,
            password_hash => mysql_password($password),
            require       => Class['::mysql::server'],
        }
        -> mysql_grant { "root@${host}/*.*":
            ensure     => present,
            options    => ['GRANT'],
            privileges => ['ALL'],
            table      => '*.*',
            user       => "root@${host}",
        }
    }
}
