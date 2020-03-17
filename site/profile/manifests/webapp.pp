class profile::webapp {
  include services::docker::params
  include services::docker

  include services::npm

  include services::php::params
  include services::php

  include services::nginx::params
  include services::nginx

  Class['services::php'] -> Class['services::nginx']
}
