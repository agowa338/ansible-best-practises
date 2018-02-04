#!/bin/sh

if [ ! -r '.vpass' ]; then
  exit 1
fi

tmp=`mktemp`
cat > $tmp

export PAGER='cat'

if grep -qF '$ANSIBLE_VAULT' $tmp; then
    ansible-vault view "$tmp" --vault-password-file=.vpass 2> /dev/null
else
  echo "Looks like one file was commited clear text"
  echo "Please fix this before continuing !"
  exit 1
fi

rm $tmp
