#!/bin/bash


source ./servers.conf

get_cpu_usage(){
    cpu_float=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1); }' \
    <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat))
    echo ${cpu_float%.*}
}

get_ram_usage(){
    ram_float=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    echo ${ram_float%.*}
}

networkInterface=$(route | grep '^default' | grep -o '[^ ]*$')
ip="$(ifconfig ${networkInterface} | grep 'inet ' | awk '{print $2}')"

DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0

main_menu() {
    exec 3>&1
    selection=$(dialog \
    --title "Menu" \
    --clear \
    --cancel-label "Exit" \
    --menu "Please select:" $HEIGHT $WIDTH 4 \
    "1" "Display System Information" \
    "2" "Configuration" \
    2>&1 1>&3)
    exit_status=$?
    exec 3>&-
    case $exit_status in
    $DIALOG_CANCEL)
      clear
      echo "Program terminated."
      exit
      ;;
    $DIALOG_ESC)
      clear
      echo "Program aborted." >&2
      exit 1
      ;;
    esac
    main_menu_selection
}

main_menu_selection() {
    case $selection in
    0 )
      clear
      echo "Program terminated."
      ;;
    1 )
        while :
        do
        display_monitor
        done &
        read
        echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)" > file
        kill $!
      ;;
    2 )
        configuration_menu
      ;;
    esac
}

configuration_menu() {
    exec 3>&1
    selection=$(dialog \
    --title "Menu" \
    --clear \
    --cancel-label "Exit" \
    --menu "Please select:" $HEIGHT $WIDTH 4 \
    "1" "Add new server" \
    "2" "Remove server" \
    2>&1 1>&3)
    case $selection in
    0 )
      clear
      echo "Program terminated."
      ;;
    1 )
        VALUES=$(dialog --ok-label "Submit" \
	    --backtitle "Linux User Managment" \
	    --title "Useradd" \
	    --form "Create a new user" \
        15 50 0 \
	    "User:" 1 1	"$user" 	1 10 30 0 \
	    "IP:"    2 1	"$shell"  	2 10 30 0 \
        2>&1 1>&3)
      ;;
    2 )
      
      ;;
    esac
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

DATA[0]=0

while true; do
  main_menu
done
