alsa_monitor.rules = {
  {
   matches: {{}},
    apply_properties = {
      ["api.alsa.disable-nmap"] = false,
      ["session.suspend-timeout-seconds"] = 0,
    },
  },
}
