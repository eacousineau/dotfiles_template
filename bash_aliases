#!/bin/bash

personal-setup()
{
    export _DOTFILES=$(cd $(dirname $(readlink -f ${BASH_SOURCE})) && pwd)
    source ${_DOTFILES}/etc/functions.sh

    alias b="source ~/.bash_aliases"

    # Multiline history.
    shopt -s cmdhist
    shopt -s lithist
    # Less annoying globs.
    shopt -s globstar

    git-aware
    short-git-prompt

    # Yuhhh! https://github.com/elephantrobotics/mycobot_ros/issues/17#issuecomment-837668745
    export PIP_REQUIRE_VIRTUALENV=1

    personal-tmux() {
        # Split off so I can still use default stuff on tty on shared machine.
        env _PERSONAL=1 tmux -f ${_DOTFILES}/tmux.conf
    }

    personal-ssh-env() {
        if [[ ! -v _SSH_DISPLAY && -v DISPLAY ]]; then
            export _SSH_DISPLAY=${DISPLAY}
            echo "Using redirect _SSH_DISPLAY=${_SSH_DISPLAY}"
        fi
        export DISPLAY=:1
        export EDITOR=vim
    }

    cuda-11.5-setup() {
        # https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=20.04&target_type=deb_network
        # But do NOT run `install cuda`. Instead:
        #   sudo apt install cuda-compiler-11-5 cuda-libraries-dev-11-5 cuda-command-line-tools-11-5
        #   sudo apt install libcudnn8-dev
        export CUDA_ROOT=/usr/local/cuda-11.5
        export CUDA_INC_DIR=${CUDA_ROOT}/include
        export PATH=${CUDA_ROOT}/bin:${PATH}
        export LD_LIBRARY_PATH=${CUDA_ROOT}/lib64:${LD_LIBRARY_PATH}
    }

    use-personal-git() {
        export GIT_AUTHOR_EMAIL=someone@somewhere
        export GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL}
        export GIT_SSH=${_DOTFILES}/scripts/ssh_personal_for_git.sh
        export PS1="personal!$ "
    }
}

# <action>
personal-setup
