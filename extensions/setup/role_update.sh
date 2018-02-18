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

# Check roles req file 
[[ ! -f "$ROLES_REQUIREMNTS_FILE" ]]  && msg_exit "roles_requirements '$ROLES_REQUIREMNTS_FILE' does not exist or permssion issue.\nPlease check and rerun."

remove_external_roles() {
    # Remove existing external roles
    if [ -d "$EXTERNAL_ROLE_DIR" ]
    then
        pushd "$EXTERNAL_ROLE_DIR" > /dev/null
        if [ "$(pwd)" == "$EXTERNAL_ROLE_DIR" ]
        then
            echo "Removing current roles in '$EXTERNAL_ROLE_DIR/*'"
            rm -rf *
            git clean -xddff "$EXTERNAL_ROLE_DIR"
            git checkout "$EXTERNAL_ROLE_DIR"
        else
            msg_exit "Path error could not change dir to $EXTERNAL_ROLE_DIR"
        fi
        popd > /dev/null
    fi
}

update_with_galaxy() {
    # Install roles
    ansible-galaxy install -r "$ROLES_REQUIREMNTS_FILE" --force --no-deps -p "$EXTERNAL_ROLE_DIR"
}

update_with_git_submodule() {
    pushd "$ROOT_DIR" > /dev/null
    python2 $ROOT_DIR/extensions/setup/ansiblegalaxygitsubmodule.py
    popd > /dev/null
}

# Check if git submodule or ansible-galaxy should be used.
# The requirements file is written into git submodules using a pre-commit hook (which invokes this script)
remove_external_roles
update_with_git_submodule

#if [[ -z "$(which ansible-galaxy)" ]]
#then
#    remove_external_roles
#    update_with_galaxy
#else
#    msg_exit "Ansible-galaxy can be used for initialization of your external roles.\nExternal roles are not initialized!"
#fi
