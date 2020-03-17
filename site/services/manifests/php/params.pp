class services::php::params {
    $versions = lookup('php.versions', Array, 'first', [])
    $packages = lookup('php.packages', Array, 'deep', [])
    $pools = lookup('projects', Hash, 'first', {})
    $composer = lookup('php.composer', Boolean, 'first', false)
}
