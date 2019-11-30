#!/bin/bash
h=30	# dialog height 0=auto
w=60	# dialog width 0=auto
mh=30	# dialog menu height 0=auto

convert_unit()
{
	unit=(B KB MB GB TB)
	val=$1
	idx=$2
	while true ;do
		if [ `echo ${val} | awk '{if($1 < 1024.0) print "1"; else print "0"}'` -eq 1 ]; then
			val=`echo $val | awk '{printf "%.2f", $1}'`
			echo $val ${unit[${idx}]}
			break
		else
			val=`echo $val | awk '{printf "%.2f", $1/1024.0}'`
			idx=$(($idx +1))
		fi
	done
}

cpu_info()
{
	model=`lscpu | grep "Model name" | awk -F':' '{print $2}' | sed 's/^[[:space:]]*//g'`
	machine=`lscpu | grep "Architecture" | awk -F':' '{print $2}' | sed 's/^[[:space:]]*//g'`
	ncpu=`lscpu | grep "^CPU(s)" | awk -F':' '{print $2}' | sed 's/^[[:space:]]*//g'`
	dialog --msgbox "CPU Info\n\nCPU Model: $model\nCPU Machine: $machine\nCPU Core: $ncpu" $h $w
}

mem_info()
{
	while true; do
		msg="Memory Info and Usage\n\n"
		# unit is already kB
		total_mem=`cat /proc/meminfo | grep MemTotal: | awk '{print $2}' | sed 's/^[[:space:]]*//g'`	
		free_mem=`cat /proc/meminfo | grep MemAvailable: | awk '{print $2}' | sed 's/^[[:space:]]*//g'`
		used_mem=$(($total_mem - $free_mem))
		
		## convert unit
		read number base < <(convert_unit $total_mem 1)
		msg="${msg}Total: $number $base\n"
		read number base < <(convert_unit $used_mem 1)
		msg="${msg}Used: $number $base\n"
		read number base < <(convert_unit $free_mem 1)
		msg="${msg}Free: $number $base\n"
		percent=`bc <<< "$used_mem *100/ $total_mem"`

		## dialog
		dialog --mixedgauge "$msg" $h $w "$percent"
		read -t 1
		if [ $? -eq 0 && -z $REPLY ]; then
			break
		fi
	done
}

net_info()
{
	while true; do
		# first menu
		interfaces=`nmcli device status | awk '(NR != 1) {print $1}'`
		dialog="dialog --stdout --title 'Network Interfaces' --menu '' $h $w $mh"
		for i in $interfaces; do
			dialog="$dialog $i '*'"
		done
		option=`eval $dialog`

		if [ -z $option ]; then
			break
		fi
		# info of interface

		ipv4=`ip addr show $option | grep "\<inet\>" | awk '{print $2}' | awk -F'/' '{print $1}'`
		netmask=`ip addr show $option | grep "\<inet\>" | awk '{print $2}' | awk -F'/' '{print $2}'`
		mac=`ip addr show $option | grep "link/ether" | awk '{print $2}'`
		msg="Interface Name: ${option}\n\nIPv4: ${ipv4}\nNetmask: ${netmask}\nMac: ${mac}"
		dialog --msgbox "$msg" $h $w

	done
}

browse_file()
{
	while true; do
		dialog="dialog --stdout --menu 'File Browser: $(pwd)' $h $w $mh "
		# brace expansion has to used with comma
		# ex. for i in {.*}; do echo $i; done	// output: {*}
		# ex. for i in .*; do echo $i; done		// output: "$all_hidden_files_in_$pwd"
		for file in {.,}*; do					# all the files in current directory
			item=`file --mime-type $file | sed 's/://g'`
			dialog="$dialog $item"
		done

		option=`eval $dialog`
		if [ -z $option ]; then
			break
		elif [ -d $option ]; then
			ls $option > /dev/null
			if [ $? -ne 0 ]; then
				dialog --msgbox "permission denied!" $h $w
				continue
			else
				cd $option
			fi
		else
			filename=$option
			fileinfo=`file $filename | awk '{print $2}'`
			filesize=`ls -l $filename | awk '{print $5}'`
			read filesize unit < <(convert_unit $filesize 0)
			file $filename | grep text > /dev/null	# determine if it's a text file
			if [ $? -eq 0 ]; then
				dialog --stdout --extra-button --extra-label 'EDIT' --msgbox "<File Name>: $filename\n<File Info>: $fileinfo\n<File Size>: $filesize $unit" $h $w
				if [ $? -eq 3 ]; then
					$EDITOR $filename
				fi
			else
				dialog --stdout --msgbox "<File Name>: $filename\n<File Info>: $fileinfo\n<File Size>: $filesize $unit" $h $w
			fi
		fi
	done
}


cpu_usage()
{
	# top output
	# us(user), sy(system), ni(nice), id(idle), wa(wait), hi(hardware interrupt), si(soft inter), st(steal) // see man top(1) Section 2b.
	# cpu usage:
	#    user = $us + $ni
	#    idle = $id + $wa
	#    sys  = 100 - $user - $idle
	[ -f .toprc ] && cp .toprc ~/
	while true; do
		dialog=`top -bn1 | grep ^%Cpu |\
				awk 'BEGIN {total=0; id=0; print "dialog --mixedgauge \"CPU Loading\\\n"}\
				{\
					user = $3 + $7;\
					idle = $9 + $11;\
					sys = 100.0 - user - idle;\
					printf "\\\nCPU%d: USER: %04.1f%% SYST: %04.1f%% IDLE: %04.1f%%", \
					id, user, sys, idle;
					id++;
					total = total + user + sys;
				}\
				END {printf "\" 30 60 %d", total/id}'`
		
		eval $dialog
		
		read -t 1
		if [ $? -eq 0 ] && [ -z $REPLY ]; then
			break
		fi
	done

}

show_menu()
{
	## the result of dialog is outputed to stderr by default, see man dialog
	result=`dialog --stdout --menu "SYS INFO" $h $w $mh\
			1 "CPU INFO" 2 "MEMORY INFO" 3 "NETWORK INFO" 4 "FILE BROWSER" 5 "CPU USAGE"`

	case $result in
		"1")
			cpu_info;;
		"2")
			mem_info;;
		"3")
			net_info;;
		"4")
			browse_file;;
		"5")
			cpu_usage;;
		"")
			echo "Action has been cancelled!"
			exit;;
		*)
			echo "no";;
	esac
}
