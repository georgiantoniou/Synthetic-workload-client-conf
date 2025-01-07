#!/bin/bash

HOME_DIR=~/Synthetic-workload-client-conf/
SERVER_DEF_PATH=~/Synthetic-workload-client-conf/http_server_exp
SERVER_TIMER_PATH=~/Synthetic-workload-client-conf/http_server_exp_timer
CLIENT_PATH=~/Synthetic-workload-client-conf/wrk2/wrk
SERVER_NODE="node1"
SEED=1234
QPS="10 20 30 40 50"
SERVICE_RATE=1000
CONNECTIONS=1
THREADS=1

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

for (( i=1 ; i<=$runs ; i++ )); 
do
    for queries in $QPS;
    do
        #Make this run output
        mkdir $EXP_DIR"/run-"$i"-qps-"$queries
    
        #Start server
        ssh ganton12@$SERVER_NODE "sudo $SERVER_DEF_PATH $SERVICE_RATE $THREADS $SEED &> /dev/null &"

        sleep 5
       
        #Start utilization
        ((iteration=duration/10))
        ssh ganton12@$SERVER_NODE "mpstat -P ALL 10 $iteration &> ~/mpstat.log &"

        #Start Client
        command="$CLIENT_PATH -t$THREADS -c$CONNECTIONS -D exp -d"$duration"s -R$queries http://"$SERVER_NODE":8080" 
        $command &> "$EXP_DIR/run-$i-qps-$queries/client.log"
               
        # Kill processes
        ssh ganton12@$SERVER_NODE "sudo pkill -9 http_server_exp"
        ssh ganton12@$SERVER_NODE "sudo pkill -9 mpstat"

        sleep 10

        # Move data to client
        scp ganton12@$SERVER_NODE:~/mpstat.log "$EXP_DIR/run-$i-qps-$queries/"

        sleep 10

    done

done


###############################################################################################################################################################


echo "EXP: Client extra + server exp $runs $duration HOME_DIR=$HOME_DIR QPS=$QPS SERVICE_RATE=$SERVICE_RATE CONNECTIONS=$CONNECTIONS THREADS=$THREADS"
# Create the experiment directory

EXP_DIR=~/data/"client=extra-server=def"

mkdir "$EXP_DIR"

for (( i=1 ; i<=$runs ; i++ )); 
do
    for queries in $QPS;
    do
        #Make this run output
        mkdir $EXP_DIR"/run-"$i"-qps-"$queries
    
        #Start server
        ssh ganton12@$SERVER_NODE "sudo $SERVER_DEF_PATH $SERVICE_RATE $THREADS $SEED &> /dev/null &"

        sleep 5
       
        #Start utilization
        ((iteration=duration/10))
        ssh ganton12@$SERVER_NODE "mpstat -P ALL 10 $iteration &> ~/mpstat.log &"

        #Start Client
        command="$CLIENT_PATH -t$THREADS -c$CONNECTIONS -D exp -d"$duration"s -R$queries -L http://"$SERVER_NODE":8080" 
        $command &> "$EXP_DIR/run-$i-qps-$queries/client.log"
        
        # Kill processes
        ssh ganton12@$SERVER_NODE "sudo pkill -9 http_server_exp"
        ssh ganton12@$SERVER_NODE "sudo pkill -9 mpstat"

        sleep 10

        # Move data to client
        scp ganton12@$SERVER_NODE:~/mpstat.log "$EXP_DIR/run-$i-qps-$queries/"

        sleep 10

    done

done

##############################################################################################################################################################


echo "EXP: Client default, arrival script + server exp $runs $duration HOME_DIR=$HOME_DIR QPS=$QPS SERVICE_RATE=$SERVICE_RATE CONNECTIONS=$CONNECTIONS THREADS=$THREADS"
# Create the experiment directory

EXP_DIR=~/data/"client=defarr-server=def"

mkdir "$EXP_DIR"

for (( i=1 ; i<=$runs ; i++ )); 
do
    for queries in $QPS;
    do
        #Make this run output
        mkdir $EXP_DIR"/run-"$i"-qps-"$queries
    
        #Start server
        ssh ganton12@$SERVER_NODE "sudo $SERVER_DEF_PATH $SERVICE_RATE $THREADS $SEED &> /dev/null &"

        sleep 5
       
        #Start utilization
        ((iteration=duration/10))
        ssh ganton12@$SERVER_NODE "mpstat -P ALL 10 $iteration &> ~/mpstat.log &"

        #Start Client
        command="$CLIENT_PATH -t$THREADS -c$CONNECTIONS -D exp -d"$duration"s -R$queries -s $HOME_DIR/wrk2/log_arrival_time.lua http://"$SERVER_NODE":8080" 
        $command &> "$EXP_DIR/run-$i-qps-$queries/client.log"
        
        # Kill processes
        ssh ganton12@$SERVER_NODE "sudo pkill -9 http_server_exp"
        ssh ganton12@$SERVER_NODE "sudo pkill -9 mpstat"

        sleep 10

        # Move data to client
        scp ganton12@$SERVER_NODE:~/mpstat.log "$EXP_DIR/run-$i-qps-$queries/"
        mv $HOME_DIR/timestamps_* "$EXP_DIR/run-$i-qps-$queries/"

        sleep 10

    done

done

##############################################################################################################################################################

echo "EXP: Client default, response script + server exp $runs $duration HOME_DIR=$HOME_DIR QPS=$QPS SERVICE_RATE=$SERVICE_RATE CONNECTIONS=$CONNECTIONS THREADS=$THREADS"
# Create the experiment directory

EXP_DIR=~/data/"client=defrsp-server=def"

mkdir "$EXP_DIR"

for (( i=1 ; i<=$runs ; i++ )); 
do
    for queries in $QPS;
    do
        #Make this run output
        mkdir $EXP_DIR"/run-"$i"-qps-"$queries
    
        #Start server
        ssh ganton12@$SERVER_NODE "sudo $SERVER_DEF_PATH $SERVICE_RATE $THREADS $SEED &> /dev/null &"

        sleep 5
       
        #Start utilization
        ((iteration=duration/10))
        ssh ganton12@$SERVER_NODE "mpstat -P ALL 10 $iteration &> ~/mpstat.log &"

        #Start Client
        command="$CLIENT_PATH -t$THREADS -c$CONNECTIONS -D exp -d"$duration"s -R$queries -s $HOME_DIR/wrk2/log_response_time.lua http://"$SERVER_NODE":8080" 
        $command &> "$EXP_DIR/run-$i-qps-$queries/client.log"
        
        # Kill processes
        ssh ganton12@$SERVER_NODE "sudo pkill -9 http_server_exp"
        ssh ganton12@$SERVER_NODE "sudo pkill -9 mpstat"

        sleep 10

        # Move data to client
        scp ganton12@$SERVER_NODE:~/mpstat.log "$EXP_DIR/run-$i-qps-$queries/"
        mv $HOME_DIR/response_times_thread_* "$EXP_DIR/run-$i-qps-$queries/"

        sleep 10

    done

done

##############################################################################################################################################################

echo "EXP: Client default server exp,timer $runs $duration HOME_DIR=$HOME_DIR QPS=$QPS SERVICE_RATE=$SERVICE_RATE CONNECTIONS=$CONNECTIONS THREADS=$THREADS"
# Create the experiment directory

EXP_DIR=~/data/"client=def-server=timer"

mkdir "$EXP_DIR"

for (( i=1 ; i<=$runs ; i++ )); 
do
    for queries in $QPS;
    do
        #Make this run output
        mkdir $EXP_DIR"/run-"$i"-qps-"$queries
    
        #Start server
        ssh ganton12@$SERVER_NODE "sudo $SERVER_TIMER_PATH $SERVICE_RATE $THREADS $SEED &> /dev/null &"
        
        sleep 5
       
        #Start utilization
        ((iteration=duration/10))
        ssh ganton12@$SERVER_NODE "mpstat -P ALL 10 $iteration &> ~/mpstat.log &"

        #Start Client
        command="$CLIENT_PATH -t$THREADS -c$CONNECTIONS -D exp -d"$duration"s -R$queries http://"$SERVER_NODE":8080" 
        $command &> "$EXP_DIR/run-$i-qps-$queries/client.log"

        ssh ganton12@$SERVER_NODE "sudo pkill --signal SIGINT http_server_exp"
        
        # Kill processes
        ssh ganton12@$SERVER_NODE "sudo pkill -9 http_server_exp"
        ssh ganton12@$SERVER_NODE "sudo pkill -9 mpstat"

        sleep 10

        # Move data to client
        scp ganton12@$SERVER_NODE:~/mpstat.log "$EXP_DIR/run-$i-qps-$queries/"
        scp ganton12@$SERVER_NODE:~/thread_* "$EXP_DIR/run-$i-qps-$queries/"
       
        sleep 10
        
    done

done

###############################################################################################################################################################

echo "EXP: Client extra server exp,timer $runs $duration HOME_DIR=$HOME_DIR QPS=$QPS SERVICE_RATE=$SERVICE_RATE CONNECTIONS=$CONNECTIONS THREADS=$THREADS"
# Create the experiment directory

EXP_DIR=~/data/"client=extra-server=timer"

mkdir "$EXP_DIR"

for (( i=1 ; i<=$runs ; i++ )); 
do
    for queries in $QPS;
    do
        #Make this run output
        mkdir $EXP_DIR"/run-"$i"-qps-"$queries
    
        #Start server
        ssh ganton12@$SERVER_NODE "sudo $SERVER_TIMER_PATH $SERVICE_RATE $THREADS $SEED &> /dev/null &"

        sleep 5
       
        #Start utilization
        ((iteration=duration/10))
        ssh ganton12@$SERVER_NODE "mpstat -P ALL 10 $iteration &> ~/mpstat.log &"

        #Start Client
        command="$CLIENT_PATH -t$THREADS -c$CONNECTIONS -D exp -d"$duration"s -R$queries -L http://"$SERVER_NODE":8080" 
        $command &> "$EXP_DIR/run-$i-qps-$queries/client.log"
        
        ssh ganton12@$SERVER_NODE "sudo pkill --signal SIGINT http_server_exp"

        # Kill processes
        ssh ganton12@$SERVER_NODE "sudo pkill -9 http_server_exp"
        ssh ganton12@$SERVER_NODE "sudo pkill -9 mpstat"

        sleep 10

        # Move data to client
        scp ganton12@$SERVER_NODE:~/mpstat.log "$EXP_DIR/run-$i-qps-$queries/"
        scp ganton12@$SERVER_NODE:~/thread_* "$EXP_DIR/run-$i-qps-$queries/"
       
        sleep 10
        
    done
    

done

##############################################################################################################################################################