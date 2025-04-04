#!/bin/bash

HOME_DIR=~/Synthetic-workload-client-conf/
SERVER_DEF_PATH=~/Synthetic-workload-client-conf/http_server_exp_busy_wait
SERVER_TIMER_PATH=~/Synthetic-workload-client-conf/http_server_exp_timer_busy_wait
CLIENT_PATH=~/Synthetic-workload-client-conf/wrk2/wrk
SERVER_NODE="node1"
SEED=1234
QPS="300"
queries="300"
# SERVICE_RATE="100000 10000 1000 100"
SERVICE_RATE="1000 100"
CONNECTIONS=10
THREADS=10

kill_proc ()
{
    ssh ganton12@$1 "sudo pkill -9 http_server_exp"
    ssh ganton12@$1 "sudo pkill -9 mpstat"
    ssh ganton12@$1 "sudo pkill -9 stap"
}

run_server ()
{
    
    # Start server
    ssh ganton12@$1 "sudo $2 $3 $4 $5 &> /dev/null &"

    sleep 5

    # Check whether server has started
    res=$(ssh ganton12@$1 "ps -eo comm | grep http_server_exp | grep -v grep" | wc -l)

    while [[ "$res" == "0" ]]; 
    do
        # Kill processes
        ssh ganton12@$1 "sudo pkill -9 http_server_exp"
        
        # Start server
        ssh ganton12@$1 "sudo $2 $3 $4 $5 &> /dev/null &"

        sleep 5

        #Check whether server has started
        res=`ssh ganton12@$1 "ps -eo comm | grep http_server_exp | grep -v grep" | wc -l`
        
    done
   
}

run_mpstat ()
{
    ((iteration=$1/10))
    ssh ganton12@$2 "mpstat -P ALL 10 $iteration &> ~/mpstat.log &"
}

run_systemtap_idle ()
{

    ssh ganton12@$1 "sudo stap $HOME_DIR/idle.stp &> ~/systemtap_idle.log &"

}

if [[ -z $1 || -z $2 ]]; then 
    echo "Usage: ./wrapper-distribution.sh <runs> <duration>"
    exit;
fi

runs=$1
duration=$2

echo "EXP: Client default + server exp $runs $duration HOME_DIR=$HOME_DIR QPS=$QPS SERVICE_RATE=$SERVICE_RATE CONNECTIONS=$CONNECTIONS THREADS=$THREADS"
# Create the experiment directory

EXP_DIR=~/data/"client=def-server=def"

mkdir "$EXP_DIR"

# for (( i=1 ; i<=$runs ; i++ )); 
# do
#     for service in $SERVICE_RATE;
#     do
#         # Make this run output
#         mkdir $EXP_DIR"/run-"$i"-service-"$service

#         # Start server
#         run_server $SERVER_NODE $SERVER_DEF_PATH $service $THREADS $SEED
       
#         # Start utilization
#         run_mpstat $duration $SERVER_NODE

#         # Start systemtap idle time monitoring

#         run_systemtap_idle $SERVER_NODE

#         # Start Client
#         command="$CLIENT_PATH -t$THREADS -c$CONNECTIONS -D exp -d"$duration"s -R$queries http://"$SERVER_NODE":8080"
#         echo "$command"
#         $command &> "$EXP_DIR/run-$i-service-$service/client.log"
        
#         sleep 5

#         # Check whether client has finished successfully
#         res=`cat "$EXP_DIR/run-$i-service-$service/client.log" | grep "Latency" | wc -l`
        
#         while [[ "$res" == "0" ]]; 
#         do
#             # Kill processes
#             kill_proc $SERVER_NODE
            
#             # Start server
#             run_server $SERVER_NODE $SERVER_DEF_PATH $service $THREADS $SEED

#             # Start utilization
#             run_mpstat $duration $SERVER_NODE

#             # Start systemtap idle time monitoring
#             run_systemtap_idle $SERVER_NODE

#             # Start Client
#             $command &> "$EXP_DIR/run-$i-service-$service/client.log"

#             sleep 5

#             # Check whether client has finished successfully
#             res=`cat "$EXP_DIR/run-$i-service-$service/client.log" | grep "Latency" | wc -l`

#         done

#         # Kill processes
#         kill_proc $SERVER_NODE

#         sleep 5

#         # Move data to client
#         scp ganton12@$SERVER_NODE:~/mpstat.log "$EXP_DIR/run-$i-service-$service/"
#         scp ganton12@$SERVER_NODE:~/systemtap_idle.log "$EXP_DIR/run-"$i"-service-"$service"/"
    
#     done

# done
##############################################################################################################################################################

# echo "EXP: Client default, response script + server exp $runs $duration HOME_DIR=$HOME_DIR QPS=$QPS SERVICE_RATE=$SERVICE_RATE CONNECTIONS=$CONNECTIONS THREADS=$THREADS"
# # Create the experiment directory

# EXP_DIR=~/data/"client=defrsp-server=def"

# mkdir "$EXP_DIR"

# for (( i=1 ; i<=$runs ; i++ )); 
# do
#     for service in $SERVICE_RATE;
#     do
#         #Make this run output
#         mkdir $EXP_DIR"/run-"$i"-service-"$service
    
#         # Start server
#         run_server $SERVER_NODE $SERVER_DEF_PATH $service $THREADS $SEED
       
#         # Start utilization
#         run_mpstat $duration $SERVER_NODE

#         #Start Client
#         command="$CLIENT_PATH -t$THREADS -c$CONNECTIONS -D exp -d"$duration"s -R$queries -s $HOME_DIR/wrk2/log_response_time.lua http://"$SERVER_NODE":8080" 
#         $command &> "$EXP_DIR/run-$i-service-$service/client.log"

#         sleep 5
        
#         # Check whether client has finished successfully
#         res=`cat "$EXP_DIR/run-$i-service-$service/client.log" | grep "Latency" | wc -l`

#         while [[ "$res" == "0" ]]; 
#         do
#             # Kill processes
#             kill_proc $SERVER_NODE
            
#             # Start server
#             run_server $SERVER_NODE $SERVER_DEF_PATH $service $THREADS $SEED

#             # Start utilization
#             run_mpstat $duration $SERVER_NODE

#             # Start Client
#             $command &> "$EXP_DIR/run-$i-service-$service/client.log"

#             sleep 5

#             # Check whether client has finished successfully
#             res=`cat "$EXP_DIR/run-$i-service-$service/client.log" | grep "Latency" | wc -l`
#         done

#         # Kill processes
#         kill_proc $SERVER_NODE

#         sleep 5

#         # Move data to client
#         scp ganton12@$SERVER_NODE:~/mpstat.log "$EXP_DIR/run-$i-service-$service/"
#         mv $HOME_DIR/response_times_thread_* "$EXP_DIR/run-$i-service-$service/"
        
#     done

# done

##############################################################################################################################################################

echo "EXP: Client default server exp,timer $runs $duration HOME_DIR=$HOME_DIR QPS=$QPS SERVICE_RATE=$SERVICE_RATE CONNECTIONS=$CONNECTIONS THREADS=$THREADS"
# Create the experiment directory

EXP_DIR=~/data/"client=def-server=timer"

mkdir "$EXP_DIR"

for (( i=1 ; i<=$runs ; i++ )); 
do
    for service in $SERVICE_RATE;
    do
        # Make this run output
        mkdir $EXP_DIR"/run-"$i"-service-"$service
    
        # Start server
        run_server $SERVER_NODE $SERVER_TIMER_PATH $service $THREADS $SEED
       
        # Start utilization
        run_mpstat $duration $SERVER_NODE

        #Start Client
        command="$CLIENT_PATH -t$THREADS -c$CONNECTIONS -D exp -d"$duration"s -R$queries http://"$SERVER_NODE":8080" 
        $command &> "$EXP_DIR/run-$i-service-$service/client.log"

        sleep 5
        
        # Check whether client has finished successfully
        res=`cat "$EXP_DIR/run-$i-service-$service/client.log" | grep "Latency" | wc -l`

        while [[ "$res" == "0" ]]; 
        do
            # Kill processes
            kill_proc $SERVER_NODE
            
            # Start server
            run_server $SERVER_NODE $SERVER_TIMER_PATH $service $THREADS $SEED

            # Start utilization
            run_mpstat $duration $SERVER_NODE

            # Start Client
            $command &> "$EXP_DIR/run-$i-service-$service/client.log"

            sleep 5

            # Check whether client has finished successfully
            res=`cat "$EXP_DIR/run-$i-service-$service/client.log" | grep "Latency" | wc -l`
        done
    
        ssh ganton12@$SERVER_NODE "sudo pkill -2 http_server_exp"
        
        # Kill processes
        kill_proc $SERVER_NODE

        sleep 5

        # Move data to client
        scp ganton12@$SERVER_NODE:~/mpstat.log "$EXP_DIR/run-$i-service-$service/"
        scp ganton12@$SERVER_NODE:~/thread_* "$EXP_DIR/run-$i-service-$service/" 
        exit;
    done

done

