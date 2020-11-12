#!/bin/sh

InstallJq() {
    if uname -a | grep Darwin > /dev/null 2>&1; then
        echo "Checking For JQ: MacOS"
        command -v jq >/dev/null 2>&1 || HOMEBREW_NO_AUTO_UPDATE=1 brew install jq --quiet
        return $?

    elif grep Debian < /etc/issue > /dev/null 2>&1 || grep Ubuntu < /etc/issue > /dev/null 2>&1; then
        echo "Checking For JQ: Debian"
        if [ "$(id -u)" = 0 ]; then export SUDO=""; else # Check if we're root
            export SUDO="sudo";
        fi
        command -v jq >/dev/null 2>&1 || { $SUDO apt -qq update && $SUDO apt -qq install -y jq; }
        return $?

    elif grep Alpine < /etc/issue > /dev/null 2>&1; then
        echo "Checking For JQ: Alpine"
        command -v jq >/dev/null 2>&1 || { echo >&2 "VAULT ORB ERROR: JQ is required. Please install"; exit 1; }
        return $?
    fi
}

print_circleci_auth_nonce() {
    InstallJq
    vault write -format=json "auth/$PARAM_PATH/nonce" build_num="$CIRCLE_BUILD_NUM" | jq '.data | {nonce: .nonce}'
}

ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" = "$0" ]; then
    print_circleci_auth_nonce
fi
