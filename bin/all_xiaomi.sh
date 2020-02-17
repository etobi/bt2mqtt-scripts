#!/bin/bash

mqtthost="$1"
shift

mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
cd $mydir

for arg; do
  ./action/xiaomi_mijia_ht.sh "$mqtthost" "$arg"
done
