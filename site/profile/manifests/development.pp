class profile::development {
  # include services::php::params
  # include services::nginx::params
  #
  # $versions = lookup('php.versions', Array, 'first', ['php7.0'])
  # $packages = lookup('php.packages', Array, 'deep', ['php7.0'])
  # $projects = lookup('projects', Hash, 'first', {})
  # $composer = lookup('composer', Boolean, 'first', true)
  # $domain   = lookup('nginx.domain', String, 'first', $::domain)
  #
  # class { 'services::php':
  #   versions => $versions,
  #   packages => $packages,
  #   pools    => $projects,
  #   composer => $composer,
  # }
  #
  # class { 'services::nginx':
  #   versions => $versions,
  #   projects => $projects,
  #   domain   => $domain
  # }
  #
  # Class['services::php']
  #   -> Class['services::nginx']
  #
  # include services::npm
  # include services::docker
}
