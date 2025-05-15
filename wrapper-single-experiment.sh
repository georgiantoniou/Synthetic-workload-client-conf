#!/bin/bash

# UTILIZATION="0.05 0.1 0.2 0.3 0.4 0.5"
UTILIZATION="0.2"
CORES="10"
# CORES="1 2 4 6 8 10"
# SERVICE_RATE="21505 10362 2014 1003 200 100"
# EXPECTED_SERVICE_RATE="20000 10000 2000 1000 200 100"
# SERVICE_RATE="200"
# EXPECTED_SERVICE_RATE="200"
SERVICE_RATE="21505 10362 2014 1003"
EXPECTED_SERVICE_RATE="20000 10000 2000 1000"
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

SERVICE_RATE="200"
EXPECTED_SERVICE_RATE="200"
DURATION=350

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

SERVICE_RATE="100"
EXPECTED_SERVICE_RATE="100"
DURATION=700

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