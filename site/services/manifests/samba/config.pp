class services::samba::config (
    String $workgroup,
    String $allow_guests,
    Array $shared
) inherits services::samba::params {
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

    $echo = '/bin/echo';
    $smbpasswd = '/usr/bin/smbpasswd';

    exec { "($echo smbo; echo $echo) | $smbpasswd -s -a smbo":
        notify => Service['smbd'],
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
