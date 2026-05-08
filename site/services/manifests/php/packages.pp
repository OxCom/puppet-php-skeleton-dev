class services::php::packages (
    Array $versions = $services::php::params::versions,
    Array $packages = $services::php::params::packages,
    Hash  $exclude_packages = $services::php::params::exclude_packages
) inherits services::php::params {
    info("Initialize")

    require services::php::ppa
    package { $versions:
        ensure  => present,
        require => Class['services::php::ppa']
    }

    $versions.each |Integer $index, String $version| {
        info("STEP #${index}: Initialize PHP: ${version}")

        # Global packages that will be installed for each version
        ['cli', 'fpm', 'common', 'dev'].each |Integer $index, String $postfix| {
            if defined(Package["$version-$postfix"]) {
                next()
            }

            package { ["$version-$postfix"]:
                ensure  => present,
                require => Class['services::php::ppa']
            }
        }

        # Packages excluded for this specific version
        $excluded = $exclude_packages[$version] ? {
            undef   => [],
            default => $exclude_packages[$version]
        }

        # List of required packages
        unique($packages).each |Integer $index, String $package| {
            # List of packages has not version prefix and should be installed as 'php-${package}'
            if member($services::php::params::common, $package) {
                if defined(Package["php-$package"]) {
                    next()
                }

                info("Installing package 'php-$package'.")
                package { ["php-$package"]:
                    ensure  => present,
                    require => Class['services::php::ppa']
                }
            } else {
                if member($excluded, $package) {
                    info("Skipping package '$version-$package' (excluded for $version).")
                    next()
                }

                if defined(Package["$version-$package"]) {
                    next()
                }

                info("Installing package '$version-$package'.")
                package { ["$version-$package"]:
                    ensure  => present,
                    require => Class['services::php::ppa']
                }
            }
        }
    }
}
