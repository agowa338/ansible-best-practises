#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT=$DIR/..
pushd $DIR
ansible-playbook -i $ROOT/development.ini -vvvv --check --step --vault-password-file $ROOT/.vpass $DIR/play.yml
EXIT_CODE=$?
popd
exit $EXIT_CODE
