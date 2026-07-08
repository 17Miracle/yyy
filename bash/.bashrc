[[ $- == *i* ]] && source -- "/usr/share/blesh/ble.sh" --attach=none

##-----------------------------------------------------------------------------
## Aliases
alias e="nvim"
alias vi="nvim"
alias vim="nvim"
alias se="sudoedit"

alias cp="cp -r"
alias rm="rm -rf --"
alias mkdir="mkdir -p"
alias cdir='cd "${_%/*}"'

alias cat="bat"
alias img="feh"
alias top="btop"
alias reboot="sudo reboot"
alias grep="grep --color=auto"
alias shutdown="sudo shutdown -h now"

alias ls='eza --icons --color=always'
alias sl='eza --icons --color=always'
alias ll='eza -laghm@ --all --icons --git --color=always'


##-----------------------------------------------------------------------------
## Functions

# Usage: extract file
extract() {
    if [ -z "$1" ]; then
        echo "Error: No file specified."
        return 1
    fi

    if [ ! -f "$1" ]; then
        echo "Error: '$1' is not a valid file!"
        return 1
    fi

    case "$1" in
        *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2)
            tar xvf "$1" ;;
        *.zip|*.7z)
            7z x "$1" ;;
        *.rar)
            unrar x "$1" ;;
        *)
            echo "Error: Cannot extract '$1'. Unsupported file format."
            return 1 ;;
    esac
}

##-----------------------------------------------------------------------------
## The Shopt Builtin
shopt -s cdable_vars
shopt -s cdspell
shopt -s checkwinsize
shopt -s dirspell
shopt -s dotglob
shopt -s extglob
shopt -s histappend
shopt -s hostcomplete
shopt -s no_empty_cmd_completion
shopt -s nocaseglob


##-----------------------------------------------------------------------------
## History
export HISTCONTROL=ignoreboth
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTTIMEFORMAT='%F %T '

# Usage: ignores single-word commands
HISTIGNORE=$'*([\t ])+([-%+,./0-9\:@A-Z_a-z])*([\t ])'


##-----------------------------------------------------------------------------
## Prompt
# Store `tput` colors for future use
COLOR256=()
COLOR256[103]=$(tput setaf 103) # muted (for git branch)
COLOR256[204]=$(tput setaf 204) # love (for exit code and prompt char)
COLOR256[216]=$(tput setaf 216) # gold (for cwd)
COLOR256[256]=$(tput sgr0)
COLOR256[257]=$(tput bold)

# Colors for use in PS1
PROMPT_COLORS=()

# Set prompt colors to Rosé Pine Moon theme
set_prompt_colors() {
    PROMPT_COLORS[0]=${COLOR256[204]}${COLOR256[257]} # love (bold) for exit code and prompt char
    PROMPT_COLORS[3]=${COLOR256[103]}${COLOR256[257]} # muted (bold) for git branch
    PROMPT_COLORS[5]=${COLOR256[216]}${COLOR256[257]} # gold (bold) for cwd
}

# Exit code of last process
PS1='$(ret=$?;(($ret!=0)) && echo "\[${COLOR256[204]}\]($ret) \[${COLOR256[256]}\]")'

# CWD
PS1+='\[${PROMPT_COLORS[5]}\]\w '

# Optional git branch with * for uncommitted changes
PS1+='$(branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); [[ -n $branch ]] && echo -n "\[${PROMPT_COLORS[3]}\]$branch" && (git status --porcelain 2>/dev/null | grep -q . && echo "*") || echo "") '

# Prompt character ($ for non-root, nothing for root)
PS1+='$(if [[ $UID != 0 ]]; then echo "\[${PROMPT_COLORS[0]}\]\$"; fi)\[${COLOR256[256]}\] '

# Set the Rosé Pine Moon theme
set_prompt_colors

# Prompt command (optional, for terminal title)
_prompt_command() {
    local pwd=${PWD/#$HOME/\~}
    printf "\033]0;%s\007" "$pwd"
}
PROMPT_COMMAND=_prompt_command


##-----------------------------------------------------------------------------
[[ ! ${BLE_VERSION-} ]] || ble-attach
