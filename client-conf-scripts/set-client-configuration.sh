#!/bin/bash

####################################################################################################################
# This script configures properly the grub file and the machines. Specifically it takes as arguments the following:
#   1) Configuration string:
#       -> C-States enabled: 
#           -> 0: only C0 (intel_indle.max_cstate=0 idle=poll) 
#           -> 1: C0/C1 (intel_indle.max_cstate=1)
#           -> 2: C0/C1/C1E (intel_indle.max_cstate=2)
#           -> 3: C0/C1/C1E/C6 (remove intel_indle.max_cstate from grub file if exists)
#       -> Intel P-States:
#           -> 1: frequency driver is intel pstate (remove intel_pstate if exists)
#           -> 0: frequency driver is acpi_cpufreq (intel_pstate=disable)
#       -> Tickless:
#           -> 1: no timer interrupts on idle periods (nohz=on)
#           -> 0: timer interrupts always (remove nohz=on from grub file)
#       -> SMT:
#           -> 1: 2 logical threads per physical core
#           -> 0: 1 thread per core
#       -> Frequency Governor:
#           -> 0: powersave
#           -> 1: performance
#           -> 2: userspace 2.2GHz
#           -> 3: ondemand
#       -> Uncore Frequency:
#           -> 1: fixed uncore frequency to 2 GHz
#           -> 0: dynamic uncore frequency to 1.2 GHz
#       -> Turbo:
#           -> 1: frquencies higher from the nominal
#           -> 0: frequencies nominal and lower
#       i.e: 0000000: cstates-disabled/intel-p-states-off/tickless-off/smt-off/freq-governor-powersave/uncore-freq-dynamic/turbo-off/
#       i.e: 3101001: this is the default configuration for skylake pcs client
#                     cstates-enabled/intel-p-states-on/tickless-on/smt-on/freq-gov-ondemand/uncore-dynamic/turbo-on/ 
#   2) nodes: hostname to configure seperated by comma 
#   3) PWD: Project Working Directory
#   4) Node,RD: node that saves the results and 
#####################################################################################################

# Scripts for every parameter the script configures
typeset -Ag GRUB_SCRIPTS=([0]="./set-cstates.sh" [1]="./set-intelpstate.sh" [2]="./set-tickless.sh")
typeset -Ag CONF_SCRIPTS=([3]="./set-smt.sh" [4]="./set-frequencygovernor.sh" [5]="./set-uncore.sh" [6]="./set-turbo.sh")
NUM_CONFS=7

# global variable for the current configuration
CONF_STRING=""
typeset -Ag CONF_VAL_ARR
typeset -g NODES
PROJ_DIR=""
RES_DIR=""
RES_NODE=""
REBOOT=0

save_client_conf () {

    echo "set-client-configuration FUNC:save_client_conf MSG:Save client configuration" >&2

    for node in "${NODES[@]}"
    do
        
        touch "client_conf_"$node

        for i in "${!GRUB_SCRIPTS[@]}"
        do  

            temp=`${GRUB_SCRIPTS[$i]} get $node`
            return_val=$?
            if [[ $return_val -eq 1 ]]; then
                exit 1
            fi
            echo "$temp" >> "client_conf_"$node

        done

    done

    for node in "${NODES[@]}"
    do

        for i in "${!CONF_SCRIPTS[@]}"
        do  

            temp=`${CONF_SCRIPTS[$i]} get $node`
            return_val=$?
            if [[ $return_val -eq 1 ]]; then
                exit 1
            fi
            echo "$temp" >> "client_conf_"$node

        done
    
    done    

    #check if result dir exists and if not create
    if  [[ ! `ssh ganton12@$RES_NODE "test -d $RES_DIR"` ]]; then

        ssh ganton12@$RES_NODE "mkdir $RES_DIR"

    fi
    
    for node in "${NODES[@]}"
    do

        scp "client_conf_"$node ganton12@$RES_NODE:$RES_DIR

    done

    ssh ganton12@$RES_NODE "echo $CONF_STRING &> $RES_DIR/client_conf"
    ssh ganton12@$RES_NODE "echo $RES_DIR &>> $RES_DIR/client_conf"
    ssh ganton12@$RES_NODE "echo $PROJ_DIR &>> $RES_DIR/client_conf"
    ssh ganton12@$RES_NODE "echo $RES_NODE &>> $RES_DIR/client_conf"
    ssh ganton12@$RES_NODE "echo $REBOOT &>> $RES_DIR/client_conf"
}

##################################################################################
# The following function sets the parameters that do not require grub file. 
#
set_rest_conf () {

    echo "set-client-configuration FUNC:set_rest_conf MSG:Set rest of configuration" >&2

    for node in "${NODES[@]}"
    do
        for i in "${!CONF_SCRIPTS[@]}"
        do  

            ${CONF_SCRIPTS[$i]} set ${CONF_VAL_ARR[$i]} $node $PROJ_DIR
            return_val=$?
            if [[ $return_val -eq 1 ]]; then
                exit 1
            fi 

        done
    done
    
}

##################################################################################
# The following function checks whether client nodes have booted.
#
check_nodes_on () {

    echo "set-client-configuration FUNC:check_nodes_on MSG:Check nodes on!!!" >&2
    for node in "${NODES[@]}"
    do  
        #Check if machine has booted
        echo "set-client-configuration FUNC:check_nodes_on MSG:Check nodes $node" >&2

        packets=`ping -c 1 $node | grep "received" | awk '{print $4}'`
        echo "$packets"
        while [[ $packets == "0" ]]; 
        do
            
            sleep 30
            packets=`ping -c 1 $node | grep "received" | awk '{print $4}'`
            echo "$packets"

        done

    done

}

##################################################################################
# The following function set all the grub files to the current configuration. It 
# also executes update-grub2. It uses global variables not arguments.
#
reboot_nodes () {

    echo "set-client-configuration FUNC:reboot_nodes MSG:Rebooting nodes!!!" >&2
    for node in "${NODES[@]}"
    do
        echo "set-client-configuration FUNC:reboot_nodes MSG:Rebooting node $node" >&2
        ssh ganton12@$node "sudo reboot"

    done
    
}

##################################################################################
# The following function set all the grub files to the current configuration. It 
# also executes update-grub2. It uses global variables not arguments.
#
update_grub () {

    for node in "${NODES[@]}"
    do
        for i in "${!GRUB_SCRIPTS[@]}"
        do  

            ${GRUB_SCRIPTS[$i]} set ${CONF_VAL_ARR[$i]} $node 
            return_val=$?
            if [[ $return_val -eq 1 ]]; then
                exit 1
            fi

        done
    done
    
}

##################################################################################
# The following function reset all the grub files parameters to the initial state. 
# It uses global variables not arguments.
#
reset_grub () {

    for node in "${NODES[@]}"
    do
        for i in "${!GRUB_SCRIPTS[@]}"
        do  

            ${GRUB_SCRIPTS[$i]} reset $node 
            return_val=$?
            if [[ $return_val -eq 1 ]]; then
                exit 1
            fi
            
        done
    done
    
}

##################################################################################
# The following function checks whether the machine needs to be rebooted for the 
# current configuration. The function uses global variables, there is no need for
# arguments.
#
check_reboot () {

    REBOOT=0
    for node in "${NODES[@]}"
    do
        for i in "${!GRUB_SCRIPTS[@]}"
        do  

            ${GRUB_SCRIPTS[$i]} check_reset $node ${CONF_VAL_ARR[$i]}
            return_val=$?
            if [[ $return_val -eq 1 ]]; then
                REBOOT=1
            fi

        done
    done
    
}

##################################################################################
# This function prints the global variables.
# 
print_global_var () {

    for key in "${!GRUB_SCRIPTS[@]}"; do
        echo "$key: ${GRUB_SCRIPTS[$key]}"
    done
    
    for key in "${!CONF_SCRIPTS[@]}"; do
        echo "$key: ${CONF_SCRIPTS[$key]}"
    done
    
    for key in "${!CONF_VAL_ARR[@]}"; do
        echo "$key: ${CONF_VAL_ARR[$key]}"
    done

    for key in "${!NODES[@]}"; do
        echo "$key: ${NODES[$key]}"
    done

    echo "$NUM_CONFS"
    echo "$CONF_STRING"
    echo "$PROJ_DIR"
    echo "$RES_DIR"
    echo "$RES_NODE"
    echo "$REBOOT"

}

##################################################################################
# The following function checks the arguments. Specifically it checks whether the 
# length of the conf_string is the correct one. It checks whether nodes are 
# reachable. Checks whether project directory exists. Additionally it checks the 
# arguments for each configuration seperately  
# 
# Arg 1:    string_configuration
# Arg 2:    nodes
# Arg 3:    project directory
# Arg 4:    node,result directory 
parse_args () {

    #Test 1: Check the configuration string length first
    temp_conf_string=$1
    if [[ ${#temp_conf_string} -ne $NUM_CONFS ]]; then
        echo "set-client-configuration FUNC:parse_args MSG:Invalid argument ~configuration-string~ (wrong size): " >&2
        echo "" >&2
        echo "set-client-configuration FUNC:parse_args MSG:Current Size: ${#temp_conf_string}" >&2
        echo "" >&2
        echo "set-client-configuration FUNC:parse_args MSG:Correct Size: $NUM_CONFS" >&2
        exit 1
    else
        CONF_STRING=$temp_conf_string
        echo "set-client-configuration FUNC:parse_args MSG:Arg test conf str size: PASS" >&2
    fi

    #Test 2: Check if configuration nodes are reachable
    for i in $(echo $2 | sed "s/,/ /g")
    do
        if [[ `ping -c 1 $i | grep received | wc -l` -ne 1 ]]; then
            echo "set-client-configuration FUNC:parse_args MSG:Node-$i not reachable" >&2
            exit 1
        fi
        # call your procedure/other scripts here below
        NODES+=("$i")
        echo "set-client-configuration FUNC:parse_args MSG:Node-$i reachable" >&2
    done

    #Test 3: Check whether project directory exists
    for i in $(echo $2 | sed "s/,/ /g")
    do
        if [[ `ssh ganton12@$i "if [[ -d $3 ]]; then echo "1"; else echo "0"; fi" ` -ne 1 ]]; then
            echo "set-client-configuration FUNC:parse_args MSG:Proj-dir-$3 $i  not exists" >&2
            exit 1
        fi
        # call your procedure/other scripts here below
        echo "set-client-configuration FUNC:parse_args MSG:Proj-dir-$3 $i exists" >&2
    done
    PROJ_DIR=$3

    #Test 4: Check if configuration scripts parameter values are correct
    # Iterate through each character in the string and put the conf values in an array
    for ((i=0; i<${#1}; i++)); do
        # Add the current character to the array
        CONF_VAL_ARR["$i"]="${1:$i:1}"
    done

    # for key in "${!CONF_VAL_ARR[@]}"; do
    #     echo "$key: ${CONF_VAL_ARR[$key]}"
    # done
    
    #check first the grub file arguments
    for i in "${!GRUB_SCRIPTS[@]}"
    do  

        ${GRUB_SCRIPTS[$i]} check_args ${CONF_VAL_ARR[$i]}
        return_val=$?
        if [[ $return_val -eq 1 ]]; then
            exit 1
        fi

    done

    for i in "${!CONF_SCRIPTS[@]}"
    do  

        ${CONF_SCRIPTS[$i]} check_args ${CONF_VAL_ARR[$i]}
        return_val=$?
        if [[ $return_val -eq 1 ]]; then
            exit 1
        fi

    done

    RES_DIR=`echo $4 | awk -F"," '{print $2}'`
    RES_NODE=`echo $4 | awk -F"," '{print $1}'`
        
}

main () {

    if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then

        echo "Invalid argument length: " >&2
        echo "" >&2
        echo "Usage: $(basename $0) main [configuration_string] [nodes] [project-working-directory] [node,rd]" >&2
        echo "" >&2
        echo "Example: $(basename $0) main 0000000 node0,node1,node2 ~/mcperf/client-conf-scripts node0,~/data/" >&2
        exit 1
    fi 

    #first parse the arguments and make the necessary checks
    parse_args $1 $2 $3 $4

    # check if machine needs to reboot
    check_reboot 

    # if reboot equals 1 then reset and update grub file and restart machines 
    if [[ $REBOOT -eq 1 ]]; then
        #reset all the configurations from grub file
        reset_grub

        #update grub files for all nodes
        update_grub

        #reboot machines
        reboot_nodes

        sleep 180

        #check if machines booted
        check_nodes_on

    fi

    #set rest of machine configuration
    set_rest_conf

    # save client configuration and timestamp on result node
    save_client_conf
     
    for node in "${NODES[@]}"
    do

        sudo rm "client_conf_"$node 

    done

    exit 0
}

"$@"