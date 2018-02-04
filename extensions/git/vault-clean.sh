#!/bin/sh

if [ ! -r '.vpass' ]; then
  exit 1
fi

tmp=`mktemp`
cat > $tmp

ansible-vault encrypt $tmp --vault-password-file=.vpass > /dev/null 2>&1

cat "$tmp"
rm $tmp
