#!/bin/bash

## program flow
##	source util.sh -> trap termination signals -> main
#set -x

. util.sh	# source util.sh

browse_file()
{
	echo browse
}

main()
{
<< comment
	while [ true ] ## "while :", "while true" both are ok
	do
		show_menu
	done
comment
	browse_file
}

main
