---------------------------------
--- ENVIRONMENT VARIABLES     ---
---------------------------------

hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("ADW_DISABLE_PORTAL", "1")

-- Cedilla support (' + c = ç)
-- Also requires editing /usr/share/X11/locale/en_US.UTF-8/Compose
-- See FIX_CEDILLA.md for details
hl.env("XCOMPOSEFILE", os.getenv("HOME") .. "/.XCompose")
hl.env("XMODIFIERS", "@im=xim")
hl.env("GTK_IM_MODULE", "cedilla")
hl.env("QT_IM_MODULE", "cedilla")
