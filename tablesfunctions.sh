#!/bin/bash
shopt -s extglob

listtables() {
	echo these are tables in $dbname2
	ls !(*.meta) 2>/dev/null
}
connecttable() {
	read -p "choose a table to connect " connectedtable
	echo table connected
}

addcolumns() {
	read -p "enter how many columns to add ? note: col 1 will be PK and is adviced to be number " columns_number
	if [[ $columns_number =~ ^[0-9]+$ ]]; then
		for ((i = 0; i < $columns_number; i++)); do
			v_c=$(($i + 1))
			read -p "enter column $v_c name " c
			arr[i]=$c

			read -p "column $v_c is integer(i) or string(s) ? " type
			if [[ $type == 'i' ]]; then
				arr2[i]='i'
			elif [[ $type == 's' ]]; then
				arr2[i]='s'
			fi

		done
		echo "${arr[@]}" >>./$connectedtable
		echo "${arr[@]}" >>./$connectedtable.meta
		echo "${arr2[@]}" >>./$connectedtable.meta

		sed -i "s/\ /:/g" ./$connectedtable
		sed -i "s/\ /:/g" ./$connectedtable.meta
		echo $columns_number columns are added to $connectedtable
	else
		echo plz enter a number
	fi

}
# addcolumns_v2() {
# 	listtables
# 	connecttable
# 	read -p "enter column name " new_column

# 	read -p "column $new_column is integer(i) or string(s) ? " type
# 	if [[ $type == 'i' ]]; then
# 		v_type='i'
# 	elif [[ $type == 's' ]]; then
# 		v_type='s'
# 	fi
# 	row_1_table=$(sed -n '1p' ./$connectedtable)
# 	row_1_meta=$(sed -n '1p' ./$connectedtable.meta)
# 	row_2_meta=$(sed -n '2p' ./$connectedtable.meta)

# 	row_1_table=$row_1_table:$new_column
# 	row_1_meta=$row_1_meta:$new_column
# 	row_2_meta=$row_2_meta:$v_type

# 	#sed -i -n 's/1p/$row_1_table/g' ./$connectedtable
# 	sed -i "1s/.*/$row_1_table/" ./$connectedtable
# 	sed -i '/^/d' ./$connectedtable.meta
# 	echo "$row_1_meta" >./$connectedtable.meta
# 	echo "$row_2_meta" >>./$connectedtable.meta

# }
createtable() {

	read -p "enter table name to create " table2create
	if [[ "$table2create" =~ ^[0-9] || "$table2create" =~ [a-zA-Z]*[[:space:]][a-zA-Z]* || "$table2create" == *['!'@#\$%^\&*\(\)_+]* ]]; then
		echo "table name can't start with number or contains spaces or special char, table is not created"
	else

		if [[ -e ./$table2create ]]; then
			echo table already exists with this name
		else
			touch ./$table2create
			echo empty table $table2create is created in $dbname2
			#listtables
			connectedtable=$table2create
			echo you are connected to $connectedtable
			addcolumns

		fi
	fi
}

droptable() {
	listtables
	read -p "enter table to drop " table2drop
	if [[ -e ./$table2drop || -e ./$table2drop.meta ]]; then
		rm ./$table2drop 2>/dev/null
		rm ./$table2drop.meta 2>/dev/null
		echo $table2drop is dropped
	else
		echo there is no table with this name
	fi
}

insertintable() {
	listtables
	connecttable

	buffer=$(awk '{if(NR==2) {print $0}}' ./$connectedtable.meta)
	IFS=':' read -r -a ctypesarr <<<"$buffer"
	#column types are loaded from .meta to ctypesarr

	buffer=$(awk '{if(NR==1) {print $0}}' ./$connectedtable.meta)
	IFS=':' read -r -a cnamesarr <<<"$buffer"
	for ((i = 0; i < ${#ctypesarr[@]}; i++)); do
		v_ct=$(($i + 1))
		read -p "enter the ${cnamesarr[i]} must be ${ctypesarr[i]} type " f
		if [[ $f =~ ^[0-9]+$ && ${ctypesarr[i]} == 'i' ]]; then
			rdata[i]=$f
		elif [[ $f =~ ^[a-zA-Z0-9]+$ && ${ctypesarr[i]} == 's' ]]; then
			rdata[i]=$f
		else
			echo "input row data doesnt match column type "
			exit
		fi

	done

	if [[ $# -le ${#rdata[@]} ]]; then
		u_input=${rdata[0]}
		check_flag=0
		check_flag=$(awk -F: -v u_input_awk=$u_input '
{
	if($1==u_input_awk)
	{ 
		flag= 1
		exit
	}
	else 
		flag=0

}
END{
	print flag
}' ./$connectedtable)

		if [[ $check_flag == 1 ]]; then
			echo "record exist: PK constraint violated"
		elif [[ $check_flag == 0 ]]; then
			to_table=$u_input:
			counter=1
			for i in "${rdata[@]}"; do
				if [[ $counter -gt 1 && $counter -lt ${#rdata[@]} ]]; then
					to_table=$to_table$i:
				fi
				if [[ $counter == ${#rdata[@]} ]]; then
					to_table=$to_table$i
				fi
				((counter = $counter + 1))
			done
		fi
		if [[ $check_flag == 0 ]]; then
			echo $to_table | cat >>./$connectedtable
		fi
	else
		echo over flow
	fi
}

selectfromtable() {
	listtables
	connecttable
	select x in single_row group_of_rows single_col quit; do
		case $REPLY in
		1)
			read -p "what is the row id " row_id
			echo $row_id
			awk -F: -v u_input_awk=$row_id '$1 == u_input_awk' ./$connectedtable
			;;
		2)
			select x in less_than less_than_or_equal more_than more_than_or_equal quit; do
				case $REPLY in
				1)
					read -p "what is the id " u_id
					awk -F: -v u_input_awk=$u_id '$1 < u_input_awk' ./$connectedtable
					;;
				2)
					read -p "what is the id " u_id
					awk -F: -v u_input_awk=$u_id '$1 <= u_input_awk' ./$connectedtable
					;;
				3)
					read -p "what is the id " u_id
					awk -F: -v u_input_awk=$u_id '$1 > u_input_awk' ./$connectedtable
					;;
				4)
					read -p "what is the id " u_id
					awk -F: -v u_input_awk=$u_id '$1 >= u_input_awk' ./$connectedtable
					;;
				5)
					break
					;;
				*)
					echo "wrong"
					;;
				esac
			done
			;;

		3)
			buffer2=$(awk '{if(NR==1) {print $0}}' ./$connectedtable.meta)
			IFS=':' read -r -a cnamesarr <<<"$buffer2"
			echo ${cnamesarr[@]}
			read -p "type a column name " cc
			awk -F: -v cc=$cc 'BEGIN{k}
			{
				for (i=1;i<=NF;i++) {if ($i == cc) {k=i} } 
				print $k 
			}' ./$connectedtable
			;;
		4)
			break
			;;
		*)
			echo "wrong"
			;;
		esac
	done
}

deletefromtable() {
	listtables
	connecttable
	select x in row clear_table quit; do
		case $REPLY in
		1)
			read -p "what is the row id " row_id
			echo $row_id
			check_flag=0
			check_flag=$(awk -F: -v u_input_awk=$row_id '
{
	if($1==u_input_awk)
	{ 
		flag= 1
		exit
	}
	else 
		flag=0

}
END{
	print flag
}' ./$connectedtable)
			if [[ $check_flag == 1 ]]; then
				sed -i "/^$row_id/d" ./$connectedtable
				echo row is deleted
			elif [[ $check_flag == 0 ]]; then
				echo row does not exist
			fi
			;;
		2)
			sed -i '2,$d' ./$connectedtable
			echo table is cleared
			;;
		3)
			break
			;;
		*)
			echo "wrong"
			;;
		esac
	done
}

updatetable() {
	listtables
	connecttable
	v_str=$(awk 'BEGIN{
		FS=":"
		out_put=""
	}
	{
		if(NR==1)
		{out_put=$0}

	}
	END{
		print out_put
	}' ./$connectedtable)

	echo $v_str

	read -p "select column number " v_col_num
	read -p "enter the row identifier " v_row_num
	read -p "enter the new value " new_value

	check_flag=0
	check_flag=$(awk -F: -v u_input_awk=$new_value '
{
	if($1==u_input_awk)
	{ 
		flag= 1
		exit
	}
	else 
		flag=0

}
END{
	print flag
}' ./$connectedtable)
	if [[ $check_flag == 1 ]]; then
		echo "record exist: PK constraint violated"
	elif [[ $check_flag == 0 ]]; then
		typec=$(awk -F: -v col=$v_col_num '{if (NR==2){print $col}}' ./$connectedtable.meta)
		if [[ $new_value =~ ^[0-9]+$ && $typec == 'i' || $new_value =~ ^[a-zA-Z0-9]+$ && $typec == 's' ]]; then

			awk -F: -v OFS=":" -v row_num_awk=$v_row_num -v col_num_awk=$v_col_num -v new_value_awk=$new_value '
	{
	if($1==row_num_awk)
	{
		$col_num_awk=new_value_awk
		
	}
	print $0
	}' ./$connectedtable | tee ./temp && mv ./temp ./$connectedtable
		else
			echo "input row data doesnt match column type "
			return
		fi
	fi

}

viewtable() {
	listtables
	connecttable
	cat ./$connectedtable.meta
	echo "===================================================================="
	sed -n '2,$p' ./$connectedtable
}
