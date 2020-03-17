class services::php (
    Array $versions   = $services::php::params::versions,
    Array $packages   = $services::php::params::packages,
    Hash $pools       = $services::php::params::pools,
    Boolean $composer = $services::php::params::composer,
) inherits services::php::params {
    info("Initialize")

    require services::php::ppa

    class { 'services::php::packages':
        versions => $versions,
        packages => $packages,
    }

    # class { 'services::php::pool':
    #     versions => $versions,
    #     pools    => $pools,
    # }

    # https://ask.puppet.com/question/2533/about-puppet-class-dependencies/
    Class['services::php::ppa']
        -> Class['services::php::packages']
    #   -> Class['services::php::pool']
    #
    # if $composer {
    #     include services::php::composer
    #
    #     Class['services::php::packages']
    #       -> Class['services::php::composer']
    # }
}
