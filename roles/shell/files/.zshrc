# ===========================================
# Cross-platform .zshrc with OS conditionals
# ===========================================

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MACOS=true
    IS_LINUX=false
else
    IS_MACOS=false
    IS_LINUX=true
fi

# ===========================================
# PATH Configuration
# ===========================================

# Cross-platform paths
export PATH="$PATH:$HOME/scripts"
export PATH="$PATH:$HOME/work-scripts"
export PATH="$PATH:$HOME/go/bin:$HOME/bin"
export PATH="$HOME/.local/bin:$PATH"

# macOS-specific paths
if [[ "$IS_MACOS" == true ]]; then
    # Homebrew shell environment
    eval "$(/opt/homebrew/bin/brew shellenv)"

    # Homebrew security settings
    export HOMEBREW_NO_INSECURE_REDIRECT=1
    export HOMEBREW_CASK_OPTS=--require-sha

    # justfile completions (requires Homebrew)
    fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
fi

# ===========================================
# Go Configuration
# ===========================================
export GOPATH="$HOME/go"

if [[ "$IS_MACOS" == true ]]; then
    # Homebrew-installed Go
    export GOROOT="/opt/homebrew/Cellar/go/1.25.5/libexec"
elif [[ "$IS_LINUX" == true ]]; then
    # System Go on Linux
    export GOROOT="/usr/lib/golang"
fi

# ===========================================
# Java Configuration
# ===========================================
if [[ "$IS_MACOS" == true ]]; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 11 2>/dev/null)
    export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"
elif [[ "$IS_LINUX" == true ]]; then
    # Amazon Linux / RHEL Java path
    if [[ -d "/usr/lib/jvm/java-11" ]]; then
        export JAVA_HOME="/usr/lib/jvm/java-11"
        export PATH="$JAVA_HOME/bin:$PATH"
    fi
fi

# ===========================================
# Spark Configuration (macOS only for now)
# ===========================================
if [[ "$IS_MACOS" == true ]]; then
    export SPARK_HOME=/opt/homebrew/Cellar/apache-spark/3.5.1
    export PATH=$SPARK_HOME/bin:$PATH
fi

# ===========================================
# Oh-My-Zsh Configuration
# ===========================================
export ZSH="$HOME/.oh-my-zsh"

# Disable oh-my-zsh update prompts
export DISABLE_UPDATE_PROMPT=true
export DISABLE_AUTO_UPDATE=true

# Load workstation secrets if present
SECRETS_ENV="$HOME/.config/personal/secrets.env"
if [[ -r "$SECRETS_ENV" ]]; then
    source "$SECRETS_ENV"
fi

plugins=(
    git
    aliases
    branch
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-interactive-cd
    zsh-navigation-tools
    zsh-completions
)

source $ZSH/oh-my-zsh.sh

# ===========================================
# GPG Configuration
# ===========================================
export GPG_TTY=$(tty)

# ===========================================
# Git Functions and Aliases
# ===========================================

# git override, requires oh-my-zsh git plugin
unalias gap 2>/dev/null
gap () {
    if [ "$(git_current_branch)" = "master" ]; then
        echo "You sure you want to do this on master"
    else
        git add -A && git commit -n -m $1 && git push origin $(git_current_branch)
    fi
}

function gapf() {
    git add -A && git commit -n -m $1 && git push origin $(git_current_branch)
}

function gitsearch() {
    git --no-pager log -S "$1" --source --all
}

function git-master-branch-name() {
    VERBOSE_NAME=`git symbolic-ref refs/remotes/origin/HEAD`
    echo $VERBOSE_NAME | sed -e 's/refs\/remotes\/origin\///'
}

# The above function fails sometimes, this script fixes it
alias fixmaster="git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master"

function gcom() {
    git checkout `git-master-branch-name`
}

# Git aliases
alias gdc='git diff --cached'
alias gm='git merge --squash --no-commit'
alias gmcsg='gcmsg'
alias gacmsg='git add -A && git commit -m'
alias gcop='git checkout prod'
alias gpod='git pull origin prod'
alias gpom='git pull origin master'
alias gsc="git --no-pager shortlog -s -n"

# ===========================================
# Utility Functions
# ===========================================

# Easy extraction of various file types
extract () {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xvjf $1    ;;
            *.tar.gz)    tar xvzf $1    ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar x $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xvf $1     ;;
            *.tbz2)      tar xvjf $1    ;;
            *.tgz)       tar xvzf $1    ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "don't know how to extract '$1'..." ;;
        esac
    else
        echo "'$1' is not valid for extraction"
    fi
}

function md5() {
    echo -n "$@" | md5sum | awk '{print $1}'
}

function sha256() {
    echo -n "$@" | sha256sum | awk '{print $1}'
}

# ===========================================
# Editor Configuration
# ===========================================
export EDITOR=nvim

# Set up vim mode
bindkey -v

# Goodies for vim mode
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward

# Default .4 seconds ... but why
export KEYTIMEOUT=0

# ===========================================
# Terminal Configuration
# ===========================================

# Fancy less
export LESS='-R'
export LESSOPEN='|~/.lessfilter %s'

# Fancy ls
export LSCOLORS='exfxcxdxbxegedabagacad'
alias ls='ls --color=auto'

# Disable zsh correct
unsetopt correct_all

# Fancy CD
cdls () {
    cd $@ && ls --color=auto
}
alias cd='cdls'

# ===========================================
# Python Aliases
# ===========================================
alias venv3='python3 -m venv ./venv && source ./venv/bin/activate'
alias venv='virtualenv ./venv && source ./venv/bin/activate'
alias senv='source ./venv/bin/activate'
alias serve='python3 -m http.server'
alias urldecode='python -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'
alias urlencode='python -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'

# ===========================================
# Tool Aliases
# ===========================================

# Vim
alias v=nvim

# Docker
alias d=docker
alias dc=docker-compose

# Kubernetes
alias k=kubectl
alias kx=kubectx
alias kns=kubens
alias kgp='kubectl get po'
kxs() {
    kx `kx | fzf --layout=reverse`
}
function kw() {
    watch -n 1 "kubectl $@"
}

# Tmux
alias ta="tmux attach"

# Just
alias j=just

# ===========================================
# Custom Functions
# ===========================================

# Open a script or something
function vw() {
    nvim "$(which $1)"
}

# Opens a new tmp txt buf
function tmpTxtBuf() {
    __fname=`date +%s%3N-tmp-txt-buf`
    echo "Opening $__fname"
    nvim /tmp/$__fname
}
alias b=tmpTxtBuf

# Opens notes
function notes() {
    SWAPPATH="$HOME/.vim/swapfiles/notes.txt.swp"
    if [ "$1" = "-f" ]; then
        nvim ~/notes.txt
    else
        if [ ! -f "$SWAPPATH" ]; then
            nvim ~/notes.txt
        else
            echo "Swap Exists"
        fi
    fi
}

# ===========================================
# ROKT Specifics
# ===========================================
export PATH="$PATH:$HOME/ROKT/my-rokt-jwt/bin"

# Quickly fuzzy find projects
cdr () {
    A_DIRECTORY=`ls ~/ROKT | fzf`
    cdls ~/ROKT/$A_DIRECTORY
}

# Claude/AI configuration
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=us-west-2
alias rokt-ai="aws-vault exec rokt-ai --"

# Custom project paths
export PATH="$PATH:$HOME/go/src/github.com/pietdaniel/tq/bin"
alias cdtq="cd $HOME/go/src/github.com/pietdaniel/tq"

alias oc=opencode

# ===========================================
# Shell Integrations (load last)
# ===========================================

# Atuin (reverse search)
if command -v atuin &>/dev/null; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi

# Starship (prompt)
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# Shift+tab to accept zsh autocomplete suggestions
bindkey '^[[Z' autosuggest-accept

# ===========================================
# FNM (Fast Node Manager) - macOS only
# ===========================================
if [[ "$IS_MACOS" == true ]] && command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd)"
fi
