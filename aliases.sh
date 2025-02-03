#!/usr/bin/env sh

alias d='docker'

alias dcom='docker compose'
alias dcom-b='docker compose build'
alias dcom-d='docker compose down'
alias dcom-d-rmia='docker compose down --rmi all'
alias dcom-d-v='docker compose down --volumes'
alias dcom-e='docker compose exec'
alias dcom-l='docker compose ls'
alias dcom-ls='docker compose ls'
alias dcom-p='docker compose ps'
alias dcom-ps='docker compose ps'
alias dcom-u='docker compose up'
alias dcom-i='docker compose images'

alias dimg='docker image'
alias dimg-l='docker image ls'
alias dimg-ls='docker image ls'
alias dimg-rma='docker image rm -f $(docker image ls -q)'

alias dcon='docker container'
alias dcon-l='docker container ls'
alias dcon-ls='docker container ls'
alias dcon-la='docker container ls -a'
alias dcon-rm='docker container rm'
alias dcon-rma='docker container rm -f $(docker container ls -a -q)'

alias dvol='docker volume'

alias dnet='docker network'
