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

    file { '/etc/samba/smb.conf':
        ensure  => file,
        content => template('services/samba/smb.conf.erb'),
        notify  => Service['samba'],
        require => [
            Package['samba']
        ]
    }
}
