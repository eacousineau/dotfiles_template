#!/bin/bash
set -e -u

ln_flags=
while [[ $# -gt 0 ]]; do
    case $1 in
    -f | --force)
        echo "Force Link Overwrite!"
        ln_flags=-f
        ;;
    *)
        echo "Invalid option: $1" >&2
        exit 0
    esac
    shift
done

if [[ -z "$ln_flags" ]]; then
    echo "NOTE: If these files already exist and you wish to overwrite, use the --force flag"
fi

cd $(dirname $BASH_SOURCE)

echo "[ bash_aliases ]"
file=bash_aliases
ln $ln_flags -s ~+/$file ~/.$file || echo "skip"

echo "[ bash_completion ]"
file=bash_completion
ln $ln_flags -s ~+/$file ~/.$file || echo "skip"

echo "[ inputrc ]"
file=inputrc
ln $ln_flags -s ~+/$file ~/.$file || echo "skip"

echo "[ git ]"
if ! which git ; then
    sudo apt-get install git || echo "skip"
fi

echo "[ git-aware-prompt ]"
if [[ ! -d ~/.bash/git-aware-prompt ]]; then
    dir=~/.bash
    (
        mkdir -p $dir && cd $dir
        git clone https://github.com/eacousineau/git-aware-prompt.git
    ) || echo "skip"
fi

echo "[ git-util ]"
if [[ ! -d ~/.bash/git-util ]]; then
    dir=~/.bash
    (
        mkdir -p $dir && cd $dir
        git clone https://github.com/eacousineau/util.git git-util
        cd git-util
        mkdir -p ~/.local/bin
        ./install ~/.local/bin
    ) || echo "skip"
fi

echo "[ gitconfig ]"
file=gitconfig
ln $ln_flags -s ~+/$file ~/.$file || echo "skip"

echo "[ gitignore ]"
dir=~/.config/git
file=gitignore
mkdir -p $dir
ln $ln_flags -s {~+,$dir}/$file || echo "skip"
git config --global core.excludesFile "$dir/$file"

echo "[ bazelrc ]"
file=bazelrc
ln $ln_flags -s ~+/$file ~/.$file || echo "skip"

echo "[ tigrc ]"
file=tigrc
ln $ln_flags -s ~+/$file ~/.$file || echo "skip"

echo "[ gdbinit ]"
file=gdbinit
ln $ln_flags -s ~+/$file ~/.$file || echo "skip"

# Make it explicit for now.
# echo "[ tmux ]"
# file=tmux.conf
# ln $ln_flags -s ~+/$file ~/.$file || echo "skip"

echo "[ autostart ]"
mkdir -p ~/.config/autostart
ln $ln_flags -s ~+/etc/autostart/nm-applet.desktop ~/.config/autostart/ || echo "skip"
ln $ln_flags -s ~+/etc/autostart/barrier.desktop ~/.config/autostart/ || echo "skip"

echo "[ other binaries ]"
ln $ln_flags -s ~+/scripts/git_remote_export.py ~/.local/bin/ || echo "skip"
ln $ln_flags -s ~+/scripts/no_touchpad.sh ~/.local/bin/ || echo "skip"
ln $ln_flags -s ~+/scripts/bazel_hash_and_cache.py ~/.local/bin/ || echo "skip"
ln $ln_flags -s ~+/scripts/firefox_isolated_new_profile.sh ~/.local/bin/ || echo "skip"
