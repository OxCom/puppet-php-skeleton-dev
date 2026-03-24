class services::wezterm {
  info("Initialize")

  if $facts['os']['name'] == 'Ubuntu' {
    require services::wezterm::package
  } else {
    notice("Skipping WezTerm install: unsupported OS '${facts['os']['name']}'.")
  }
}
