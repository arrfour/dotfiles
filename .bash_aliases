alias gti='git'
alias tmux='tmux -2'
alias less='less -R'
alias diff='colordiff'
alias dc='cd'
alias yams='find . -type f -name "*.yml*" | sed "s|\./||g" | egrep -v "(\.kitchen/|\[warning\]|\.molecule/)" | xargs yamllint -f parsable'
alias glog='git log --oneline --graph --color --all --decorate'
# alias ll='ls -alh' currently defined in .bashrc
alias pip-upgrade="pip freeze --user | cut -d'=' -f1 | xargs -n1 pip install -U"

