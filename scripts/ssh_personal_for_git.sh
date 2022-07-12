#!/bin/bash
set -eu

# Setup
#   ssh-keygen -f ~/.ssh/id_rsa_github_personal.pem
#   xcopy < ~/.ssh/id_rsa_github_personal.pem.pub
#
# Usage (via bash aliases)
#   use-personal-git
#
# See also: https://gist.github.com/eacousineau/0642866e7acc0f396383b3b1c29c6362

pem_github_personal=~/.ssh/id_rsa_github_personal.pem
exec ssh -i ${pem_github_personal} "$@"
