class services::openssl {
  info("Initialize")

  # https://www.openssl.org/source/
  class { '::openssl':
    package_ensure         => latest,
    ca_certificates_ensure => latest,
  }
}