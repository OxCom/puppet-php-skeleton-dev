class services::openssl {
    info("Initialize")

    # https://www.openssl.org/source/
    class { '::openssl':
        package_ensure         => 'present',
        ca_certificates_ensure => 'present',
    }
}
