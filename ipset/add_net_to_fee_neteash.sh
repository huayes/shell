#!/bin/bash
PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

ipset_name_temp=Fee_Netease_temp
ipset_name=Fee_Netease
cidr_file=/home/fee_admin/feedata/cidr.txt

# define directory
ROOT=/home/fee_admin/var
LOG=$ROOT/log
RUN=$ROOT/run

# log file
LOG0=$LOG/update_ipset.log
# tag file
RUN_TAG=$RUN/update_ipset_running.tag

# defile funtions
datef() { date "+%Y/%m/%d %H:%M:%S" ; }
print_to_log() { echo "[$(datef)] $1" >> $LOG0 ; }
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

# create log dir
[ ! -d "$LOG" ] && mkdir -p $LOG
# create run dir
[ ! -d "$RUN" ] && mkdir -p $RUN

if [ ! -f "${cidr_file}" ]; then
    print_to_log "not exist file: ${cidr_file}, exit!"
    echo "not exist file: ${cidr_file}, exit!"
    exit 1
fi

if [ -f "${RUN_TAG}" ]; then
    print_to_log "Last process still running, exit!"
    echo "Last process still running, exit!"
    exit 1
else
    touch ${RUN_TAG}
fi

print_to_log "---------$(datef)-----------"
# create log dir
# if ipset does not exist, create it
sudo ipset create -exist ${ipset_name_temp} hash:net
sudo ipset create -exist ${ipset_name} hash:net

print_to_log "Begin to add net into ${ipset_name_temp}"
if [ -s ${cidr_file} ]; then
    while read net ; do
        valinet $net
        if [ "$?" -eq "0" ]; then
            sudo ipset add ${ipset_name_temp} $net
            if [ "$?" -ne "0" ]; then
                print_to_log "ipset add ${ipset_name_temp} $net failed"
                echo "ipset add ${ipset_name_temp} $net failed"
                rm ${RUN_TAG}
                exit 1
            fi
        else
            print_to_log "invalid net address: $net"
            echo "invalid net address: $net"
            rm ${RUN_TAG}
            exit 1
        fi
    done < ${cidr_file}
fi
print_to_log "End to add net into ${ipset_name_temp}"

print_to_log "Begin to ipset swap ${ipset_name_temp} ${ipset_name}"
sudo ipset swap ${ipset_name_temp} ${ipset_name}
if [ "$?" -ne "0" ]; then
    print_to_log "ipset swap ${ipset_name_temp} ${ipset_name} failed!"
    echo "ipset swap ${ipset_name_temp} ${ipset_name} failed!"
    rm ${RUN_TAG}
    exit 1
fi
print_to_log "End to ipset swap ${ipset_name_temp} ${ipset_name}"

print_to_log "Begin to ipset destroy ${ipset_name_temp}"
sudo ipset destroy ${ipset_name_temp}
if [ "$?" -ne "0" ]; then
    print_to_log "ipset destroy ${ipset_name_temp} failed"
    echo "ipset destroy ${ipset_name_temp} failed"
    rm ${RUN_TAG}
    exit 1
fi
print_to_log "End to ipset destroy ${ipset_name_temp}"

rm ${RUN_TAG}
print_to_log "---------$(datef)-----------"
