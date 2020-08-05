#!/bin/bash

source ./servers.conf

DATA[0]=0

get_cpu_usage(){
    cpu_float=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1); }' \
    <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat))
    echo ${cpu_float%.*}
}

get_ram_usage(){
    ram_float=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    echo ${ram_float%.*}
}

display_monitor() {
    unset DATA
    DATA+=("IP: ${ip}" "0")
    DATA+=("CPU usage" "-$(get_cpu_usage)")
    DATA+=("RAM usage" "-$(get_ram_usage)")
    for server in ${servers[@]}
    do
        DATA+=("" "")
        DATA+=("IP: $(echo $server | cut -d "@" -f 2)" "0")
        DATA+=("CPU usage" "-$(ssh ${server} "$(typeset -f get_cpu_usage); get_cpu_usage")")
        DATA+=("RAM usage" "-$(ssh ${server} "$(typeset -f get_ram_usage); get_ram_usage")")
    done
    dialog --title "Simple System Monitor " "$@" \
        --mixedgauge "Press enter to go back to menu" \
            0 0 0 \
            "${DATA[@]}" 
            
    sleep 1 
}

networkInterface=$(route | grep '^default' | grep -o '[^ ]*$')
ip="$(ifconfig ${networkInterface} | grep 'inet ' | awk '{print $2}')"

while :
do
display_monitor
done
        


