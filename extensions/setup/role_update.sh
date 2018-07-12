#!/bin/bash
set -e
#TODO: Support python virtual environments for now global

COLOR_END='\e[0m'
COLOR_RED='\e[0;31m'

# This current directory.
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT_DIR=$(cd "$DIR/../../" && pwd)
EXTERNAL_ROLE_DIR="$ROOT_DIR/roles/external"
ROLES_REQUIREMNTS_FILE="$ROOT_DIR/roles/roles_requirements.yml"

# Exit msg
msg_exit() {
    printf "$COLOR_RED$@$COLOR_END"
    printf "\n"
    printf "Exiting...\n"
    exit 1
}

# Trap if ansible-galaxy failed and warn user
cleanup() {
    msg_exit "Update failed. Please don't commit or push roles till you fix the issue"
}
trap "cleanup"  ERR INT TERM

remove_external_roles() {
    git submodule deinit --all --force
}

update_with_git_submodule() {
    git submodule update --init --recursive --remote
    git submodule sync --recursive
}

remove_external_roles
update_with_git_submodule
