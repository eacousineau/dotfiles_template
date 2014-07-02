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
ln $ln_flags -s ~+/$file ~/.$file

echo "[ bash_completion ]"
file=bash_completion
ln $ln_flags -s ~+/$file ~/.$file

echo "[ inputrc ]"
file=inputrc
ln $ln_flags -s ~+/$file ~/.$file

echo "[ git ]"
if ! which git ; then
    sudo apt-get install git
fi

echo "[ git-aware-prompt ]"
if [[ ! -d ~/.bash/git-aware-prompt ]]; then
    dir=~/.bash
    (
        mkdir -p $dir && cd $dir
        git clone https://github.com/eacousineau/git-aware-prompt.git
    )
fi

echo "[ gitconfig ]"
file=gitconfig
ln $ln_flags -s ~+/$file ~/.$file

echo "[ gitignore ]"
dir=~/.config/git
file=gitignore
mkdir -p $dir
ln $ln_flags -s {~+,$dir}/$file
git config --global core.excludesFile "$dir/$file"
