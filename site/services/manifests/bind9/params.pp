class services::bind9::params {
  if $::osfamily != 'Debian' {
    fail('This module only works on Debian or derivatives like Ubuntu')
  }

  $zone = $::domain
  $dns = []
}
