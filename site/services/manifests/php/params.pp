class services::php::params {
  if $::osfamily != 'Debian' {
    fail('This module only works on Debian or derivatives like Ubuntu')
  }

  # https://puppet.com/docs/puppet/4.10/hiera_use_function.html
  $versions = []
  $packages = []
  $pools    = {}
  $composer = false

  # this is a list of packages without version prefix
  $common   = ['codesniffer', 'codecoverage', 'xdebug']
}
