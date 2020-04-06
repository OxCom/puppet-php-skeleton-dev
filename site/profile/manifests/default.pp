class profile::default {
    include apt
    include ntp

    # the base profile should include component modules that will be on all nodes
    $tools = lookup('tools', Array, 'deep', []);
    $tools.each |Integer $index, String $tool| {
        package { $tool:
            ensure => present
        }
    }

    include services::openssl
}
