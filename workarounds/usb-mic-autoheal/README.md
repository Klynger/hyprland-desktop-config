# USB Mic Auto-Heal

Workaround for a **hardware problem**: the C-Media USB mic (`0d8c:016c`)
has a marginal cable/connector. Moving the cable corrupts the USB link
(`EPROTO -71` in the kernel log), which triggers this cascade:

1. The mic disconnect-loops while the contact is unstable.
2. On kernels ≥ 7.2 the error storm makes the kernel set `disable=1` on
   **all four ports** of the rear-panel Genesys Logic hub (`05e3:0608`,
   path `3-3`) — everything plugged there goes electrically silent until
   the ports are re-enabled or the machine reboots. (LTS 6.18 instead
   retries and recovers on its own.)
3. Every reconnect leaves a ghost PipeWire node behind; apps stuck
   capturing a ghost play a looping "tic tic tic" junk sound.

## What this does

A udev rule fires on every disconnect of the mic and starts a oneshot
systemd service that:

1. re-enables any kernel-disabled ports on hub `3-3`,
2. waits for the mic to re-enumerate,
3. restarts the user's `wireplumber`/`pipewire`/`pipewire-pulse` to purge
   ghost nodes (debounced to once per 30 s), and sends a desktop
   notification.

Discord still needs a manual restart afterwards if it lost its device
list — it doesn't reconnect to a restarted audio server.

## Install / uninstall

```bash
sudo ./install.sh --create
sudo ./install.sh --delete
```

## Machine-specific bits

- Hub sysfs path `3-3` and the mic's USB IDs are hardcoded in
  `usb-mic-autoheal` — adjust if the topology changes.

## Remove this workaround

Once the mic cable is repaired or the mic replaced, run
`sudo ./install.sh --delete` and delete this directory.
