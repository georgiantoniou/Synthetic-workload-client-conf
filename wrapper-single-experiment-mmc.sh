#!/bin/bash

UTILIZATION="0.001" # 0.1 0.2 0.3 0.4 0.5"
CORES="1 2 4 6 8 10"
CONNECTIONS="1 4 8 12 16 20"
SERVICE_RATE="12500 10000 2000 1000 200 100"
EXPECTED_SERVICE_RATE="12500 10000 2000 1000 200 100"
DURATION=140
RUNS=2

for util in $UTILIZATION;
do
    k=0
    for core in $CORES;
    do
        ((k=k+1))
        j=1
        for service in $SERVICE_RATE;
        do
            expected_service=$(echo "$EXPECTED_SERVICE_RATE"| awk -v a="$j" '{print $a}')
            echo "$service $expected_service"
            connections=$(echo "$CONNECTIONS"| awk -v a="$k" '{print $a}')
            echo "$connections"
            ~/Synthetic-workload-client-conf/run-single-experiment-mmc.sh $core $connections $util $expected_service $service $DURATION $RUNS
            ((j=j+1))
        done
    done
done


