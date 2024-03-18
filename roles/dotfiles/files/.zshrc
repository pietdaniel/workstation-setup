# Path
export PATH="${PATH?}:/Users/piet/scripts"
export PATH="${PATH?}:/Users/rokt/scripts"

# Go
export GOPATH="${HOME?}/go"
export GOROOT="$(go env GOROOT)"
export PATH="$PATH:$HOME/go/bin:$HOME/bin"

# Force certain more-secure behaviours from homebrew
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CASK_OPTS=--require-sha

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"

# justfile completions
eval "$(brew shellenv)"
fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)

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

# git override, requires oh-my-zsh git plugin
unalias gap
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
alias gdc='git diff --cached'
alias gsc="git --no-pager shortlog -s -n"
alias gpod='git pull origin prod'
alias gpom='git pull origin master'
alias gdc='git diff --cached'

# easy extraction of various file types
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

# the one, the only
export EDITOR=nvim

# set up vim
bindkey -v

# goodies for vim mode
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward

# default .4 seconds ... but why
export KEYTIMEOUT=0

# fancy less
export LESS='-R'
export LESSOPEN='|~/.lessfilter %s'

# fancy ls
export LSCOLORS='exfxcxdxbxegedabagacad'
alias ls='ls --color=auto'

# disable zsh correct
unsetopt correct_all

# Fancy CD
cdls () {
    cd $@ && ls --color=auto
}
alias cd='cdls'

# Python aliases
alias venv3='python3 -m venv ./venv && source ./venv/bin/activate'
alias venv='virtualenv ./venv && source ./venv/bin/activate'
alias senv='source ./venv/bin/activate'
alias serve='python3 -m http.server'
alias urldecode='python -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'
alias urlencode='python -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'

# Vim aliases
alias v=nvim

# Docker Aliases
alias d=docker
alias dc=docker-compose

# K8s Aliases
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

## open a script or something
function vw() {
  nvim "$(which $1)"
}

## opens a new tmp txt buf
function tmpTxtBuf() {
  __fname=`date +%s%3N-tmp-txt-buf`
  echo "Opening $__fname"
  nvim /tmp/$__fname
}

alias b=tmpTxtBuf

# Tmux aliases
alias ta="tmux attach"

# just aliases
alias j=just

# opens my notes
function notes() {
  SWAPPATH="/Users/piet/.vim/swapfiles/notes.txt.swp"
  if [ "$1" = "-f" ]; then
    nvim ~/notes.txt
  else
    if [ ! -f "$SWAPPATH"  ]; then
      nvim ~/notes.txt
    else
      echo "Swap Exists"
    fi
  fi
}

# =vv ROKT Specifics vv=

# Quickly fuzzy find projects
cdr () {
  A_DIRECTORY=`ls ~/ROKT | fzf`
  cdls ~/ROKT/$A_DIRECTORY
}

# =^^ ROKT Specifics ^^=


# reverse search
eval "$(atuin init zsh --disable-up-arrow)"

# prompt
eval "$(starship init zsh)"

# shift+tab to accept zshrc autocomplete suggestions
bindkey '^[[Z' autosuggest-accept
