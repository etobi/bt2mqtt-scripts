#!/bin/bash

address="$1"
sensorname="$2"
basetopic="mijia/"
mqtthost="localhost"

echo "get data from sensor"
RET=1
until [ ${RET} -eq 0 ]; do
echo -n '.'
  data=$(
    /usr/bin/timeout 20 \
      /usr/bin/gatttool -b $address --char-write-req --handle=0x10 -n 0100 --listen | \
      grep "Notification handle" -m 2
  )
  RET=$?
  sleep 1
done

echo "get battery data from sensor"
RET=1
until [ ${RET} -eq 0 ]; do
echo -n '.'
  batteryData=$(
    /usr/bin/gatttool -b $address --char-read --handle=0x18 | \
      cut -c 34-35
  )
  RET=$?
  sleep 1
done

# process data received from sensorname 1
valueTemp=$(echo $data | tail -1 | cut -c 42-54 | xxd -r -p)
valueHumidity=$(echo $data | tail -1 | cut -c 64-74 | xxd -r -p)
valueBattery=$(echo "ibase=16; ${batteryData^^}" | bc)

echo "valueTemp=" $valueTemp
echo "valueHumidity=" $valueHumidity
echo "valueBattery=" $valueBattery

publish() {
  local name value
  name=$1
  value=$2
  /usr/bin/mosquitto_pub -h ${mqtthost} -t "${basetopic}${name}" -m "${value}"
}
export -f publish

publish "${sensorname}/temp" "${valueTemp}"
publish "${sensorname}/humidity" "${valueHumidity}"
publish "${sensorname}/battery" "${valueBattery}"
