class services::samba (
    String $workgroup = $services::samba::params::workgroup,
    String $allow_guests = $services::samba::params::allow_guests,
) inherits services::samba::params {
    info("Initialize")

    package { ['samba']:
        ensure => present,
    }

    service { 'smbd':
        ensure  => 'running',
        enable  => 'true',
        require => Package['samba'],
    }

    smb_user { 'smbo':                          # * user name
        ensure         => present,              # * absent | present
        password       => 'smbo',               # * user password (default: random)
        force_password => true,                 # * force password value, if false
    }

    $shared = [
        {
            name => 'storage',
            path => '/var/storage',
            writable => 'yes',
        }
    ]

    class { 'services::samba::config':
        workgroup    => $workgroup,
        allow_guests => $allow_guests,
        shared       => $shared
    }
}
