class services::samba::config (
    String $workgroup,
    String $allow_guests,
    Array $shared
) inherits services::samba::params {
    file { '/var/storage':
        ensure  => 'directory',
        owner   => 'smbo',
        group   => 'smbo',
        mode    => '0777',
        recurse => true,
        require => [
            Package['samba']
        ]
    }

    user { 'smbo':
        ensure => present,
        comment => 'samba user',
        home => '/home/smbo',
        managehome => true,
        require => [
            Package['samba'],
            File['/var/storage']
        ]
    }

    exec { 'yes smbo|head -n 2| sudo smbpasswd -a -s smbo':
        user    => 'root',
        path    => ['/usr/bin', '/usr/sbin', '/bin'],
        notify  => Service['smbd'],
        require => [
            User['smbo']
        ],
    }

    file { '/etc/samba/smb.conf':
        ensure  => file,
        content => template('services/samba/smb.conf.erb'),
        notify  => Service['smbd'],
        require => [
            Package['samba'],
            File['/var/storage']
        ]
    }
}
