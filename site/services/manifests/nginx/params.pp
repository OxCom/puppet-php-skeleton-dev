class services::nginx::params {
    $projects = lookup('projects', Hash, 'first', {})
    $versions = lookup('php.versions', Array, 'first', ['php8.3'])
    $domain = $::fqdn
}
