#!/bin/bash

HOME_DIR=~/Synthetic-workload-client-conf/
SERVER_DEF_PATH=~/Synthetic-workload-client-conf/http_server_exp_busy_wait
SERVER_TIMER_PATH=~/Synthetic-workload-client-conf/http_server_exp_timer_busy_wait
CLIENT_PATH=~/Synthetic-workload-client-conf/wrk2/wrk
SERVER_NODE="node1"
SEED=1234

kill_proc ()
{
    sudo pkill -9 http_server_exp
    sudo pkill -9 mpstat
    sudo pkill -9 stap
    sudo pkill -9 socwatch
    sudo pkill -9 turbostat
}

run_server ()
{
    
    # Start server
    numactl --cpunodebind=1 --membind=1 sudo $1 $2 $3 $4 &> /dev/null &

    sleep 5

    # Check whether server has started
    res=$(ps -eo comm | grep http_server_exp | grep -v grep | wc -l)

    while [[ "$res" == "0" ]]; 
    do
        # Kill processes
        sudo pkill -9 http_server_exp
        
        # Start server
        numactl --cpunodebind=1 --membind=1 sudo $1 $2 $3 $4 &> /dev/null &

        sleep 5

        #Check whether server has started
        res=`ps -eo comm | grep http_server_exp | grep -v grep | wc -l`
        
    done
   
}

run_mpstat ()
{
    ((iteration=$1/10))
    numactl --cpunodebind=0 --membind=0 mpstat -P ALL 10 $iteration &> ~/mpstat.log &
}

run_systemtap_idle ()
{
     numactl --cpunodebind=0 --membind=0 sudo stap $HOME_DIR/idle.stp &> ~/systemtap_idle.log & 
}

run_socwatch_idle ()
{
     numactl --cpunodebind=0 --membind=0 sudo /opt/intel/oneapi/vtune/2025.1/socwatch/x64/socwatch -f cpu-cstate -m -r int -o socwatch -s 40 -t 10 &> /dev/null &
}

run_turbostat ()
{
    numactl --cpunodebind=0 --membind=0 sudo turbostat --interval 10 --quiet &> ~/turbostat.log &
}

if [[ -z $1 || -z $2 || -z $3 || -z $4 || -z $5 || -z $6 || -z $7 ]]; then 
    echo "Usage: ./wrapper-distribution.sh <threads> <connections> <utilization> <expected service time> <actual service time> <duration> <runs>"
    exit;
fi

THREADS=$1
CONNECTIONS=$2
QPS=$3
EXPECTED_SERVICE_RATE=$4
SERVICE_RATE=$5
duration=$6
runs=$7

echo "Experiment: "$THREADS"t-"$CONNECTIONS"c-"$QPS"u-"$EXPECTED_SERVICE_RATE"-"$SERVICE_RATE"-"$duration"s-"$runs

for (( i=1 ; i<=$runs ; i++ )); 
do
    # Create the experiment directory
    EXP_NAME=$THREADS"t-"$CONNECTIONS"c-"$QPS"u-"$EXPECTED_SERVICE_RATE"-"$SERVICE_RATE"-"$duration"s-"$i

    EXP_DIR=~/data/$EXP_NAME

    mkdir "$EXP_DIR"
    
    # Calculate arrival rate based on utilization and service rate
    queries=$(echo "" | awk -v a="$QPS" -v b="$EXPECTED_SERVICE_RATE" '{print int((1000000*a)/(1000000/b))}')
    ((queries=queries*THREADS))
    echo "$queries"

    # Start server
    run_server $SERVER_TIMER_PATH $SERVICE_RATE $THREADS $SEED

    # Start utilization
    run_mpstat $duration

    # # Start socwatch idle time monitoring
    run_socwatch_idle $SERVER_NODE

    # # Start turbostat idle time monitoring
    # run_turbostat $SERVER_NODE

    # Start systemtap idle time monitoring 
    # run_systemtap_idle

    # Start Client
    command="numactl --cpunodebind=0 --membind=0 $CLIENT_PATH -t$THREADS -c$CONNECTIONS -D exp -d"$duration"s -R$queries http://"$SERVER_NODE":8080"
    echo "$command"
    $command &> "$EXP_DIR/client.log"
            
    sleep 5

    # Check whether client has finished successfully
    res=`cat "$EXP_DIR/client.log" | grep "Latency" | wc -l`
            
    while [[ "$res" == "0" ]]; 
    do
        # Kill processes
        kill_proc
                
        # Start server
        run_server $SERVER_TIMER_PATH $SERVICE_RATE $THREADS $SEED

        # Start utilization
        run_mpstat $duration

        # # Start socwatch idle time monitoring
        run_socwatch_idle

        # # Start turbostat idle time monitoring
        # run_turbostat

        # Start systemtap idle time monitoring 
        # run_systemtap_idle

        # Start Client
        $command &> "$EXP_DIR/client.log"

        sleep 5

        # Check whether client has finished successfully
        res=`cat "$EXP_DIR/client.log" | grep "Latency" | wc -l`

    done

    # Kill processes
    kill_proc

    sleep 5

    # Move data to client
    sudo mv ~/mpstat.log "$EXP_DIR/"
    sudo mv ~/socwatch_trace.csv "$EXP_DIR/"
    sudo mv ~/turbostat.log "$EXP_DIR/"
    sudo mv ~/systemtap_idle.log "$EXP_DIR/"
    sudo mv ~/thread_* "$EXP_DIR/"

    sudo rm ~/mpstat.log
    sudo rm ~/socwatch*
    sudo rm ~/turbostat.log
    sudo rm ~/systemtap_idle.log
           
done