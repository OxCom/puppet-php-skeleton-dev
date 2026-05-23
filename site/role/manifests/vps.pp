class role::work inherits role::default {
  include profile::database
  include profile::webapp
}
