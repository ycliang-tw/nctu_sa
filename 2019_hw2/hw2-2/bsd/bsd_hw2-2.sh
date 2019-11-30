#!/bin/bash

## program flow
##	source util.sh -> trap termination signals -> main
# set -x

. util.sh	# source util.sh

main()
{
	while [ true ]; do ## "while :", "while true" both are ok
		show_menu
	done
}

main
