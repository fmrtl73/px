#!/bin/bash
cp /pre_flight_checks.sh /host/tmp/
nsenter -t 1 -m -u -n -i /tmp/pre_flight_checks.sh

