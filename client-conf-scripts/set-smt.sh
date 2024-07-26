#!/bin/bash

####################################################################################################
# This script is used to enable/disable smt from the pseudo root filesystem. 
# It has 5 functions
#   1) check_args:  Check args it checks the format of the input parameter. set-smt.sh currently
#                   recognizes the following inputs
#                   -> 0: Disable SMT (echo "off" | sudo tee /sys/devices/system/cpu/smt/control)
#                   -> 1: Enable SMT (echo "on" | sudo tee /sys/devices/system/cpu/smt/control)
#                   
#                   It takes as an argument the following:
#                   -> Arg1: Configuration Value
# 
#   2) set_conf:    Changes the configuration based on the configuration parameter. It takes as an arg
#                   the following:
#                   -> Arg1: Configuration Value 
#                   -> Arg2: Node to change configuration
#
#   3) reset_conf:  Reset the initial smt configuration which is the
#                   configuration with the value 1.
#                   -> Arg1: Node to change configuration
#
#   4) check_reset: No need to implement this because smt can be configured without reboot 
#
#   5) get:         Return the smt configuration of a node. Returns /proc/cpuinfo | grep MHz.
#                   and cat /sys/devices/system/cpu/smt/control.
#                   -> Arg1: Node
#
#####################################################################################################

##################################################################################
# Check whether we need to reset machine.
# 
# Arg1: Node
# Arg2: Val
check_reset () {

     if [[ -z $1 || -z $2 ]]; then
        echo "set-smt FUNC:check_reset MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-smt FUNC:check_reset MSG:Usage: $(basename $0) check_reset [node] [configuration_value]" >&2
        echo "" >&2
        echo "set-smt FUNC:check_reset MSG:Example: $(basename $0) check_reset node0 0" >&2
        exit 1
    fi

}

##################################################################################
# Reset configuration Value.
# 
# Arg1: Node
reset () {

    host=$1
    if [[ -z $1 ]]; then
        echo "set-smt FUNC:reset MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-smt FUNC:reset MSG:Usage: $(basename $0) reset [node]" >&2
        echo "" >&2
        echo "set-smt FUNC:reset MSG:Example: $(basename $0) reset 0 node0" >&2
        exit 1
    fi

    ssh ganton12@$host "sudo echo "on" | sudo tee /sys/devices/system/cpu/smt/control"
    echo "set-smt FUNC:reset MSG:$host reset" >&2
}

##################################################################################
# Set configuration Value.
# 
# Arg 1:    configuration value
# Arg 2:    node
set () {

    if [[ -z $1 || -z $2 ]]; then
        echo "set-smt FUNC:set MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-smt FUNC:set MSG:Usage: $(basename $0) set [configuration_value] [node]" >&2
        echo "" >&2
        echo "set-smt FUNC:set MSG:Example: $(basename $0) set 0 node0" >&2
        exit 1
    fi

    smt=$1
    host=$2
    
    if [[ $smt == "1" ]]; then
        
        ssh ganton12@$host "sudo echo "on" | sudo tee /sys/devices/system/cpu/smt/control"
        echo "set-smt FUNC:set MSG: Node-$host smt on"
    
    elif [[ $smt == "0" ]]; then  
    
        ssh ganton12@$host "sudo echo "off" | sudo tee /sys/devices/system/cpu/smt/control"
        echo "set-smt FUNC:set MSG: Node-$host smt off"

    fi

    exit 0

}

##################################################################################
# Get configuration of the machine.
# 
# Arg 1:    node
get () {

    if [[ -z $1 ]]; then
        echo "set-smt FUNC:get MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-smt FUNC:get MSG:Usage: $(basename $0) get [node]" >&2
        echo "" >&2
        echo "set-smt FUNC:get MSG:Example: $(basename $0) get node0" >&2
        exit 1
    fi

    temp=`ssh ganton12@$1 "sudo cat /sys/devices/system/cpu/smt/control"`
    echo "***SMT_CONTROL***: $temp"

    temp=`ssh ganton12@$1 "cat /proc/cpuinfo | grep MHz | wc -l"`
    echo "***SMT_THREADS***: $temp"

    exit 0

}


##################################################################################
# Check arg configuratio value. Valid choices (0,1)
# 
# Arg 1:    configuration value
check_args () {

    if [[ -z $1 ]]; then
        echo "set-smt FUNC:check_args MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-smt FUNC:check_args MSG:Usage: $(basename $0) check_args [configuration_value]" >&2
        echo "" >&2
        echo "set-smt FUNC:check_args MSG:Example: $(basename $0) check_args 0" >&2
        exit 1
    fi

    if [[ $1 -ne 0 && $1 -ne 1 ]]; then
        echo "set-smt FUNC:check_args MSG:Invalid configuration value: $1 " >&2
        echo "" >&2
        echo "set-smt FUNC:check_args MSG:Usage: $(basename $0) check_args [configuration_value]" >&2
        echo "" >&2
        echo "set-smt FUNC:check_args MSG:Example: $(basename $0) check_args [0,1]" >&2
        exit 1
    else
        echo "set-smt FUNC:check_args MSG:Arg test conf value: PASS " >&2
        exit 0
    fi

}
"$@"