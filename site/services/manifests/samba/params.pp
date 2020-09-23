class services::samba::params {
    $workgroup = lookup('samba.workgroup', String, 'first', [])
}
