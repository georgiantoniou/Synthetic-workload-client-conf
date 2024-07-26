#!/bin/bash

####################################################################################################
# This script is used to enable/disable c-states from the grub file. It has 5 functions
#   1) check_args:  Check args it checks the format of the input parameter. set-cstate.sh currently
#                   recognizes the following inputs
#                   -> 0: only C0 (intel_idle.max_cstate=0 idle=poll) 
#                   -> 1: C0/C1 (intel_idle.max_cstate=1)
#                   -> 2: C0/C1/C1E (intel_idle.max_cstate=2)
#                   -> 3: C0/C1/C1E/C6 (remove intel_idle.max_cstate from grub file if exists)
#                   It takes as an argument the following:
#                   -> Arg1: Configuration Value
# 
#   2) set:    Changes the grub file based on the configuration parameter. It takes as an arg
#                   the following:
#                   -> Arg1: Configuration Value 
#                   -> Arg2: Node to change configuration
#
#   3) reset:  Reset the initial c-state configuration of the grub file which is the
#                   configuration wih the value 3.
#                   -> Arg1: Node to change configuration
#
#   4) check_reset: Check whether we need to reset the configuration and reboot the machine. 
#                   Specifically, whether /proc/cmdline contains c-state configuration   
#                   -> Arg1: Node 
#                   -> Arg2: Configuration Value  
#
#   5) get:         Return the c-state configuration of a node. Returns /proc/cmdline.
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
        echo "set-cstates FUNC:check_reset MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-cstates FUNC:check_reset MSG:Usage: $(basename $0) check_reset [node] [configuration_value]" >&2
        echo "" >&2
        echo "set-cstates FUNC:check_reset MSG:Example: $(basename $0) check_reset node0 0" >&2
        exit 1
    fi
    
    if [[ $2 == 0 && `ssh ganton12@$1 "cat /proc/cmdline | grep \"intel_idle.max_cstate=0 idle=poll\" | wc -l"` == 1 ]]; then
        echo "set-cstates FUNC:check_reset MSG:No need to reboot $1" >&2
        exit 0
    elif [[ $2 == 1 && `ssh ganton12@$1 "cat /proc/cmdline | grep \"intel_idle.max_cstate=1\" | wc -l"` == 1 ]]; then
        echo "set-cstates FUNC:check_reset MSG:No need to reboot $1" >&2
        exit 0
    elif [[ $2 == 2 && `ssh ganton12@$1 "cat /proc/cmdline | grep \"intel_idle.max_cstate=2\" | wc -l"` == 1 ]]; then
        echo "set-cstates FUNC:check_reset MSG:No need to reboot $1" >&2
        exit 0
    elif [[ $2 == 3 && `ssh ganton12@$1 "cat /proc/cmdline | grep \"intel_idle.max_cstate\" | wc -l"` == 0 ]]; then
        echo "set-cstates FUNC:check_reset MSG:No need to reboot $1" >&2
        exit 0
    else
        echo "set-cstates FUNC:check_reset MSG:Need to reboot $1" >&2
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
        echo "set-cstates FUNC:reset MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-cstates FUNC:reset MSG:Usage: $(basename $0) reset [node]" >&2
        echo "" >&2
        echo "set-cstates FUNC:reset MSG:Example: $(basename $0) reset 0 node0" >&2
        exit 1
    fi

    ssh ganton12@$host "sudo sed -i 's/\(^GRUB_CMDLINE_LINUX=\".*\) intel_idle.max_cstate=[^[:space:]]*\(.*\"\)/\1\2/' /etc/default/grub"
    ssh ganton12@$host "sudo sed -i 's/\(^GRUB_CMDLINE_LINUX=\".*\) idle=[^[:space:]]*\(.*\"\)/\1\2/' /etc/default/grub"
    echo "set-cstates FUNC:reset MSG:$host reset" >&2
}

##################################################################################
# Set configuration Value.
# 
# Arg 1:    configuration value
# Arg 2:    node
set () {

    if [[ -z $1 || -z $2 ]]; then
        echo "set-cstates FUNC:set MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-cstates FUNC:set MSG:Usage: $(basename $0) set [configuration_value] [node]" >&2
        echo "" >&2
        echo "set-cstates FUNC:set MSG:Example: $(basename $0) set 0 node0" >&2
        exit 1
    fi

    cstate=$1
    host=$2
    flagstoadd=""

    reset $2

    if [[ $cstate == "0" ]]; then
        flagstoadd=$flagstoadd"intel_idle.max_cstate=0 idle=poll"
    elif [[ $cstate == "1" ]]; then
        flagstoadd=$flagstoadd"intel_idle.max_cstate=1"
    elif [[ $cstate == "2" ]]; then
        flagstoadd=$flagstoadd"intel_idle.max_cstate=2"
    fi

    ssh ganton12@$host "sudo sed -i 's/\(^GRUB_CMDLINE_LINUX=\".*\)\"/\1 $flagstoadd\"/' /etc/default/grub"
    echo "set-cstates FUNC:set MSG: Node-$host Flag-$flagstoadd"

    ssh ganton12@$host "sudo update-grub2"
    echo "set-cstates FUNC:set MSG: Node-$host update-grub2"

    exit 0

}

##################################################################################
# Get configuration of the machine.
# 
# Arg 1:    node
get () {

    if [[ -z $1 ]]; then
        echo "set-cstates FUNC:get MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-cstates FUNC:get MSG:Usage: $(basename $0) get [node]" >&2
        echo "" >&2
        echo "set-cstates FUNC:get MSG:Example: $(basename $0) get node0" >&2
        exit 1
    fi

    temp=`ssh ganton12@$1 "cat /proc/cmdline"`
    echo "***CSTATES***: $temp"
    
    exit 0

}


##################################################################################
# Check arg configuratio value. Valid choices (0,1,2,3)
# 
# Arg 1:    configuration value
check_args () {

    if [[ -z $1 ]]; then
        echo "set-cstates FUNC:check_args MSG:Invalid argument list length: " >&2
        echo "" >&2
        echo "set-cstates FUNC:check_args MSG:Usage: $(basename $0) check_args [configuration_value]" >&2
        echo "" >&2
        echo "set-cstates FUNC:check_args MSG:Example: $(basename $0) check_args 0" >&2
        exit 1
    fi

    if [[ $1 -ne 0 && $1 -ne 1 && $1 -ne 2 && $1 -ne 3 ]]; then
        echo "set-cstates FUNC:check_args MSG:Invalid configuration value: $1 " >&2
        echo "" >&2
        echo "set-cstates FUNC:check_args MSG:Usage: $(basename $0) check_args [configuration_value]" >&2
        echo "" >&2
        echo "set-cstates FUNC:check_args MSG:Example: $(basename $0) check_args [0,1,2,3]" >&2
        exit 1
    else
        echo "set-cstates FUNC:check_args MSG:Arg test conf value: PASS " >&2
        exit 0
    fi

}
"$@"