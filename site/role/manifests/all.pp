class role::all inherits role::default {
  # include profile::dns
  # include profile::memcached
  # include profile::redis
  # include profile::database
  # include profile::development
}
