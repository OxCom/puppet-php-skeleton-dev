class services::nginx::params {
  if $::osfamily != 'Debian' {
    fail('This module only works on Debian or derivatives like Ubuntu')
  }

  $projects = {}
  $versions = []
  $domain = 'lo'
}
