class profile::webapp {
  include services::docker::params
  include services::docker

  include services::npm

  include services::php::params
  include services::php

  # include services::nginx::params

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

  # Class['services::php'] -> Class['services::nginx']
}
