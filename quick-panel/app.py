"""QuickPanel — a GTK4 popup with media controls and quick-launch buttons."""

import os
import subprocess
import threading
from pathlib import Path
from urllib.parse import urlparse, unquote

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gtk, Gdk, GLib, Gtk4LayerShell, Pango

APP_DIR = Path(__file__).parent
STYLE_CSS = APP_DIR / "style.css"

PLAYER_ICONS = {
    "chromium": "",
    "firefox": "",
    "mpv": "󰐹",
    "spotify": "󰎆",
}


def playerctl_async(*args):
    """Run a playerctl command in a background thread (fire-and-forget)."""
    threading.Thread(
        target=lambda: subprocess.run(
            ["playerctl", *args],
            capture_output=True, timeout=2
        ),
        daemon=True,
    ).start()


def playerctl(*args):
    """Run a playerctl command and return stdout."""
    try:
        result = subprocess.run(
            ["playerctl", *args],
            capture_output=True, text=True, timeout=2
        )
        return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return ""


def get_media_info():
    """Get current media metadata from playerctl."""
    status = playerctl("status")
    if not status or status == "Stopped":
        return None

    title = playerctl("metadata", "title")
    artist = playerctl("metadata", "artist")
    album = playerctl("metadata", "album")
    player = playerctl("metadata", "--format", "{{playerName}}")
    art_url = playerctl("metadata", "mpris:artUrl")

    art_path = ""
    if art_url:
        parsed = urlparse(art_url)
        if parsed.scheme == "file":
            art_path = unquote(parsed.path)
        elif parsed.scheme in ("http", "https"):
            art_path = art_url

    return {
        "status": status,
        "title": title or "Unknown",
        "artist": artist or "",
        "album": album or "",
        "player": player or "",
        "art_path": art_path,
    }


class QuickPanel(Gtk.Application):
    ART_SIZE = 120

    def __init__(self):
        super().__init__(application_id="dev.klynger.QuickPanel")
        self.win = None
        self.media_update_id = None
        self._title_label = None
        self._artist_label = None
        self._album_label = None
        self._play_btn = None
        self._art_widget = None
        self._current_art_path = ""
        self._is_playing = False

    def do_activate(self):
        if self.win:
            self.win.present()
            return

        # Load CSS — USER priority so window transparency overrides GTK theme
        css_provider = Gtk.CssProvider()
        css_provider.load_from_path(str(STYLE_CSS))
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_USER,
        )

        # Main panel window
        self.win = Gtk.Window(application=self)
        self.win.set_default_size(380, -1)
        self.win.set_resizable(False)
        self.win.set_decorated(False)

        Gtk4LayerShell.init_for_window(self.win)
        Gtk4LayerShell.set_layer(self.win, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_anchor(self.win, Gtk4LayerShell.Edge.TOP, True)
        Gtk4LayerShell.set_margin(self.win, Gtk4LayerShell.Edge.TOP, 8)
        Gtk4LayerShell.set_keyboard_mode(
            self.win, Gtk4LayerShell.KeyboardMode.ON_DEMAND
        )

        key_ctrl = Gtk.EventControllerKey()
        key_ctrl.connect("key-pressed", self._on_key)
        self.win.add_controller(key_ctrl)

        # Close when clicking outside (window loses focus)
        self.win.connect("notify::is-active", self._on_focus_change)

        # Main layout
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        main_box.add_css_class("quick-panel")

        # Media section
        self.media_box = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL, spacing=0
        )
        self._build_media_section()
        main_box.append(self.media_box)

        # Separator
        main_box.append(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL))

        # Quick-launch grid
        launch_box = Gtk.Box(
            orientation=Gtk.Orientation.HORIZONTAL, spacing=16
        )
        launch_box.set_halign(Gtk.Align.CENTER)
        launch_box.append(
            self._make_launch_button("󰃭", "Calendar", "org.gnome.Calendar")
        )
        main_box.append(launch_box)

        self.win.set_child(main_box)

        self.media_update_id = GLib.timeout_add(500, self._update_media)
        self.win.present()

    def _load_art(self, art_path):
        """Load album art into a fixed-size widget."""
        if not art_path or not os.path.isfile(art_path):
            return None

        try:
            texture = Gdk.Texture.new_from_filename(art_path)
            picture = Gtk.Picture.new_for_paintable(texture)
            picture.set_size_request(self.ART_SIZE, self.ART_SIZE)
            picture.set_content_fit(Gtk.ContentFit.COVER)
            picture.set_can_shrink(True)
            picture.add_css_class("album-art")

            fixed = Gtk.Fixed()
            fixed.set_size_request(self.ART_SIZE, self.ART_SIZE)
            fixed.set_halign(Gtk.Align.START)
            fixed.set_valign(Gtk.Align.CENTER)
            fixed.set_hexpand(False)
            fixed.set_vexpand(False)
            fixed.put(picture, 0, 0)
            fixed.add_css_class("album-art-frame")
            return fixed
        except Exception:
            return None

    def _build_media_section(self):
        child = self.media_box.get_first_child()
        while child:
            next_child = child.get_next_sibling()
            self.media_box.remove(child)
            child = next_child

        info = get_media_info()

        if not info:
            self._title_label = None
            self._artist_label = None
            self._album_label = None
            self._play_btn = None
            self._art_widget = None
            self._current_art_path = ""
            no_media = Gtk.Label(label="No media playing")
            no_media.add_css_class("dim-label")
            no_media.add_css_class("no-media")
            self.media_box.append(no_media)
            return

        self._is_playing = info["status"] == "Playing"
        self._current_art_path = info["art_path"]
        # Media card
        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        card.add_css_class("media-card")

        # Top row: art left, info right
        top_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)

        self._art_widget = self._load_art(info["art_path"])
        if self._art_widget:
            top_row.append(self._art_widget)

        # Info column
        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        info_box.set_hexpand(True)
        info_box.set_valign(Gtk.Align.CENTER)

        player_icon = PLAYER_ICONS.get(info["player"], "")
        player_name = info["player"].capitalize() if info["player"] else ""
        if player_icon or player_name:
            source_label = Gtk.Label(
                label=f"{player_icon}  {player_name}".strip(), xalign=0
            )
            source_label.add_css_class("media-player-source")
            info_box.append(source_label)

        self._title_label = Gtk.Label(label=info["title"], xalign=0)
        self._title_label.set_ellipsize(Pango.EllipsizeMode.END)
        self._title_label.set_max_width_chars(22)
        self._title_label.add_css_class("media-title")
        info_box.append(self._title_label)

        if info["artist"]:
            self._artist_label = Gtk.Label(label=info["artist"], xalign=0)
            self._artist_label.set_ellipsize(Pango.EllipsizeMode.END)
            self._artist_label.set_max_width_chars(22)
            self._artist_label.add_css_class("media-artist")
            info_box.append(self._artist_label)
        else:
            self._artist_label = None

        if info["album"]:
            self._album_label = Gtk.Label(label=info["album"], xalign=0)
            self._album_label.set_ellipsize(Pango.EllipsizeMode.END)
            self._album_label.set_max_width_chars(22)
            self._album_label.add_css_class("media-album")
            info_box.append(self._album_label)
        else:
            self._album_label = None

        top_row.append(info_box)
        card.append(top_row)

        # Controls
        controls = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        controls.set_halign(Gtk.Align.CENTER)

        prev_btn = self._make_control_button("󰒮", "control-btn")
        prev_btn.connect("clicked", self._on_prev)
        controls.append(prev_btn)

        play_icon = "󰏤" if self._is_playing else "󰐊"
        self._play_btn = self._make_control_button(play_icon, "control-btn-play")
        self._play_btn.connect("clicked", self._on_play_pause)
        controls.append(self._play_btn)

        next_btn = self._make_control_button("󰒭", "control-btn")
        next_btn.connect("clicked", self._on_next)
        controls.append(next_btn)

        card.append(controls)
        self.media_box.append(card)

    def _make_control_button(self, label_text, css_class):
        """Create a control button with a centered text label."""
        btn = Gtk.Button(label=label_text)
        btn.add_css_class(css_class)
        return btn

    def _set_play_label(self):
        self._play_btn.set_label("󰏤" if self._is_playing else "󰐊")

    def _on_play_pause(self, _btn):
        self._is_playing = not self._is_playing
        self._set_play_label()
        playerctl_async("play-pause")

    def _on_prev(self, _btn):
        playerctl_async("previous")

    def _on_next(self, _btn):
        playerctl_async("next")

    def _update_media(self):
        info = get_media_info()

        if not info:
            if self._title_label is not None:
                self._build_media_section()
            return True

        if self._title_label is None:
            self._build_media_section()
            return True

        if info["art_path"] != self._current_art_path:
            self._build_media_section()
            return True

        self._title_label.set_label(info["title"])
        if self._artist_label:
            self._artist_label.set_label(info["artist"])
        if self._album_label:
            self._album_label.set_label(info["album"])

        self._is_playing = info["status"] == "Playing"
        self._set_play_label()

        return True

    def _make_launch_button(self, icon, label_text, command):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        box.set_halign(Gtk.Align.CENTER)

        btn = Gtk.Button(label=icon)
        btn.add_css_class("launch-btn")
        btn.connect("clicked", lambda _: self._launch(command))
        box.append(btn)

        label = Gtk.Label(label=label_text)
        label.add_css_class("launch-label")
        box.append(label)

        return box

    def _launch(self, command):
        subprocess.Popen(
            ["gtk-launch", command], start_new_session=True
        )

    def _on_focus_change(self, win, _pspec):
        if not win.is_active():
            # Small delay to avoid closing during transient focus changes
            GLib.timeout_add(150, self._check_focus)

    def _check_focus(self):
        if self.win and not self.win.is_active():
            self.quit()
        return False

    def _on_key(self, _ctrl, keyval, _keycode, _state):
        if keyval == Gdk.KEY_Escape:
            self.quit()
            return True
        return False
