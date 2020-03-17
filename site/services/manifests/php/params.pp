class services::php::params {
  # $domain   = lookup('nginx.domain', String, 'first', $::domain)

  $versions = lookup('php.versions', Array, 'first', [])
  $packages = lookup('php.packages', Array, 'deep', [])
  $pools    = {}
  $composer = lookup('composer', Boolean, 'first', false)

  # List of packages without version prefix
  $common   = ['codesniffer', 'codecoverage', 'xdebug']
}
