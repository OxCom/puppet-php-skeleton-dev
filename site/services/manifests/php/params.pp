class services::php::params {
    $versions = lookup('php.versions', Array, 'first', [])
    $packages = lookup('php.packages', Array, 'deep', [])
    $exclude_packages = lookup('php.exclude_packages', Hash, 'first', {})
    $pools = lookup('projects', Hash, 'first', {})
    $composer = lookup('php.composer', Boolean, 'first', false)

    # List of packages without version prefix
    $common = ['codesniffer', 'codecoverage']
}
