#!/bin/bash

UTILIZATION="0.05 0.1 0.2 0.3 0.4 0.5"
CORES="1 2 4 6 8 10"
SERVICE_RATE="13514 10752 2087 1039 208 103"
EXPECTED_SERVICE_RATE="12500 10000 2000 1000 200 100"
DURATION=140
RUNS=3

for util in $UTILIZATION;
do
    for core in $CORES;
    do
        j=1
        for service in $SERVICE_RATE;
        do
            expected_service=$(echo "$EXPECTED_SERVICE_RATE"| awk -v a="$j" '{print $a}')
            echo "$service $expected_service"
            ~/Synthetic-workload-client-conf/run-single-experiment.sh $core $core $util $expected_service $service $DURATION $RUNS
            ((j=j+1))
        done
    done
done


