#!/bin/bash
PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

change_cidr_file=/home/fee_admin/var/change_cidr.txt
ipset_name=Fee_Netease
#ipset_name="test"

# define directory
ROOT=/home/fee_admin/var
LOG=$ROOT/log
RUN=$ROOT/run

# log file
LOG0=$LOG/auto_update_ipset.log
# tag file
RUN_TAG=$RUN/auto_update_ipset_running.tag

# defile funtions
datef() { date "+%Y/%m/%d %H:%M:%S" ; }
print_to_log() { echo "[$(datef)] $1" >> "$LOG0" ; }
# valinet function
valinet()
{
    local net=$1
    local stat=1
    if [[ $net =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}$ ]]; then
        ip=$(echo $net|cut -d/ -f1)
        netmask=$(echo $net|cut -d/ -f2)
        ip_array=(${ip//./ })
        if [[ $netmask -le 32 && ${ip_array[0]} -le 255 && ${ip_array[1]} -le 255 && ${ip_array[2]} -le 255 && ${ip_array[3]} -le 255 ]]; then
            stat=0
        fi
    fi
    return $stat
}

# alert function
alert()
{
    local msg=$1
    if [ -f "/usr/local/bin/alert.py" ]; then
        alert.py -m "$msg"
    fi
}

# create log dir
[ ! -d "$LOG" ] && mkdir -p $LOG
# create run dir
[ ! -d "$RUN" ] && mkdir -p $RUN

if [ -f "${RUN_TAG}" ]; then
    print_to_log "Last process still running, exit!"
    echo "Last process still running, exit!"
    exit 1
else
    touch ${RUN_TAG}
fi

if [ ! -f "${change_cidr_file}" ]; then
    print_to_log "not exist file: ${change_cidr_file}, exit!"
    echo "not exist file: ${change_cidr_file}, exit!"
    rm ${RUN_TAG}
    exit 1
fi



print_to_log "---------$(datef)-----------"
print_to_log "Begin to auto to operator ${ipset_name}"
if [ -s ${change_cidr_file} ]; then
    while read line ; do
        opt=${line:0:1}
        net=${line:1}
        if [ "$opt" = "-" ]; then
            valinet $net
            if [ "$?" -eq "0" ]; then
            	#ip=$(echo $net|cut -d/ -f1)
            	#netmask=$(echo $net|cut -d/ -f2)
                sudo ipset test ${ipset_name} $net > /dev/null 2>&1
                if [ "$?" -eq "0" ]; then
                	#if [ "$netmask" -eq "32" ]; then
                	#	targe=$ip
                	#else
                	#	targe=$net
                	#fi
                    print_to_log "Begin to ipset del ${ipset_name} $net"
                    sudo ipset del ${ipset_name} $net
                    if [ "$?" -ne "0" ]; then
                        print_to_log "ipset del ${ipset_name} $net failed"
                        echo "ipset del ${ipset_name} $net failed"
                        alert "cidr: ipset del ${ipset_name} $net failed"
                        rm ${RUN_TAG}
                        exit 1
                    fi
                    print_to_log "End to ipset del ${ipset_name} $net"
                fi
            else
                print_to_log "invalid net address($net) in cidr file"
                echo "invalid net address($net) in cidr file"
                alert "invalid net address($net) in cidr file"
    		fi
    	elif [ "$opt" = "+" ]; then
            valinet $net
            if [ "$?" -eq "0" ]; then
                sudo ipset test ${ipset_name} $net > /dev/null 2>&1
                if [ $? -ne "0" ]; then
                    print_to_log "Begin to ipset add ${ipset_name} $net"
                    sudo ipset add ${ipset_name} $net
                    if [ "$?" -ne "0" ]; then
                        print_to_log "ipset add ${ipset_name} $net failed"
                        echo "ipset add ${ipset_name} $net failed"
                        alert "cidr: ipset add ${ipset_name} $net failed"
                        rm ${RUN_TAG}
                        exit 1
                    fi
                    print_to_log "End to ipset add ${ipset_name} $net"
                fi
            else
                print_to_log "invalid net address($net) in cidr file"
                echo "invalid net address($net) in cidr file"
                alert "invalid net address($net) in cidr file"
            fi
        fi
    done < ${change_cidr_file}
fi
print_to_log "End to auto to operator ${ipset_name}"

rm ${RUN_TAG}
print_to_log "---------$(datef)-----------"
print_to_log ""
