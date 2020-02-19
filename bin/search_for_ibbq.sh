#!/bin/bash

mqtthost="$1"
shift

mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
cd $mydir

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

pgrep ibbq.sh
exit_status=$?
if [[ ${exit_status} -eq 0 ]]; then
  echo "already running"
  exit
fi

if [[ "$ibbq" != "" ]]; then
  echo "start ibbq"
  ./action/ibbq.sh "$mqtthost" "$ibbq"
fi
