class profile::webapp {
  # include services::docker::params
  # include services::php::params
  # include services::nginx::params

  class { 'services::docker':
      version  => lookup('docker.version', String, 'first', 'latest'),
      users => lookup('docker.users', Array, 'deep', []),
  }

  # $versions = lookup('php.versions', Array, 'first', ['php7.0'])
  # $packages = lookup('php.packages', Array, 'deep', ['php7.0'])
  # $projects = lookup('projects', Hash, 'first', {})
  # $composer = lookup('composer', Boolean, 'first', true)
  # $domain   = lookup('nginx.domain', String, 'first', $::domain)
  #
  # class { 'services::nginx':
  #   versions => $versions,
  #   projects => $projects,
  #   domain   => $domain
  # }
  #
  # Class['services::php'] -> Class['services::nginx']

  # include services::npm
  # include services::docker
}
