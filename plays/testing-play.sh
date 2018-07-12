#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT=$DIR/..
pushd $DIR
ansible-playbook -i $ROOT/testing.ini -vvvv --vault-password-file $ROOT/.vpass $DIR/play.yml
EXIT_CODE=$?
popd
exit $EXIT_CODE
