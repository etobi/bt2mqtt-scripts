#!/bin/bash

mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"

for arg; do
  cd $mydir
  action/xiaomi_mijia_ht.sh "$arg"
done
