#!/bin/bash

# http://musescore.org/en/node/25277#comment-98902
mkcd() {
	# Separate arguments so that -p can be used
	mkdir "$@" && cd "${!#}"
}

alias env-isolate='env -i HOME=$HOME DISPLAY=$DISPLAY SHELL=$SHELL TERM=$TERM USER=$USER PATH=/usr/local/bin:/usr/bin:/bin'
alias bash-isolate='env-isolate bash --norc'

# Set up things for prefix
export-prepend ()
{
    eval "export $1=\"$2:\$$1\""
}
fhs-extend()
{
    local python_version=3.6
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "fhs-extend [--python-version <VERSION>] <PREFIX>"
                return;;
            --python-version)
                python_version=$1
                shift;;
            *)
                break;;
        esac
    done
    local prefix=${1%/}
    export-prepend PYTHONPATH $prefix/lib:$prefix/lib/python${python_version}/dist-packages:$prefix/lib/python${python_version}/site-packages
    export-prepend PATH $prefix/bin
    export-prepend LD_LIBRARY_PATH $prefix/lib
    export-prepend PKG_CONFIG_PATH $prefix/lib/pkgconfig:$prefix/share/pkgconfig
    echo "[ FHS Environment extended: ${prefix} ]"
    # MAN path?
    export-prepend MANPATH $prefix/share/man
}

fhs-clear() {
    export LD_LIBRARY_PATH=
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
    export PYTHONPATH=
    export PKG_CONFIG_PATH=
    echo "[ FHS Environment reset ]"
}

_ssh-display-env() {
    # See README about capturing this shit
    env DISPLAY=${_SSH_DISPLAY:-${DISPLAY}} "$@"
}

xcopy() {
    _ssh-display-env xclip -i -sel clipboard
    echo "[ Clipboard ]"
    echo "$(xclip -o -sel clipboard)"
}
alias copy="xcopy"
xpaste() {
    _ssh-display-env xclip -o -sel clipboard
}

# Useful for getting full file paths in conjunction with expansion of ~+ (you get tab complete as well)
ecopy() {
	echo -n $@ | xcopy
}

# Home-escaped copy
hecopy() {
	echo -n "$@" | sed "s#^$HOME#~#g" | xcopy
}

alias open='gnome-open'

# export -f grepf
# Min-grep - ignore binaries and git directories for better speed
grepm() {
	grep -rnI --exclude-dir=.git --exclude-dir='build*' --exclude-dir='*-build' --exclude-dir='bazel-*' "$@"
}

# For finding out what object file has a symbol defined - to be run from the build directory
nm-grep() {
	find . -name '*.o' | xarg bash -c "echo \$1 && nm -C \$1 | grep --color=always '$@'" _
	find . -name '*.so' | xarg bash -c "echo \$1 && objdump -T \$1 | c++filt | grep --color=always '$@'" _
}

symlink-replace() {
	local sym="$1" orig=
	test ! -L $1 && { eecho "Not a symlink: $1" && return 1; }
	orig="$(readlink -f "$sym")"
	rm "$sym"
	echo "Copied '$orig' to '$sym'"
	cp "$orig" "$sym"
}

# Taken from git-sh-setup
# Find a way to source this file, finding the libexec dir?
# Can just do . git-sh-setup -- will it have too much extra stuff?
die () {
	die_with_status 1 "$@"
}

die_with_status () {
	status=$1
	shift
	eecho "$*"
	exit "$status"
}

# Echo to stderr
eecho() {
	echo >&2 "$*"
}

alias historyn="history | sed 's/^[ ]*[0-9]\+[ ]*//'"
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

minimal-prompt() {
	PROMPT_COMMAND=""
	export PS1="$ "
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

# Return relative path of $1 with respect to $2
rel_path() {
    python -c "import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" $1 $2
}

symlink-make-rel() { (
    # NOTE: Use `ln -sr ...` in git-new-workdir from now on
    # Relink using ln -srfT
    set -e -u
    path=${1-.}
    local links=$(find ${path} -type l)
    for link in $links; do
        local link_deref=$(readlink -f $link)
        if [[ -f "${link_deref}" ]]; then
            set -x
            ln -srfT $link_deref $link
            set +x
        fi
    done
) }

git-ref()
{
    use_remote=
    if [[ "$1" == "-r" ]]; then
        use_remote=1
        shift
    fi
    local file="$1"
    # Get repo basename, git file's path, and the sha associated with the file
    repo="$(cd "$(dirname "$file")" && git rev-parse --show-toplevel)"
    rel="$(rel_path $file $repo)"
    if [[ -n "$use_remote" ]]; then
        name="$(git config remote.${REMOTE-origin}.url)"
    else
        name="$(basename $repo)"
    fi
    echo "$name:$(git rev-parse --short HEAD):$rel"
}


git-no-prune-merge() { (
    set -eux
    ref="$@"
    git checkout no_prune
    git merge --no-ff --strategy=ours ${ref} \
        -m "No-prune merge (with --strategy=ours) of ${ref}"
    git checkout -
) }

mp4-to-gif() { (
    set -eux
    base=$1
    ffmpeg -i ${base}.mp4 -vf "fps=30,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 ${base}.gif
) }


git-path-spec()
{ (
    local path=$(realpath $1)
    cd $(dirname $path)
    local worktree=$(git rev-parse --show-toplevel)
    local repo=$(basename $worktree)
    # local repo=$(basename $(git config remote.origin.url) .git) # ???
    local sha=$(git ref)
    local branch=$(git bg)
    local rel=$(rel_path $path $worktree)
    # short
    echo "${repo}:${sha}:${rel} (${branch})"
    # long
    echo -e "\nrepo: {name: ${repo}, sha: ${sha}, branch: ${branch}}\nfiles:\n- file: ${rel}"
) }

github-shorturl() {
    # https://github.com/blog/985-git-io-github-url-shortener
    local url=${1-}
    if [[ -z $1 ]]; then
        url="$(xclip -o)"
        echo "(From clipboard)" >&2
    fi
    local shorturl="$(curl -s -i https://git.io -F "url=$url" | grep 'Location: ' | sed 's#Location: ##g')" # 2> /dev/null)"
    ecopy $shorturl
}

git-log-for-rebase() { (
    # For multi-PR stuff
    # @ref http://stackoverflow.com/a/24074652/7829525
    # Example:
    #    $ git-log-for-rebase pr2-wip-start pr3-wip
    set -e -u -x
    wip_base=${1}
    wip_new=${2}
    git log --format='pick %h %s' --reverse ${wip_base}..${wip_new}
) }

create-notebook() { (
    set -eux
    cat > "$1" <<'EOF'
{
 "cells": [],
 "metadata": {},
 "nbformat": 4,
 "nbformat_minor": 2
}
EOF
) }
