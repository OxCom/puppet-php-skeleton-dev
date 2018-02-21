class services::php::packages (
  Array $versions   = $services::php::params::versions,
  Array $packages   = $services::php::params::packages
) inherits services::php::params {
  info("Initialize")

  # add PPA for php
  require services::php::ppa

  # install default list of PHP modules
  package { $versions:
    ensure  => present,
    require => Class['services::php::ppa']
  }

  $versions.each |Integer $index, String $version| {
    info("STEP #${index}: Initialize PHP: ${version}")

    # global packages that will be installed for each version
    ['cli', 'fpm', 'common', 'dev'].each |Integer $index, String $postfix| {
      if defined(Package["$version-$postfix"]) {
        next()
      }

      package { ["$version-$postfix"]:
        ensure  => present,
        require => Class['services::php::ppa']
      }
    }

    # list of required packages
    unique($packages).each |Integer $index, String $package| {
      # Some packages are not in ppa:ondrej/php so we have to include them as 'php-${package}'
      # TODO: In a better way we can to:
      # 1) introduce our own PPA with list of deb packages
      # 2) write puppet / ruby script to build PHP extensions for different versions
      if member($services::php::params::common, $package) {
        if defined(Package["php-$package"]) {
          next()
        }

        info("Tried to install package '$package' that should have 'php' prefix.")
        package { ["php-$package"]:
          ensure  => present,
          require => Class['services::php::ppa']
        }
      } else {
        if defined(Package["php-$package"]) {
          next()
        }

        package { ["$version-$package"]:
          ensure  => present,
          require => Class['services::php::ppa']
        }
      }
    }
  }
}