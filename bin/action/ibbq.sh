#!/bin/bash

mqtthost="$1"
ibbqadress="$2"

basetopic="ibbq/probe/"

publish() {
  local probe value
  probe=$1
  read value
  # echo $probe : $value
  /usr/bin/mosquitto_pub -h ${mqtthost} -t "${basetopic}${probe}" -m "${value}"
}
export -f publish

parse_temp() {
  local probe value
  read value
  if [[ "$value" == "fff6" ]]; then
    # skip not-connected probe
    exit
  fi
  temp_raw=$(echo "ibase=16; ${value^^}" | bc)
  temp_dec=$(echo "scale=1; ${temp_raw} / 10" | bc)
  echo "${temp_dec}"
}
export -f parse_temp

parse_notification() {
  local input value0 value1 value2 value3 value4 value5 value6 value7 value8 value9 value10 value11
  read input
  handle=$(echo $input | cut -c23-28)
  if [[ "$handle" == "0x0030" ]]; then
    value0=$(echo $input | cut -c37-38)
    value1=$(echo $input | cut -c40-41)
    value2=$(echo $input | cut -c43-44)
    value3=$(echo $input | cut -c46-47)
    value4=$(echo $input | cut -c49-50)
    value5=$(echo $input | cut -c52-53)
    value6=$(echo $input | cut -c55-56)
    value7=$(echo $input | cut -c58-59)
    value8=$(echo $input | cut -c61-62)
    value9=$(echo $input | cut -c64-65)
    value10=$(echo $input | cut -c67-68)
    value11=$(echo $input | cut -c70-71)
    echo "$value1$value0" | parse_temp | publish 1
    echo "$value3$value2" | parse_temp | publish 2
    echo "$value5$value4" | parse_temp | publish 3
    echo "$value7$value6" | parse_temp | publish 4
    echo "$value9$value8" | parse_temp | publish 5
    echo "$value11$value10" | parse_temp | publish 6
  fi
}
export -f parse_notification

echo "connect ibbq"
gatttool -b "${ibbqadress}" --char-write-req --handle=0x0029 --value=2107060504030201b8220000000000
exit_status=$?
if [ $exit_status -eq 1 ]; then
  echo 'offline' | publish 'status'
  exit 1
fi
sleep 1

echo "subscribe"
gatttool -b "${ibbqadress}" --char-write-req --handle=0x0031 --value=0100
exit_status=$?
if [ $exit_status -eq 1 ]; then
  echo 'offline' | publish 'status'
  exit 2
fi
sleep 1

echo "get notifications"
while IFS= read -r -t 10 newline; do
    echo 'online' | publish 'status'
    echo $newline |
  grep "Notification handle = 0x0030" |
  parse_notification; done < <(
    gatttool -b "${ibbqadress}" --char-write-req --handle=0x0034 --value=0b0100000000 --listen
  )

echo 'offline' | publish 'status'
