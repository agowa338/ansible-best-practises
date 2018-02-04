#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT_DIR=$(cd "$DIR/../../" && pwd)

git config diff.vault.textconv ./extensions/git/vault-diff.sh
git config filter.vault.smudge ./extensions/git/vault-smudge.sh smudge
git config filter.vault.clean ./extensions/git/vault-clean.sh clean
git config filter.vault.required true
git config diff.vault.cachetextconv false
