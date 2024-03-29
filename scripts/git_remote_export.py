#!/usr/bin/env python3

import argparse

import pyperclip

import shell_defs as defs


def remote_key(remote):
    priority = 2
    if remote == "origin":
        priority = 0
    elif remote == "upstream":
        priority = 1
    return (priority, remote)


def main():
    cmds = []
    remotes = defs.subshell("git remote").split()
    remotes.sort(key=remote_key)
    for remote in remotes:
        fetch = defs.subshell(f"git config remote.{remote}.url")
        push = defs.subshell(f"git config remote.{remote}.pushurl", check=False)
        cmds.append(f"git remote add {remote} {fetch}")
        if len(push) > 0 and fetch != push:
            cmds.append(f"  git config remote.{remote}.pushurl {push}")

    text = "\n".join(cmds)
    print("[ Copied to clipboard ]")
    print(text)
    pyperclip.copy(text)


assert __name__ == "__main__"
main()
