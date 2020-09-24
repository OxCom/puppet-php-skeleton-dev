class services::samba (
    String $workgroup = $services::samba::params::workgroup,
    String $allow_guests = $services::samba::params::allow_guests,
) inherits services::samba::params {
    info("Initialize")

    package { ['samba']:
        ensure => present,
    }

    service { 'samba':
        ensure  => 'running',
        enable  => 'true',
        require => Package['samba'],
    }

    file { '/var/storage':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        require => [
            Package['samba']
        ]
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
            Package['samba'],
            File['/var/storage']
        ]
    }
}
