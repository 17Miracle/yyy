#
# /home/$USER/.config/zsh/.zshrc
#

# Core modules
zmodload zsh/complist

# Autoload utilities
autoload -Uz colors && colors
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
autoload -Uz add-zsh-hook

# Use emacs-style key bindings
bindkey -e

# Register ZLE widgets
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Arrow key history search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

#: Hooks
# Rehash commands automatically on directory change
rehash_on_cd() { rehash }
add-zsh-hook chpwd rehash_on_cd

#: Completion
zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' menu no
zstyle ':completion:*' verbose yes
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' ignore-parents parent pwd

# Matching rules (case-insensitive + partial matching)
zstyle ':completion:*' matcher-list \
       '' \
       'm:{a-zA-Z}={A-Za-z}' \
       'r:|[._-]=* r:|=*'

# Grouping & sorting
zstyle ':completion:*' group-name ''
zstyle ':completion:*' file-sort modification reverse

# Cache completion results
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Warnings formatting
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'

#: Aloxaf/fzf-tab configuration
# Disable git checkout sorting (keeps git order)
zstyle ':completion:*:git-checkout:*' sort false

# Group navigation
zstyle ':fzf-tab:*' switch-group '<' '>'

# zlua integration
zstyle ':fzf-tab:complete:_zlua:*' query-string input

# Use tmux popup
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

# Popup sizing
zstyle ':fzf-tab:complete:cd:*' popup-pad 50 0
zstyle ':fzf-tab:*' popup-min-size 50 8
zstyle ':fzf-tab:complete:diff:*' popup-min-size 80 12

# Preview for cd completion
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
       'eza -1 --color=always $realpath'

# Using gruvbox-material colors
FZF_TAB_GROUP_COLORS=(
    $'\033[38;5;109m' $'\033[38;5;107m' $'\033[38;5;179m'
    $'\033[38;5;139m' $'\033[38;5;167m' $'\033[38;5;63m'
    $'\033[38;5;108m' $'\033[38;5;144m' $'\033[38;5;168m'
    $'\033[91m'       $'\033[38;5;84m'  $'\033[92m'
    $'\033[38;5;214m' $'\033[38;5;134m' $'\033[38;5;172m'
    $'\033[38;5;114m'
)
zstyle ':fzf-tab:*' group-colors $FZF_TAB_GROUP_COLORS

#: Shell options
setopt GLOBDOTS
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS
setopt CDABLE_VARS
setopt PUSHD_IGNORE_DUPS

# Disable audible/visual bells
unsetopt BEEP LIST_BEEP

#: History configuration
# History behavior
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt APPEND_HISTORY

# History size
HISTSIZE=5000000
SAVEHIST=5000000

#: Prompt
PROMPT='%F{cyan}%~%f $ '

#: User shell extensions (aliases, functions)
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/alias" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/alias"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/fn" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/fn"

#: fzf integration
# Load dynamic fzf zsh integration if available
if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
fi

# System-wide fzf extras
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh

#: Plugins
plugins=(
    /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.plugin.zsh
    ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins/fzf-tab-source/*.plugin.zsh(N)
    /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
)

for plugin in "${plugins[@]}"; do
    [ -f "$plugin" ] && source "$plugin"
done
