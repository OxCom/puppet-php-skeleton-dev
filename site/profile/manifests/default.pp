class profile::default {
    include apt

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
                age => '0',
                matches => ['webp.so', 'webp.la'],
                require => Package[$tool]
            }
        }
    }

    include services::openssl
    include services::wezterm

    # extend FS watch limit with max_user_watches
    sysctl { "fs.inotify.max_user_watches":
      ensure => present,
      value  => "524288",
    }

    # This file contains the maximum number of memory map areas a process may have.
    sysctl { "vm.max_map_count":
      ensure => present,
      value  => "1048576",
    }

    # update max open files (ulimit -n)
    sysctl { "fs.file-max":
      ensure => present,
      value  => "65535",
    }
}
