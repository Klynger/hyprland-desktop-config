# How to fix Cedilla in en intl keyboard - [source](https://gist.github.com/nilo/c2a31a0f9f29c88145ca)

1. English(US, internacional with dead Keys) on your system keyboard layout.
2. Editing the files:

```bash
sudo vim /usr/lib/gtk-3.0/3.0.0/immodules.cache
sudo vim /usr/lib/gtk-2.0/2.10.0/immodules.cache
```

changing the line
```
"cedilla" "Cedilla" "gtk20" "/usr/share/locale" "az:ca:co:fr:gv:oc:pt:sq:tr:wa"
```

to

```
"cedilla" "Cedilla" "gtk20" "/usr/share/locale" "az:ca:co:fr:gv:oc:pt:sq:tr:wa:en"
```

3. Replacing "ć" to "ç" and "Ć" to "Ç" on /usr/share/X11/locale/en_US.UTF-8/Compose

```bash
sudo cp /usr/share/X11/locale/en_US.UTF-8/Compose /usr/share/X11/locale/en_US.UTF-8/Compose.bak
sed 's/ć/ç/g' < /usr/share/X11/locale/en_US.UTF-8/Compose | sed 's/Ć/Ç/g' > Compose
sudo mv Compose /usr/share/X11/locale/en_US.UTF-8/Compose
```

Instead of doing this you might want to create a custom Compose file and point to it on your `.xprofile`:

```bash
export XCOMPOSEFILE="$HOME/.XCompose"
```

4. Add two lines on /etc/environment

```bash
GTK_IM_MODULE=cedilla
QT_IM_MODULE=cedilla
```

5. Restart your computer

Some applications might still not work after this change, so you need to maybe edit them. One example is Google Chrome. You might need to create a flags file for chrome:

```bash
mkdir ~/.config
touch ~/.config/chrome-flags.conf
echo "--ozone-platform=x11" >> ~/.config/chrome-flags.conf
```

This will add a default flag to Chrome when opening. Chrome, by default, uses Wayland as the display server. This causes some issues with the Cedilla fix because wayland is not as customizable as X11. By adding this flag, we are telling Chrome to use X11 instead of Wayland.
