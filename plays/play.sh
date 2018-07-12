#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT=$DIR/..

## Import ssh host keys
[ -d $HOME/.ssh ] || mkdir -p $HOME/.ssh
[ -a $HOME/.ssh/known_hosts ] || touch $HOME/.ssh/known_hosts
chmod 644 $HOME/.ssh/known_hosts
# Adopt the following example line for all your hosts inside your environment, or you won't be able to
# securely deploy to all your servers (without having connected manually and accepted the ssh public key first).
# These commands should be included for multiple reasons:
#   1. New team members do not need to connect to every host and accept the key themself.
#   2. CI-Pipeline has an empty known_hosts and become stuck without it.
# Alternatively you could tell ssh to not validate the remote host, but that opens you up for MITM-Attacks and is very insecure.
# The 1st part of the following command just contains the hostname `'examplePlay000.prod.example.com'` for lookup inside of the known_hosts file.
# The 2nd part is a simple copy and paste from your own known_hosts file, which contains the hostname, the ip and the hosts public ssh key.
#grep -q -F 'examplePlay000.prod.example.com' $HOME/.ssh/known_hosts | echo 'examplePlay000.prod.example.com,10.0.0.1 ecdsa-sha2-nistp256 (...)' >> $HOME/.ssh/known_hosts



pushd $DIR

## Don't perform a role_update if we're inside a docker container/ci-pipeline.
## GitLab should already have checked out all submodules in the version that should be deployed.
## If we would update external modules there, it would either fail (if internal repositories are included)
## or we would have a non predictable state. If you want to repeat an older run to revert the environment,
## it could happen, that the external roles are updated, but we want to apply the older state.
[ -v isDocker ] || $ROOT/extensions/setup/role_update.sh
EXIT_CODE=-1
if [ -a $ROOT/.ssh.vpass ]
then
    ansible-playbook -i $ROOT/production.ini -vv --vault-password-file $ROOT/.vpass --private-key $ROOT/.ssh.vpass $DIR/play.yml
else
    ansible-playbook -i $ROOT/production.ini -vv --vault-password-file $ROOT/.vpass $DIR/play.yml
fi
EXIT_CODE=$?

popd
exit $EXIT_CODE
