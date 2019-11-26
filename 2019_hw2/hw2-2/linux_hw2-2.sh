#!/bin/bash
# show_menu
#	show the menu of SIM(System Information Monitor)
# cpu_info
#	show cpu info
# mem_info
# 	show memory info
# net_info
#	show network interfaces info
# browse_file
#	simple file browser

## program flow
##	source util.sh -> trap termination signals -> main


cpu_info()
{
	echo haha	
}

show_menu()
{
	result=`dialog --stdout --menu "SYS INFO" 30 60 10 1 "CPU_INFO" 2 "MEMORY INFO" 3 "NETWORK INFO" 4 "FILE BROWSER"`

	case $result in
		"1")
			echo "option one"
			;;
		"2")
			echo "option two"
			;;
		"3")
			echo "option three"
			;;
		"4")
			echo "option four"
			;;
		"")
			echo "Action has been cancelled!"
			;;
		*)
			echo "no"
			;;
	esac
}

main()
{
	show_menu
#	cpu_info
#	mem_info
#	net_info
#	browse_file
}

main
