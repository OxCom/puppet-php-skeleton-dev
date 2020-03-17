class services::nginx::params {
    $projects = lookup('projects', Hash, 'first', {})
    $versions = lookup('php.versions', Array, 'first', ['php7ю4'])
    $domain = $::fqdn
}
