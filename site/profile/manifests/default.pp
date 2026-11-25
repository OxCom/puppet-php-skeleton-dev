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
            # Remove only ImageMagick's webp coder modules. A recursive tidy over
            # /usr/lib scans ~70k entries every run and triggers the max_files warning.
            $webp_coders = '/usr/lib/*/ImageMagick-*/modules-*/coders/webp.so /usr/lib/*/ImageMagick-*/modules-*/coders/webp.la'
            exec { 'webp-fix':
                command  => "rm -f ${webp_coders}",
                onlyif   => "test -n \"\$(ls ${webp_coders} 2>/dev/null)\"",
                provider => shell,
                path     => '/bin:/usr/bin',
                require  => Package[$tool]
            }
        }
    }

    include services::git
    include services::snapd
    include services::openssl
    include services::ghostty
    include services::mc

    sysctl { "fs.inotify.max_user_watches":
      ensure => present,
      value  => "524288",
    }

    sysctl { "vm.max_map_count":
      ensure => present,
      value  => "1048576",
    }

    sysctl { "fs.file-max":
      ensure => present,
      value  => "65535",
    }
}
