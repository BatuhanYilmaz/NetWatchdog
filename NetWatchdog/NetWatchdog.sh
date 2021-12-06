#!/bin/bash

# ------ DEFINITION OF PARAMETERS START ------

# Host to ping
PING_HOST="google.com"
# Name of log file
LOGFILE=/home/ubuntu/NetWatchdog/netLogs.txt
# Maximum number of retries
RETRY_MAX=5
# WLAN wait duration (in seconds) for reset
WLAN_RESET_WAIT=5
# Global buffer for current network SSID
CURR_NETWORK=""
# Definition of *off* and *no connection* states
OFF_STATE="off/any"

# ------ DEFINITION OF PARAMETERS END ------

# ------ DEFINITION OF FUNCTIONS START ------

function logStep {
	echo "[" $(date +"%Y-%m-%d %T") "]" $1 $2 $3 >> $LOGFILE
}

# Check the SSID of currently connected network
function checkWLAN {
	logStep "Checking WLAN connection..." ""
	{	
		CURR_NETWORK=$(sudo iwconfig | grep '^wlan0' | cut -d\: -f2)
	} &> /dev/null
	logStep "Current network SSID: " ${CURR_NETWORK}
}

# Reset function for WLAN adapter
function resetWLAN {
	{
		logStep "Resetting WLAN adapter..."
		# Shutting the WLAN adapter down
		sudo nmcli radio wifi off
		logStep "WLAN adapter switched OFF"
		# Waiting for the adapter toreset
		sleep $WLAN_RESET_WAIT;
		# Setting the adapter to ON state
		sudo nmcli radio wifi on
		logStep "WLAN adapter switched ON"
		logStep "WLAN reset successful"
		#$(date +"%Y-%m-%d %T")
		#sudo systemctl restart NetworkManager
	} &> /dev/null
}

# ------ DEFINITION OF FUNCTIONS END ------

# ----- MAIN BLOCK START ------

logStep "------ WLAN Connection Check Routine START ------"

# Check whether that the device is currently connected to a network
checkWLAN
sleep 1;

# Check whether the device is connected with a network or not 
if [ ${CURR_NETWORK} != ${OFF_STATE} ]; then
	echo "Current network SSID: " ${CURR_NETWORK}
else
	echo "NO NETWORK CONNECTION!"
	# Retrying if reset fails
	for ((i=0;i<$RETRY_MAX;i++)); do
		logStep "Reset attempt: " $(($i + 1))
		resetWLAN
		sleep 10;
		checkWLAN
		if [ ${CURR_NETWORK} != ${OFF_STATE} ]; then
			#sleep 10;
			break
		fi
	done
	
	# Ping a specified online host
	logStep "Pinging " ${PING_HOST} "..."
	for ((i=0;i<$RETRY_MAX;i++)); do
		ping -c 1 -q $PING_HOST &>/dev/null
		PING_RESULT=$?
		# Check if the connection is established with the specified host
		if [ $PING_RESULT -ne 0 ]; then
			logStep "Unable to connect" ${PING_HOST} 
		else
			logStep "Connected successfully to" ${PING_HOST}
			break
		fi
	done
	# Unable to connect after *n* replies
	#echo "[" $(date +"%Y-%m-%d %T") "]" "Unable to connect after "  $RETRY_MAX " retries" >> $LOGFILE

fi

logStep "------ WLAN Connection Check Routine END ------"

# ------ MAIN BLOCK END ------
