export EDITOR=vim
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
alias vim='nvim'
echo "Starting SE bastille installer.."
doas ./SE_bastille-installer/SE_bastille-installer
