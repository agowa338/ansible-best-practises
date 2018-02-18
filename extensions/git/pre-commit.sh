#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT_DIR=$(cd "$DIR/../../" && pwd)
EXTERNAL_ROLE_DIR="$ROOT_DIR/roles/external"
ROLES_REQUIREMNTS_FILE="$ROOT_DIR/roles/roles_requirements.yml"

git_diff_command_output=$(git diff --name-only --staged $ROLES_REQUIREMNTS_FILE 2>&1)
git_diff_exit_code=$?
git_diff_command_output_lines=$(echo $git_diff_command_output | wc -l )

if [ $git_diff_exit_code -eq 128 ]
then
    : # do nothing, requirements file does not exist
elif [ $git_diff_exit_code -eq 0 ] && [ $git_diff_command_output_lines -gt 0 ]
then
    $ROOT_DIR/extensions/setup/role_update.sh
elif [ $git_diff_exit_code -eq 0 ]
then
    : # no new module
else
    # unknown error
    exit $git_diff_exit_code
fi
exit 0
