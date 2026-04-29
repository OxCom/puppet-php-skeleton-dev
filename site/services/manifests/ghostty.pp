class services::ghostty {
  info("Initialize")

  if $facts['os']['name'] == 'Ubuntu' {
    require services::ghostty::package
  } else {
    notice("Skipping Ghostty install: unsupported OS '${facts['os']['name']}'.")
  }
}
