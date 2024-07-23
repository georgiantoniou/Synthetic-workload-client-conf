#!/bin/bash

####################################################################################################
# This script is used to set freguency governor to powersave/performance/userspace. 
# It has 5 functions
#   1) check_args:  Check args it checks the format of the input parameter. set-frequncygovernor.sh 
#                   currently recognizes the following inputs
#                   -> 0: powersave (sudo cpupower frequency-set -g powersave)
#                   -> 1: performance (sudo cpupower frequency-set -g performance)
#                   -> 2: userspace (sudo cpupower frequency-set -g userspace;
#                         sudo cpupower frequency-set -f 2200MHz)
#                   -> 3: ondemand
#                         Option 2,3 cannot be used with intel_pstate
#
#                   It takes as an argument the following:
#                   -> Arg1: Configuration Value
# 
#   2) set_conf:    Change the configuration based on the configuration parameter. It takes as an arg
#                   the following:
#                   -> Arg1: Configuration Value 
#                   -> Arg2: Node to change configuration
#
#   3) reset_conf:  Reset the initial turbo configuration which is the
#                   configuration with the value 1.
#                   -> Arg1: Node to change configuration
#
#   4) check_reset: No need to implement this because frequency governor can be configured without reboot 
#
#   5) get:         Return the freq governor configuration of a node. sudo cpupower frequency-info.
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
        echo "set-frequencygovernor FUNC:check_reset MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-frequencygovernor FUNC:check_reset MSG:Usage: $(basename $0) check_reset [node] [configuration_value]" >&2
        echo "" >&2
        echo "set-frequencygovernor FUNC:check_reset MSG:Example: $(basename $0) check_reset node0 0" >&2
        exit 1
    fi

}

##################################################################################
# Reset configuration Value.
# 
# Arg1: Node
# Arg2: Project directory pass
reset () {

    host=$1
    if [[ -z $1 ]]; then
        echo "set-frequencygovernor FUNC:reset MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-frequencygovernor FUNC:reset MSG:Usage: $(basename $0) reset [node]" >&2
        echo "" >&2
        echo "set-frequencygovernor FUNC:reset MSG:Example: $(basename $0) reset 0 node0" >&2
        exit 1
    fi

    if [[ `ssh ganton12@$host "sudo cpupower frequency-info | grep intel_pstate | wc -l"` == 1 ]]; then
        ssh ganton12@$host "sudo cpupower frequency-set -g powersave"
    else
        ssh ganton12@$host "sudo cpupower frequency-set -g ondemand"
    fi
    
    echo "set-frequencygovernor FUNC:reset MSG:$host reset" >&2
}

##################################################################################
# Set configuration Value.
# 
# Arg 1:    configuration value
# Arg 2:    node
# Arg 3:    project directory
set () {

    if [[ -z $1 || -z $2 ]]; then
        echo "set-frequencygovernor FUNC:set MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-frequencygovernor FUNC:set MSG:Usage: $(basename $0) set [configuration_value] [node]" >&2
        echo "" >&2
        echo "set-frequencygovernor FUNC:set MSG:Example: $(basename $0) set 0 node0" >&2
        exit 1
    fi

    freqgov=$1
    host=$2
    
    if [[ $freqgov == 0 ]]; then
        
        ssh ganton12@$host "sudo cpupower frequency-set -g powersave"
        echo "set-frequencygovernor FUNC:set MSG: Node-$host frequency-governor powersave"
    
    elif [[ $freqgov == 1 ]]; then  
    
        ssh ganton12@$host "sudo cpupower frequency-set -g performance"
        echo "set-frequencygovernor FUNC:set MSG: Node-$host frequency-governor performance"

    elif [[ $freqgov == 2 ]]; then

        if [[ `ssh ganton12@$host "sudo cpupower frequency-info | grep intel_pstate | wc -l"` == 1 ]]; then
            echo "set-frequencygovernor FUNC:set MSG: Node-$host frequency-governor userspace, \
            cannot be used with intel_pstate driver!!!"
            exit 1
        else
            ssh ganton12@$host "sudo cpupower frequency-set -g userspace; sudo cpupower frequency-set -f 2200MHz"
            echo "set-frequencygovernor FUNC:set MSG: Node-$host frequency-governor userspace, 2.2GHz"
        fi
    elif [[ $freqgov == 3 ]]; then

        if [[ `ssh ganton12@$host "sudo cpupower frequency-info | grep intel_pstate | wc -l"` == 1 ]]; then
            echo "set-frequencygovernor FUNC:set MSG: Node-$host frequency-governor ondemand, \
            cannot be used with intel_pstate driver!!!"
            exit 1
        else
            ssh ganton12@$host "sudo cpupower frequency-set -g ondemand;"
            echo "set-frequencygovernor FUNC:set MSG: Node-$host frequency-governor ondemand"
        fi
    fi

    exit 0

}

##################################################################################
# Get configuration of the machine.
# 
# Arg 1:    node
get () {

    if [[ -z $1 ]]; then
        echo "set-frequencygovernor FUNC:get MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-frequencygovernor FUNC:get MSG:Usage: $(basename $0) get [node]" >&2
        echo "" >&2
        echo "set-frequencygovernor FUNC:get MSG:Example: $(basename $0) get node0" >&2
        exit 1
    fi

    temp=`ssh ganton12@$1 "sudo cpupower frequency-info"`
    echo "***FREQUENCY-GOVERNOR***: $temp"

    exit 0

}

##################################################################################
# Check arg configuratio value. Valid choices (0,1,2,3)
# 
# Arg 1:    configuration value
check_args () {

    if [[ -z $1 ]]; then
        echo "set-frequencygovernor FUNC:check_args MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-frequencygovernor FUNC:check_args MSG:Usage: $(basename $0) check_args [configuration_value]" >&2
        echo "" >&2
        echo "set-frequencygovernor FUNC:check_args MSG:Example: $(basename $0) check_args 0" >&2
        exit 1
    fi

    if [[ $1 -ne 0 && $1 -ne 1 && $1 -ne 2 && $1 -ne 3 ]]; then
        echo "set-frequencygovernor FUNC:check_args MSG:Invalid configuration value: $1 " >&2
        echo "" >&2
        echo "set-frequencygovernor FUNC:check_args MSG:Usage: $(basename $0) check_args [configuration_value]" >&2
        echo "" >&2
        echo "set-frequencygovernor FUNC:check_args MSG:Example: $(basename $0) check_args [0,1,2,3]" >&2
        exit 1
    else
        echo "set-frequencygovernor FUNC:check_args MSG:Arg test conf value: PASS " >&2
        exit 0
    fi

}
"$@"