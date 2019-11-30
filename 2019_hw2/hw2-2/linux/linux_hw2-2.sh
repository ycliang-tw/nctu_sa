#!/bin/bash
## program flow
##	source util.sh -> trap termination signals -> main

cl_routine()
{
	dialog --msgbox "bye~bye~!" 0 0
	exit 
}


main()
{
	while true; do
		show_menu
	done
}

# set -x
. util.sh
trap "cl_routine" 2 3 18 
main

unit_test()
{
	# [V] cpu_info
	# [V] mem_info
	# [V] net_info
	# [V] browse_file
	# [V] cpu_usage
}

#unit_test

