#!/bin/bash
#
mysql -e "stop slave;"
SLAVE_STATUS=$(mysql -e "show slave status \G")

while read -r line; do
	case $line in
		*Relay_Master_Log_File*)
			MASTER_LOG_FILE=$(echo $line | grep Relay_Master_Log_File: | awk '":" { print $2 }')
		;;
		*Relay_Log_Pos*)
			MASTER_LOG_POSITION=$(echo $line | grep Relay_Log_Pos: | awk '":" { print $2 }')
		;;
	esac
done <<< "$SLAVE_STATUS"

echo "Syncing master log file: $MASTER_LOG_FILE - Position: $MASTER_LOG_POSITION"
echo -n "Go ahead [y/N] ? "
read ans

case $ans in 
	[Yy][Ee][Ss])
		mysql -e "reset slave;"
		mysql -e "CHANGE MASTER TO MASTER_LOG_FILE='$MASTER_LOG_FILE', MASTER_LOG_POS=$MASTER_LOG_POSITION;"
		mysql -e "start slave;"
	;;
	*)
		mysql -e "start slave;"
		echo "OK, ok: exiting"
	;;
esac
