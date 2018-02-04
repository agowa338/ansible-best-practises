#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT=$DIR/..
pushd $DIR
ansible-playbook -i $ROOT/testing.ini -vvvv --check --vault-password-file $ROOT/.vpass $DIR/examplePlay.yml
popd
