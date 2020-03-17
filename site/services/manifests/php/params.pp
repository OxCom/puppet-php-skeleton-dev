class services::php::params {
  $versions = lookup('php.versions', Array, 'first', [])
  $packages = lookup('php.packages', Array, 'deep', [])
  $pools    = lookup('php.packages', Hash, 'first', {})
  $composer = lookup('composer', Boolean, 'first', false)

  # List of packages without version prefix
  $common   = ['codesniffer', 'codecoverage', 'xdebug']
}
