class services::php::params {
    $versions = lookup('php.versions', Array, 'first', [])
    $packages = lookup('php.packages', Array, 'deep', [])
    $pools = lookup('php.pools', Hash, 'first', {})
    $composer = lookup('php.composer', Boolean, 'first', false)

    # List of packages without version prefix
    $common = ['codesniffer', 'codecoverage', 'xdebug']
}
