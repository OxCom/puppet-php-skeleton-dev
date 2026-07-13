class services::nginx::params {
    $projects = lookup('projects', Hash, 'first', {})
    $versions = lookup('php.versions', Array, 'first', ['php8.3'])
    $domain   = $facts['networking']['fqdn']
    $certbot  = lookup('certbot', Boolean, 'first', false)
}
