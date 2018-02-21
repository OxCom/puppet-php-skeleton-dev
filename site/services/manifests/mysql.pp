class services::mysql {
  info("Initialize")

  $password = lookup('db.mysql.root_password', String, 'first', 'root')
  $remove = lookup('db.mysql.remove_default_accounts', Boolean, 'first', true)
  $options = lookup('db.mysql.override_options', Hash, 'first', {})

  # https://github.com/puppetlabs/puppetlabs-mysql
  class { '::mysql::server':
    root_password           => $password,
    remove_default_accounts => $remove,
    override_options        => $options
  }
}