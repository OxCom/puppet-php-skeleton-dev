class services::samba::params {
    $workgroup = lookup('samba.workgroup', String, 'first', 'WORKGROUP')
    $allow_guests = lookup('samba.allow_guests', String, 'first', 'yes')
}
