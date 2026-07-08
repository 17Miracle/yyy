[[ -f ~/.config/bash/.bashrc ]] && . ~/.config/bash/.bashrc

# Default programs
export PAGER="/usr/bin/less"
export EDITOR="/usr/bin/nvim"
export VISUAL="/usr/bin/nvim"
export BROWSER="/usr/bin/brave"
export VIDEOPLAYER="/usr/bin/mpv"
export TERMINAL="/usr/bin/ghostty"
export SUDO_EDITOR="/usr/bin/nvim"
export IMAGEVIEWER="/usr/bin/swayimg"

# Follow XDG base dir specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# History files
export HISTFILE="$XDG_CACHE_HOME/bash/bash_history"
export LESSHISTFILE="$XDG_CACHE_HOME/less/less_history"
export PYTHON_HISTORY="$XDG_DATA_HOME/python/python_history"

# Moving other files and some other variables
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOPATH="$XDG_DATA_HOME/go"
export GOBIN="$GOPATH/bin"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export NPM_CONFIG_PREFIX="$XDG_DATA_HOME/npm"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export DATE=$(date "+%-d %B %Y, %A, %T")
export MANPAGER="nvim +Man!"

export FZF_DEFAULT_OPTS="--style full --color 16 --layout=reverse --height 30% --preview='bat -p --color=always {}'"
export FZF_CTRL_R_OPTS="--style full --color 16 --layout=reverse --height 30% --no-preview"

# Important
export XDG_CURRENT_DESKTOP=niri
export XDG_SESSION_DESKTOP=niri
export XDG_SESSION_TYPE=wayland
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
export ELECTRON_OZONE_PLATFORM_HINT=wayland
export ELECTRON_ENABLE_HARDWARE_ACCELERATION=1
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_SCALE_FACTOR=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export _JAVA_AWT_WM_NONREPARENTING=1
export GDK_BACKEND="wayland,x11,*"
export GDK_SCALE=1
export GDK_USE_PORTAL=1
export MOZ_ENABLE_WAYLAND=1
export WLR_NO_HARDWARE_CURSORS=1
