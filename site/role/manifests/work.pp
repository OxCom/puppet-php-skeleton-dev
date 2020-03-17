class role::work inherits role::default {
  include profile::redis
  include profile::database
  include profile::webapp
}
