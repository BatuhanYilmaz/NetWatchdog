#!/bin/bash

# Current date
# CURR_DATE=`date`

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

function logStep {
	echo "[" $(date +"%Y-%m-%d %T") "]" $1 $2 >> $LOGFILE
}

# Check the SSID of currently connected network
function checkWLAN {
	logStep "Checking WLAN connection..." ""
	{	
		CURR_NETWORK=$(iwconfig | grep '^wlan0' | cut -d\: -f2)
	} &> /dev/null
	logStep "Current network SSID: " ${CURR_NETWORK}
}

# Reset function for WLAN adapter
function resetWLAN {
	{
		logStep "Resetting WLAN adapter..." ""
		nmcli radio wifi off
		logStep "WLAN adapter switched OFF" ""
		# Waiting for the reset
		sleep $WLAN_RESET_WAIT;
		nmcli radio wifi on
		logStep "WLAN adapter switched ON" ""
		logStep "WLAN reset successful" ""
		#$(date +"%Y-%m-%d %T")
		#sudo systemctl restart NetworkManager
	} &> /dev/null
}

#function getCurrDate {
#	CURR_DATE=date +"%Y-%m-%d %T"
#}

# ----- MAIN BLOCK START ------

logStep "------ WLAN Connection Check Routine START ------" ""

checkWLAN
sleep 1;

# Check whether the device is connected wo a network or not 
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
			break
		fi
	done
	
	# Unable to connect after *n* replies
	#echo "[" $(date +"%Y-%m-%d %T") "]" "Unable to connect after "  $RETRY_MAX " retries" >> $LOGFILE

fi

logStep "------ WLAN Connection Check Routine END ------" ""

# ------ MAIN BLOCK END ------
