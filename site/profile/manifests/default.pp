class profile::default {
    include apt
    include ntp

    # the base profile should include component modules that will be on all nodes
    $tools = lookup('tools', Array, 'deep', []);
    $tools.each |Integer $index, String $tool| {

        package { $tool:
            ensure => present
        }

        if ($tool == 'imagemagick') {
            info("Fix: slow webp convert in Imagick and Webp.")
            tidy { 'webp-fix':
                path    => '/usr/lib/',
                recurse => true,
                age => 0,
                matches => ['webp.so', 'webp.la'],
                require => Package[$tool]
            }
        }
    }

    include services::openssl


}
