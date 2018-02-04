#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT_DIR=$(cd "$DIR/../../" && pwd)

if [ ! -r "$ROOT_DIR/.vpass" ]; then
  exit 1
fi

export PAGER='cat'
if grep -qF '$ANSIBLE_VAULT' $1; then
  CONTENT=`ansible-vault view "$1" --vault-password-file="$ROOT_DIR/.vpass"`
  echo "$CONTENT"
else
  cat "$1"
fi
