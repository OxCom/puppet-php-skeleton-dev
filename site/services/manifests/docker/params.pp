class services::docker::params {
    $version = lookup('docker.version', String, 'first', 'latest')
    $users = lookup('docker.users', Array, 'deep', [])
}
