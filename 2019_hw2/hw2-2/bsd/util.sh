#!/bin/bash
h=30	# dialog height 0=auto
w=60	# dialog width 0=auto
mh=30	# dialog menu height 0=auto
readsec=3 # read, wait 3 sec for input

convert_unit()
{
	unit=(B KB MB GB TB)
	val=$1
	idx=0
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
	model=`sysctl -n hw.model`
	machine=`sysctl -n hw.machine`
	ncpu=`sysctl -n hw.ncpu`
	dialog --msgbox "CPU Info\n\nCPU Model: $model\nCPU Machine: $machine\nCPU Core: $ncpu" $h $w
}

mem_info()
{
	while true; do
		msg="Memory Info and Usage\n\n"
		## show memory info according to how htop calculates memory usage
		##    htop source code-> htop/freebsd/FreeBSDProcessList.c:284 : static inline void FreeBSDProcessList_scanMemoryInfo
		##    total_mem: hw.physmem
		##    used_mem: active_mem + wired_mem
		##        active_mem = vm.stats.vm.v_active_count * vm.stats.vm.v_page_size 
		##        wired_mem = vm.stats.vm.v_wire_count * vm.stats.vm.v_page_size - kstat.zfs.misc.arcstats.size
		##    free_mem: total_mem - used_mem
#		total_mem=`sysctl -n hw.physmem`
		total_mem=`sysctl -n hw.realmem`
		page_size=`sysctl -n vm.stats.vm.v_page_size`
		active_mem=$(($(sysctl -n vm.stats.vm.v_active_count) * $page_size))
		wired_mem=$(( $(( $(sysctl -n vm.stats.vm.v_wire_count) * $page_size )) - $(sysctl -n kstat.zfs.misc.arcstats.size) ))
		used_mem=$(($active_mem + $wired_mem))
		free_mem=$(($total_mem - $used_mem))
		
		## convert unit
		read number base < <(convert_unit $total_mem)
		msg="${msg}Total: $number $base\n"
		read number base < <(convert_unit $used_mem)
		msg="${msg}Used: $number $base\n"
		read number base < <(convert_unit $free_mem)
		msg="${msg}Free: $number $base\n"
		percent=`bc <<< "$used_mem *100/ $total_mem"`

		## dialog
		dialog --mixedgauge "$msg" $h $w "$percent"
		read -t $readsec
		if [ $? -eq 0 ] && [ -z $REPLY ]; then
			break
		fi
	done
}

net_info()
{
	while true; do
		# first menu
		interfaces=`netstat -i | awk '{if($1 != "Name") print $1}' | sort | uniq`
		dialog="dialog --stdout --title 'Network Interfaces' --menu '' $h $w $mh"
		for i in $interfaces; do
			dialog="$dialog $i '*'"
		done
		option=`eval $dialog`
		if [ -z $option ]; then
			break
		fi
		# info of interface
<<padded_version	
		pad='_______'
		
		IPv4='IPv4'
		IPv4=`printf '%s %s' $IPv4 ${pad:${#IPv4}}`
		ipv4=`ifconfig $option | grep "\<inet\>" | awk '{print $2}'`
		Netmask='Netmask'
		Netmask=`printf '%s %s' $Netmask ${pad:${#Netmask}}`
		netmask=`ifconfig $option | grep "\<inet\>" | awk '{print $4}'`

		Mac='Mac'
		Mac=`printf '%s %s' $Mac ${pad:${#Mac}}`
		mac=`ifconfig $option | grep ether | awk '{print $2}'`

		msg="Interface Name: $option\n\n${IPv4}: ${ipv4}\n${Netmask}: ${netmask}\n${Mac}: ${mac}"
padded_version

		ipv4=`ifconfig $option | grep "\<inet\>" | awk '{print $2}'`
		netmask=`ifconfig $option | grep "\<inet\>" | awk '{print $4}'`
		mac=`ifconfig $option | grep ether | awk '{print $2}'`
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
			read filesize unit < <(convert_unit $filesize)
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
	ncpu=`sysctl -n hw.ncpu`
	while true; do
		dialog=`top -P -d 2 | grep ^CPU | tail -n $ncpu | sed 's/%//g' |\
				awk 'BEGIN { total=0; id=0; print "dialog --mixedgauge \"CPU Loading\\\n"}\
				{\
					user=($3 + $5);\
					sys=($7 + $9);\
					idle=$11;\
					printf "\\\n%s%d: USER: %04.1f%% SYST: %04.1f%% IDLE: %04.1f%%", "CPU", id, user, sys, idle;\
					id++;\
					total=total+user+sys;\
				}\
				END {printf "%s %d %d %d", "\"", 30, 60, total/id }'`

		eval $dialog
		read -t $readsec
		if [ $? -eq 0 ] && [ -z $REPLY ]; then
			break
		fi
	done

}

show_menu()
{
	## the result of dialog is outputed to stderr by default, see man dialog
	exec 3>&1
	result=`dialog --menu "SYS INFO" $h $w $mh 1 "CPU INFO" 2 "MEMORY INFO" 3 "NETWORK INFO" 4 "FILE BROWSER" 5 "CPU USAGE" 2>&1 1>&3`
	echo $result
	exec 3>&-

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
