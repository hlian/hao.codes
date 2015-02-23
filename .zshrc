zsh ~/.zshrc-install

ZSH=$HOME/.oh-my-zsh
ZSH_THEME="blinks"
SOLARIZED_THEME="light"
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="yyyy-mm-dd"
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
plugins=(git zsh-syntax-highlighting colored-man systemd)
source $ZSH/oh-my-zsh.sh
export PS1=$'\n'$PS1

setopt auto_pushd
setopt autocd
setopt extendedglob
setopt hist_verify
setopt incappendhistory
setopt menu_complete
setopt nobeep
setopt noclobber
setopt noflowcontrol
setopt nomatch
setopt sharehistory
setopt rcquotes
unsetopt case_glob
unsetopt nomatch
compdef -d git

# Aliases. ####################
bindkey -e
alias l='ls -Fh'
alias ll='l -l'
alias -g  L='|& less'
alias -g  D='>| /tmp/diff.diff'
alias -g  bb='$(git branch | fzf +s +m)'
alias -g  brb='$(git branch -r | sed "s/origin\///" | fzf +s +m)'
alias -g  .log='$(git log --reverse --pretty=oneline --abbrev-commit -10 | fzf +s --prompt="fixup> " | awk ''{ print $1 }'')'
alias telnet='rlwrap telnet'
alias reload='. ~/.zshrc'
alias v='vim'
alias ci='cabal install --disable-documentation --disable-coverage --disable-benchmarks --disable-library-profiling -j'
# http://dev.stephendiehl.com/hask/#data-formats
alias ghci-core="ghci -ddump-simpl -dsuppress-idinfo -dsuppress-coercions -dsuppress-type-applications -dsuppress-uniques -dsuppress-module-prefixes"
alias dgit='git --git-dir ~/dotfiles/.git'
alias egit='git --git-dir ~/.emacs.d/.git'
alias g='git commit -vp'
alias gc='git cherry-pick'
alias gr='git rebase'
alias gi='git rebase -i'
alias u='git submodule update'
alias gt='cd ~/lab/ios'
alias recask='pushd ~/.emacs.d && cask build && popd'

export HISTSIZE=100000
export SAVEHIST=100000

export WORDCHARS=
export CLICOLOR=1
export LESS=-Ri
export LSCOLORS=ExFxCxDxBxegedabagacad

if [[ -d /usr/local/bin ]]; then
    export PATH=/usr/local/bin:$PATH
fi

if [[ -d /usr/local/sbin ]]; then
    export PATH=/usr/local/sbin:$PATH
fi

if [[ -d $HOME/.cabal/bin ]]; then
    export PATH=$HOME/.cabal/bin:$PATH
fi

if [[ $TERM_PROGRAM =~ iTerm.app ]]; then
    alias emacs='~/Applications/Emacs.app/Contents/MacOS/Emacs -nw --no-desktop'
    export EDITOR='~/Applications/Emacs.app/Contents/MacOS/Emacs -nw --no-desktop'
    alias e='open -a Emacs'
else
    export EDITOR='emacs --no-desktop'
    alias e='emacs --no-desktop'
fi

if which ruby >/dev/null && which gem >/dev/null; then
    export PATH="$(ruby -rubygems -e 'puts Gem.user_dir')/bin:$PATH"
fi

if [[ -d ~/.cask/bin ]]; then
    export PATH="$HOME/.cask/bin:$PATH"
fi

if [[ -d ~/.cabal/bin ]]; then
    export PATH="$HOME/.cabal/bin:$PATH"
fi

if [[ ! -f ~/.zshrc-here ]]; then
    touch ~/.zshrc-here
fi

source ~/.fzf.zsh
source ~/.zshrc-here
# http://serverfault.com/questions/192499/prune-duplicate-entries-from-path-variable
typeset -U PATH
