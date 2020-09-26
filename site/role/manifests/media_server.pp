class role::media_server inherits role::default {
    include profile::smb

    include services::docker::params
    include services::docker
}
