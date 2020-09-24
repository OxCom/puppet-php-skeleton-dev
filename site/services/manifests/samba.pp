class services::samba (
    String $workgroup = $services::samba::workgroup,
    String $allow_guests = $services::samba::allow_guests,
) inherits services::samba::params {
    info("Initialize")

    package { ['samba']:
        ensure => present,
    }

    service { "samba":
        ensure  => 'running',
        enable  => 'true',
        require => Package['samba'],
    }

    $shared = [
        {
            name => 'storage',
            path => '/var/storage',
            writable => 'yes',
        }
    ];

    file { '/etc/samba/smb.conf':
        ensure  => file,
        content => template('services/samba/smb.conf.erb'),
        notify  => Service['samba'],
        require => [
            Package['samba']
        ]
    }
}
