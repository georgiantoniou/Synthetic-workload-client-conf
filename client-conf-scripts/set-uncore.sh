#!/bin/bash

####################################################################################################
# This script is used to set fixed/dynamic uncore frequency using msr registers. 
# It has 5 functions
#   1) check_args:  Check args it checks the format of the input parameter. set-uncore.sh currently
#                   recognizes the following inputs
#                   -> 0: dynamic (sudo wrmsr 0x620 0xc14)
#                   -> 1: fixed (sudo wrmsr 0x620 0x1414)
#                   
#                   It takes as an argument the following:
#                   -> Arg1: Configuration Value
# 
#   2) set_conf:    Change the configuration based on the configuration parameter. It takes as an arg
#                   the following:
#                   -> Arg1: Configuration Value 
#                   -> Arg2: Node to change configuration
#
#   3) reset_conf:  Reset the initial uncore frequency configuration which is the
#                   configuration with the value 0.
#                   -> Arg1: Node to change configuration
#
#   4) check_reset: No need to implement this because uncore can be configured without reboot 
#
#   5) get:         Return the uncore frequency configuration of a node. Returns sudo rdmsr 0x620.
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
        echo "set-uncore FUNC:check_reset MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-uncore FUNC:check_reset MSG:Usage: $(basename $0) check_reset [node] [configuration_value]" >&2
        echo "" >&2
        echo "set-uncore FUNC:check_reset MSG:Example: $(basename $0) check_reset node0 0" >&2
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
        echo "set-uncore FUNC:reset MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-uncore FUNC:reset MSG:Usage: $(basename $0) reset [node]" >&2
        echo "" >&2
        echo "set-uncore FUNC:reset MSG:Example: $(basename $0) reset 0 node0" >&2
        exit 1
    fi

    ssh ganton12@$host "sudo wrmsr 0x620 0xc14"
    echo "set-uncore FUNC:reset MSG:$host reset" >&2
}

##################################################################################
# Set configuration Value.
# 
# Arg 1:    configuration value
# Arg 2:    node
set () {

    if [[ -z $1 || -z $2 ]]; then
        echo "set-uncore FUNC:set MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-uncore FUNC:set MSG:Usage: $(basename $0) set [configuration_value] [node]" >&2
        echo "" >&2
        echo "set-uncore FUNC:set MSG:Example: $(basename $0) set 0 node0" >&2
        exit 1
    fi

    uncore=$1
    host=$2
    
    if [[ $uncore == 1 ]]; then
        
        ssh ganton12@$host "sudo wrmsr 0x620 0x1414"
        echo "set-uncore FUNC:set MSG: Node-$host uncore fixed"
    
    elif [[ $uncore == 0 ]]; then  
    
        ssh ganton12@$host "sudo wrmsr 0x620 0xc14"
        echo "set-uncore FUNC:set MSG: Node-$host uncore dynamic"

    fi

    exit 0

}

##################################################################################
# Get configuration of the machine.
# 
# Arg 1:    node
get () {

    if [[ -z $1 ]]; then
        echo "set-uncore FUNC:get MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-uncore FUNC:get MSG:Usage: $(basename $0) get [node]" >&2
        echo "" >&2
        echo "set-uncore FUNC:get MSG:Example: $(basename $0) get node0" >&2
        exit 1
    fi

    temp=`ssh ganton12@$1 "sudo rdmsr 0x620"`
    echo "***UNCORE***: $temp"

    exit 0

}

##################################################################################
# Check arg configuratio value. Valid choices (0,1)
# 
# Arg 1:    configuration value
check_args () {

    if [[ -z $1 ]]; then
        echo "set-uncore FUNC:check_args MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-uncore FUNC:check_args MSG:Usage: $(basename $0) check_args [configuration_value]" >&2
        echo "" >&2
        echo "set-uncore FUNC:check_args MSG:Example: $(basename $0) check_args 0" >&2
        exit 1
    fi

    if [[ $1 -ne 0 && $1 -ne 1 ]]; then
        echo "set-uncore FUNC:check_args MSG:Invalid configuration value: $1 " >&2
        echo "" >&2
        echo "set-uncore FUNC:check_args MSG:Usage: $(basename $0) check_args [configuration_value]" >&2
        echo "" >&2
        echo "set-uncore FUNC:check_args MSG:Example: $(basename $0) check_args [0,1]" >&2
        exit 1
    else
        echo "set-uncore FUNC:check_args MSG:Arg test conf value: PASS " >&2
        exit 0
    fi

}
"$@"