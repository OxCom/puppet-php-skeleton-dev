class role::all inherits role::default {
  include profile::redis
  # include profile::dns
  # include profile::memcached
  # include profile::database
  # include profile::development
}
