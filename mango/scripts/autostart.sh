#!/usr/bin/env sh

#
# /home/$USER/.config/mango/scripts/autostart.sh
#

set +e

# Locale — week starts on Monday
export LC_TIME=en_GB.UTF-8

# Screen Sharing
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wlroots >/dev/null 2>&1
