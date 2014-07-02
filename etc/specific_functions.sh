#!/bin/bash

# @brief Simple aliases

alias ll='ls -AlF'

sfe()
{
	for d in $(find . -mindepth 1 -maxdepth 1 -type d)
	do
		( cd $d; eval "$@"; )
	done
}

git-aware() {
	export GITAWAREPROMPT=~/.bash/git-aware-prompt
	# From: https://github.com/jimeh/git-aware-prompt (mentioned by Dane in Confluence)
	# This solution doesn't screw up bash's ability to count characters so you don't get weird line wrapping when editing old lines
	source $GITAWAREPROMPT/main.sh
	export PS1="\[$bldgrn\]\u@\h\[$bldblu\] \w\[$bldylw\]\$git_branch\[$txtcyn\]\$git_dirty\[$txtrst\]\$ "

	short-git-prompt() {
		short-git-cmd() {
			my_host=workstation
			my_dir="$(basename "$PWD")"
		}
		PROMPT_COMMAND="find_git_branch; find_git_dirty; short-git-cmd"
		export PS1="\[$txtcyn\]\$my_dir\[$bldylw\]\$git_branch\[$txtcyn\]\$git_dirty\[$txtrst\]\$ "
	}
}

git-full-clone()
{
    (
    set -e -u
    repo="$1"
    dir="$(basename "$repo" .git)"

    git clone "$repo" "$dir"
    cd $dir
    git sfe -t -r 'git sube set-url super && yes | git sube refresh -T --no-sync --reset'

    remote=local
    git remote add $remote "$(git config remote.origin.url)"
    git checkout -- .gitmodules
    git sube set-url -r --remote origin repo -g
    git sube set-url -r --remote $remote super
    )
}

