export VISUAL=vim
export EDITOR="$VISUAL"

# Docker
alias d="docker"
alias dm="docker-machine"
alias dc="docker compose"
alias dp="docker ps --format '{{.Names}}\t{{.Ports}}\t{{.Status}}\t{{.Image}}'"

alias gwgrep='grep --color=auto --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=docker_node_modules_cache'
alias gg="gwgrep"
