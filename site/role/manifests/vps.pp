class role::vps inherits role::default {
  include profile::database
  include profile::webapp
}
