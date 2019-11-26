
convert_unit()
{
	unit=(B KB MB GB TB)
	val=$1
	idx=0
	while true ;do
		if [ `echo ${val} | awk '{if($1 < 1024.0) print "1"; else print "0"}'` -eq 1 ]; then
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
	dialog --msgbox "CPU Info\nCPU Model: $model\nCPU Machine: $machine\nCPU Core: $ncpu"  30 60
}

mem_info()
{
	msg="Memory Info and Usage\n\n"
	## show memory info according to how htop calculates memory usage
	##    htop source code-> htop/freebsd/FreeBSDProcessList.c:284 : static inline void FreeBSDProcessList_scanMemoryInfo
	##    total_mem: hw.physmem
	##    used_mem: active_mem + wired_mem
	##        active_mem = vm.stats.vm.v_active_count * vm.stats.vm.v_page_size 
	##        wired_mem = vm.stats.vm.v_wire_count * vm.stats.vm.v_page_size - kstat.zfs.misc.arcstats.size
	##    free_mem: total_mem - used_mem
#	total_mem=`sysctl -n hw.physmem`
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
	while true; do
		dialog --mixedgauge "$msg" 30 60 "$percent"
		read -t 1
		if [ -z $REPLY ]; then
			break
		fi
	done
}

net_info()
{
	# first menu
	interfaces=`netstat -i | awk '{if($1 != "Name") print $1}' | sort | uniq`
	dialog="dialog --stdout --title 'Network Interfaces' --menu '' 30 60 10"
	for i in $interfaces; do
		dialog="$dialog $i '*'"
	done
	option=`eval $dialog`
	
	# info of interface
<<padded_version	
	pad='_______'
	
	IPv4='IPv4'
	IPv4=`printf '%s %s' $IPv4 ${pad:${#IPv4}}`
	ipv4=`ifconfig $option | grep inet | awk '{print $2}'`
	Netmask='Netmask'
	Netmask=`printf '%s %s' $Netmask ${pad:${#Netmask}}`
	netmask=`ifconfig $option | grep inet | awk '{print $4}'`

	Mac='Mac'
	Mac=`printf '%s %s' $Mac ${pad:${#Mac}}`
	mac=`ifconfig $option | grep ether | awk '{print $2}'`

	msg="Interface Name: $option\n\n${IPv4}: ${ipv4}\n${Netmask}: ${netmask}\n${Mac}: ${mac}"
padded_version

	ipv4=`ifconfig $option | grep inet | awk '{print $2}'`
	netmask=`ifconfig $option | grep inet | awk '{print $4}'`
	mac=`ifconfig $option | grep ether | awk '{print $2}'`
	msg="Interface Name: ${option}\n\nIPv4: ${ipv4}\nNetmask: ${netmask}\nMac: ${mac}"
	dialog --msgbox "$msg" 30 60 
}

show_menu()
{
	## the result of dialog is outputed to stderr by default, see man dialog
	exec 3>&1
	result=`dialog --menu "SYS INFO" 30 60 10 1 "CPU_INFO" 2 "MEMORY INFO" 3 "NETWORK INFO" 4 "FILE BROWSER" 2>&1 1>&3`
	echo $result
	exec 3>&-

	case $result in
		"1")
			cpu_info
			;;
		"2")
			mem_info
			;;
		"3")
			echo "option three"
			;;
		"4")
			echo "option four"
			;;
		"")
			echo "Action has been cancelled!"
			exit
			;;
		*)
			echo "no"
			;;
	esac
}
