#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT=$DIR/..
pushd $DIR
$ROOT/extensions/setup/role_update.sh
ansible-playbook -i $ROOT/production.ini -vv --vault-password-file $ROOT/.vpass $DIR/examplePlay.yml
popd
