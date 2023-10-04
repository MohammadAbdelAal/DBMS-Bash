#!/bin/bash

itidbsexist() {
	if [[ -e ./itidbs ]]; then
		cd ./itidbs
	else
		mkdir ./itidbs
		echo "itidbs dir is created, any further actions will be done in it"
		cd ./itidbs
	fi
}
createdb() {
	read -p "this will create db in dir itidbs in current dir, enter db name " dbname
	if [[ "$dbname" =~ ^[0-9] || "$dbname" =~ [a-zA-Z]*[[:space:]][a-zA-Z]* || "$dbname" == *['!'@#\$%^\&*\(\)_+]* ]]; then
		echo "database name can't start with number or contains spaces or special char, db is not created"
	else
		if [[ -e ./$dbname ]]; then
			echo "db already exists"
		else
			mkdir ./$dbname
			echo $dbname is created
		fi
	fi
}

listdbs() {
	ls -d */ 2>/dev/null | cut -f1 -d'/'

}

. ./tablesfunctions.sh

afterconnectmenu() {

	select option2 in createtable listtables droptable insertintable selectfromtable deletefromtable updatetable viewtable; do
		case $REPLY in
		1) createtable ;;
		2) listtables ;;

		3) droptable ;;
		4) insertintable ;;
		5) selectfromtable ;;
		6) deletefromtable ;;
		7) updatetable ;;
		8) viewtable ;;
		#8) addcolumns_v2 ;;
		esac
	done
}

connectdb() {
	listdbs
	echo "enter db you want to connect to "
	read dbname2
	if [[ -e ./$dbname2 ]]; then
		cd ./$dbname2
		echo connected to $dbname2 successfuly
		afterconnectmenu

	else
		echo "wrong path"
	fi
}

dropdb() {
	listdbs
	echo "enter db you want to drop THIS will delete included tables and unrecoverable "
	read dbname3
	if [[ -e ./$dbname3 ]]; then
		rm -r ./$dbname3
		if [[ $? == 0 ]]; then
			echo $dbname3 is dropped successfuly
		fi
	else
		echo "wrong path"
	fi
}
