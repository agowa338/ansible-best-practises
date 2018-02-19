#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT_DIR=$(cd "$DIR/../../" && pwd)

if ! git lfs install
then
    wget https://github.com/git-lfs/git-lfs/releases/download/v2.3.4/git-lfs-linux-amd64-2.3.4.tar.gz
    gunzip git-lfs-linux-amd64-2.3.4.tar.gz
    tar -xf git-lfs-linux-amd64-2.3.4.tar
    cd git-lfs-2.3.4
    ./install.sh
    cd ..
    git lfs install
fi

git --version
ln -Pf $ROOT_DIR/extensions/git/* $ROOT_DIR/.git/hooks
git config diff.vault.textconv ./.git/hooks/vault-diff.sh
git config filter.vault.smudge ./.git/hooks/vault-smudge.sh smudge
git config filter.vault.clean ./.git/hooks/vault-clean.sh clean
git config filter.vault.required true
git config diff.vault.cachetextconv false
