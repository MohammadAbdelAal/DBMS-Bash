#!/bin/bash
. ./dbsfunctions.sh

itidbsexist

select option1 in createdb listdbs connectdb dropdb; do
	case $REPLY in
	1)
		createdb
		;;
	2)
		listdbs
		;;
	3)
		connectdb
		;;
	4)
		dropdb
		;;
	esac
done
