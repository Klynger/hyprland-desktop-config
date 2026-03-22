#!/usr/bin/env python3
"""Waybar custom module: shows current song (with marquee) or active window title.

Also manages the album art cache file for the image module.
"""

import json
import os
import shutil
import signal
import subprocess
import sys
import threading
import time
from urllib.parse import unquote, urlparse

MAX_WIDTH = 40
SCROLL_INTERVAL = 0.4
SCROLL_SEPARATOR = "   ·   "
ART_CACHE = os.path.join(
    os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "waybar-media-art"
)
PLAYER_ICONS = {
    "chromium": "",
    "firefox": "",
    "mpv": "󰐹",
    "spotify": "󰎆",
}


def playerctl(*args):
    try:
        r = subprocess.run(
            ["playerctl", *args], capture_output=True, text=True, timeout=2
        )
        return r.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return ""


def get_active_window():
    try:
        r = subprocess.run(
            ["hyprctl", "activewindow", "-j"],
            capture_output=True, text=True, timeout=2,
        )
        return json.loads(r.stdout).get("title", "") or "Desktop"
    except Exception:
        return "Desktop"


def refresh_media_art():
    subprocess.run(
        ["pkill", "-RTMIN+8", "waybar"],
        capture_output=True, timeout=2,
    )


def update_art_cache():
    art_url = playerctl("metadata", "mpris:artUrl")
    if art_url:
        parsed = urlparse(art_url)
        if parsed.scheme == "file":
            path = unquote(parsed.path)
            if os.path.isfile(path):
                shutil.copy2(path, ART_CACHE)
                return
    remove_art_cache()


def remove_art_cache():
    try:
        os.remove(ART_CACHE)
    except FileNotFoundError:
        pass


def emit_json(text, tooltip, css_class):
    obj = {"text": text, "tooltip": tooltip, "class": css_class}
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def marquee(text, offset):
    """Return a sliding window of MAX_WIDTH chars from looped text."""
    if len(text) <= MAX_WIDTH:
        return text
    looped = text + SCROLL_SEPARATOR
    total = len(looped)
    start = offset % total
    window = (looped + looped)[start:start + MAX_WIDTH]
    return window


class MediaModule:
    def __init__(self):
        self._scroll_offset = 0
        self._full_text = ""
        self._tooltip = ""
        self._is_playing = False
        self._lock = threading.Lock()
        self._stop = threading.Event()

    def run(self):
        self._update_state()
        self._emit()

        # Event listener thread
        ev_thread = threading.Thread(target=self._listen_events, daemon=True)
        ev_thread.start()

        # Main loop handles scrolling
        while not self._stop.is_set():
            with self._lock:
                if self._is_playing and len(self._full_text) > MAX_WIDTH:
                    self._scroll_offset += 1
                    self._emit_locked()
            time.sleep(SCROLL_INTERVAL)

    def _update_state(self):
        status = playerctl("status")
        if status == "Playing":
            title = playerctl("metadata", "title")
            artist = playerctl("metadata", "artist")
            player = playerctl("metadata", "--format", "{{playerName}}")

            icon = PLAYER_ICONS.get(player, "")

            text = title
            if artist:
                text = f"{title} - {artist}"
            if icon:
                text = f"{icon} {text}"

            tooltip = title
            if artist:
                tooltip += f"\n{artist}"
            album = playerctl("metadata", "album")
            if album:
                tooltip += f"\n{album}"

            update_art_cache()

            with self._lock:
                if text != self._full_text:
                    self._scroll_offset = 0
                self._full_text = text
                self._tooltip = tooltip
                self._is_playing = True
        else:
            window_title = get_active_window()
            remove_art_cache()

            with self._lock:
                self._full_text = window_title
                self._tooltip = window_title
                self._is_playing = False
                self._scroll_offset = 0

        refresh_media_art()

    def _emit(self):
        with self._lock:
            self._emit_locked()

    def _emit_locked(self):
        css_class = "playing" if self._is_playing else "window"
        display = marquee(self._full_text, self._scroll_offset)
        emit_json(display, self._tooltip, css_class)

    def _listen_events(self):
        """Listen for playerctl and Hyprland events."""
        import selectors

        sel = selectors.DefaultSelector()

        # playerctl --follow status
        try:
            p_proc = subprocess.Popen(
                ["playerctl", "--follow", "status"],
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            )
            sel.register(p_proc.stdout, selectors.EVENT_READ, "playerctl")
        except FileNotFoundError:
            p_proc = None

        # Hyprland IPC socket
        hypr_sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
        xdg = os.environ.get("XDG_RUNTIME_DIR", "")
        sock_path = f"{xdg}/hypr/{hypr_sig}/.socket2.sock"

        s_proc = None
        if os.path.exists(sock_path):
            try:
                s_proc = subprocess.Popen(
                    ["socat", "-u", f"UNIX-CONNECT:{sock_path}", "-"],
                    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                )
                sel.register(s_proc.stdout, selectors.EVENT_READ, "hyprland")
            except FileNotFoundError:
                s_proc = None

        try:
            while not self._stop.is_set():
                events = sel.select(timeout=1)
                for key, _ in events:
                    line = key.fileobj.readline()
                    if not line:
                        continue
                    self._update_state()
                    self._emit()
        finally:
            if p_proc:
                p_proc.kill()
            if s_proc:
                s_proc.kill()
            sel.close()


def main():
    def cleanup(*_):
        remove_art_cache()
        sys.exit(0)

    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    module = MediaModule()
    module.run()


if __name__ == "__main__":
    main()
