#!/bin/bash

pgrep ibbq.sh
exit_status=$?
if [[ ${exit_status} -eq 0 ]]; then
  echo "already running"
  exit
fi

coproc bluetoothctl
echo -e 'scan on\n' >&${COPROC[1]}
sleep 5
echo -e 'devices\nexit\n' >&${COPROC[1]}
IFS= read -d '' output <&${COPROC[0]}
ibbq=$(echo -e "$output" | egrep "^Device" | grep iBBQ | cut -c 8-24)

if [[ "$ibbq" != "" ]]; then
  echo "start ibbq"
  ibbq.sh "$ibbq"
fi
