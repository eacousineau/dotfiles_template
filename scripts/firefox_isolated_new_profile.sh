#!/bin/bash
shopt -s expand_aliases

# Related articles:
# - https://developer.mozilla.org/en-US/docs/Mozilla/QA/Desktop_Firefox_Reporting_and_Writing_Good_Bugs#all
# - https://support.mozilla.org/en-US/kb/troubleshoot-firefox-issues-using-safe-mode
# - https://cat-in-136.github.io/2012/12/tip-how-to-run-new-firefox-instance-w.html

alias env-isolate='env -i HOME=$HOME DISPLAY=$DISPLAY SHELL=$SHELL TERM=$TERM USER=$USER PATH=/usr/local/bin:/usr/bin:/bin _ISOLATED=1'
alias bash-isolate='env-isolate bash --norc'

if [[ -z ${_ISOLATED} ]]; then
    # N.B. `exec <alias>` does not work with current options.
    bash-isolate ${BASH_SOURCE}
    exit $?
fi

# Create new temporary directory.
cd $(mktemp -d --suffix=firefox-profile)

# Avoid dbus errors.
mkdir fake_home
export HOME=${PWD}/fake_home

# Show environment.
env

# Launch firefox.
firefox -profile ${PWD} -no-remote -new-instance
