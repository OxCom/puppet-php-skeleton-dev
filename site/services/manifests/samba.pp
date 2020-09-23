class services::samba (
    String $versions = $services::samba::workgroup,
) inherits services::samba::params {
    info("Initialize")

    package { ['samba']:
        ensure => present,
    }
}
