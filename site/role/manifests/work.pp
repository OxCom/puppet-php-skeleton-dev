class role::work inherits role::default {
  include profile::redis
  include profile::database
  # include profile::dns
  # include profile::memcached
  # include profile::development
}
