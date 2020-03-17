class services::php::composer {
    info("Initialize")

    class { 'composer':
        build_deps => false,
    }
}
