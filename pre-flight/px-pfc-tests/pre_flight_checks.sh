#!/bin/bash

### REQUIREMENTS ###
PX_RAM=4
PX_CPUS=4
PX_CORES=4
PX_VAR_LEFT=2
PX_BK_DR=8
PX_PORTS_BEGIN=9001
PX_PORT_END=9016
PX_PORT_LH_78=32678
PX_PORT_LH_78=32679
PX_KERNEL_VERSION=3.10
PX_DOCKER_VERSION=1.13.1

RED='\033[0;31m'
NC='\033[0m' # No Color



vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

testvercomp () {
    vercomp $1 $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    if [[ $op != $3 ]]
    then
        echo "FAIL: Expected '$3', Actual '$op', Arg1 '$1', Arg2 '$2'"
    else
        # echo "Pass: '$1 $op $2'"
   	echo -e "\033[0;32mPASS\033[0m" 
        #echo "$1"
    fi
}


echo "--- BEGIN TESTS FOR "`hostname` " ---"
######## BEGIN RAM ##########
echo -ne "MEM:\t\t "
if [ ! -f /proc/meminfo ]; then
    echo -e "\033[0;31mFAIL\033[0m" " (/proc/meminfo not found!)"
else
    RAM=`cat /proc/meminfo | grep MemT | awk '{print $2}'`
    # echo $RAM
    if [ ${RAM%%.*} -gt ${PX_RAM%%.*} ]; then 
        echo -e "\033[0;32mPASS\033[0m"
        #echo $RAM
    else
        echo -e "\033[0;31mFAIL\033[0m"
    fi
fi;

########## END RAM ###########


# CPUS=`cat /proc/cpuinfo | grep processor | wc -l`
# echo $CPUS
# if [ $CPUS \>= $PX_CPUS ];
# then
#     echo "PASS";
# else
#     echo "FAILED";
# fi;


########### BEGIN CORES ##########

echo -ne "#CORES:\t\t "
if [ ! -f /proc/cpuinfo ]; then
    echo -e "\033[0;31mFAIL\033[0m" " (/proc/cpuinfo not found!)"
else 
    CORES=`cat /proc/cpuinfo | grep 'cpu cores' | wc -l`
    # echo $CORES
    if [ $CORES -gt $PX_CORES ]; then
        echo -e "\033[0;32mPASS\033[0m"
        echo $CORES
    else
        echo -e "\033[0;31mFAIL\033[0m"  " ($CORES found!)"
    fi
fi
############## BEGIN VAR #################


VAR_LEFT=`df -hT /var | grep dev | awk '{print $3}' | sed 's/G//g'`
#echo $VAR_LEFT
echo -ne "/VAR:\t\t "
if [ -z "$VAR_LEFT" ]; then
    echo -e "\033[0;31mFAIL\033[0m" " (/var not found!)"
else
    if (( ${VAR_LEFT%%.*} >= ${PX_VAR_LEFT%%.*} )); then
        echo -e "\033[0;32mPASS\033[0m"
    else
        echo -e "\033[0;31mFAIL\033[0m"
    fi
fi

# echo $SELINUX
echo -ne "SELINUX:\t "
if ! [ -x "$(command -v getenforce)" ]; then
    echo -e "\033[0;32mPASS\033[0m"
else
    SELINUX=`getenforce`
    if [ "$SELINUX" != "disabled" ]; then
        echo -e "\033[0;32mPASS\033[0m"
        echo $SELINUX
    else
        echo -e "\033[0;31mFAIL\033[0m"
    fi;
fi


KERNEL_VERSION=`uname -r | sed 's/-.*$//g'`
# echo $KERNEL_VERSION
echo -ne "DOCKER:\t\t "
testvercomp $KERNEL_VERSION $PX_KERNEL_VERSION ">"


DOCKER_VERSION=`docker --version | awk '{print $3}' | sed 's/-.*$//g'`
# echo $DOCKER_VERSION
echo -ne "KERNEL:\t\t "
testvercomp $DOCKER_VERSION $PX_DOCKER_VERSION ">"


echo -ne "PING:\t\t "
if [ "`ping -c 1 8.8.8.8`" ]
then
   echo -e "\033[0;32mPASS\033[0m"
else
   echo -e "\033[0;31mFAIL\033[0m"
fi

echo -ne "SWAP:\t\t "

if ! [ -x "$(command -v swapon)" ]; then
    if [ ! -f /proc/meminfo ]; then
        echo -e "\033[0;31mFAIL\033[0m" " (/proc/meminfo not found!)"
    else
        if [ `cat /proc/meminfo | grep 'SwapTotal' | awk  '{print $2}'` != 0 ]; then
            echo -e "\033[0;31mFAIL\033[0m"
        else
            echo -e "\033[0;32mPASS\033[0m"
        fi
    fi
else
    if [[ $(swapon -s) ]]; then
        echo -e "\033[0;31mFAIL\033[0m"
    else
        echo -e "\033[0;32mPASS\033[0m"
    fi
fi


echo "--- END TESTS FOR" `hostname` "@"  `date +%Y/%m/%d-%H:%M:%S` "---"

exit 0

