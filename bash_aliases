#!/bin/bash

export DOTFILES="$(dirname "$(readlink -f "$BASH_SOURCE")")"

personal-setup()
{
	source $DOTFILES/etc/functions.sh
	source $DOTFILES/etc/specific_functions.sh

	alias b="source ~/.bash_aliases"
	alias bash-isolate='env -i HOME=$HOME DISPLAY=$DISPLAY SHELL=$SHELL TERM=$TERM USER=$USER bash --norc'

	git-aware
	short-git-prompt
}

# <action>
personal-setup
