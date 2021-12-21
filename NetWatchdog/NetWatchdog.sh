#!/bin/bash

# ------ DEFINITION OF PARAMETERS START ------

# Host to ping
PING_HOST="google.com"
#Name of log file
LOGFILE_NAME=netLogs.txt
# Directory of log file
LOGFILE=~/$LOGFILE_NAME
# Maximum number of retries
RETRY_MAX=5
# WLAN wait duration (in seconds) for reset
WLAN_RESET_WAIT=5
# Global buffer for current network SSID
CURR_NETWORK=""
# Definition of *off* and *no connection* states
OFF_STATE="off/any"
# Set ping state
PING_OK=0

#!/bin/bash -l

LOGFILE_NAME=netLogs.txt
# Directory of log file
LOGFILE=~/$LOGFILE_NAME
 
# Definition of verbosity levels
SILENT_LVL=0
CRT_LVL=1
ERR_LVL=2
WRN_LVL=3
NTF_LVL=4
INF_LVL=5
DBG_LVL=6
 
# Set default verbosity level
VERBOSITY=4
 

 
# ------ DEFINITION OF PARAMETERS END ------

# ------ DEFINITION OF FUNCTIONS START ------

# esilent prints output even in silent mode
function esilent () { VERB_LVL=$SILENT_LVL elog "$@" >> $LOGFILE;}
function enotify () { VERB_LVL=$NTF_LVL elog "$@" >> $LOGFILE;} 
function eok ()    { VERB_LVL=$NTF_LVL elog "SUCCESS - $@" >> $LOGFILE;}
function ewarn ()  { VERB_LVL=$WRN_LVL elog "WARNING - $@" >> $LOGFILE;}
function einfo ()  { VERB_LVL=$INF_LVL elog "INFO ---- $@" >> $LOGFILE;}
function edebug () { VERB_LVL=$DBG_LVL elog "DEBUG --- $@" >> $LOGFILE;}
function eerror () { VERB_LVL=$ERR_LVL elog "ERROR --- $@" >> $LOGFILE;} 
function ecrit ()  { VERB_LVL=$CRT_LVL elog "FATAL --- $@" >> $LOGFILE;} 
function edumpvar () { for var in $@ ; do edebug "$var=${!var}" ; done }
function elog() {
        if [ $VERBOSITY -ge $VERB_LVL ]; then
                DATESTRING=`date +"%Y-%m-%d %H:%M:%S"`
                echo -e "$DATESTRING - $@"
        fi
}

# Old basic function for logging
#function logStep {
#	echo "[" $(date +"%Y-%m-%d %T") "]" $1 $2 $3 >> $LOGFILE
#}

# Check the SSID of currently connected network
function checkWLAN {
	einfo "Checking WLAN connection..." ""
	{	
		CURR_NETWORK=$(sudo iwconfig | grep '^wlan0' | cut -d\: -f2)
	} &> /dev/null
	einfo "Current network SSID: " ${CURR_NETWORK}
}

# Ping a specified online host
function pingConnection {

	einfo "Pinging " ${PING_HOST} "..."
	for ((i=0;i<$1;i++)); do
		ping -c 1 -q $PING_HOST &>/dev/null
		PING_RESULT=$?
		# Check if the connection is established with the specified host
		if [ $PING_RESULT -ne 0 ]; then
			PING_OK=0;
			eerror "Unable to connect" ${PING_HOST} 
		else
			PING_OK=1;
			einfo "Connected successfully to" ${PING_HOST}
			break
		fi
	done


}

# Reset function for WLAN adapter
function resetWLAN {
	{
		enotify "Resetting WLAN adapter..."
		# Shutting the WLAN adapter down
		sudo nmcli radio wifi off
		enotify "WLAN adapter switched OFF"
		# Waiting for the adapter toreset
		sleep $WLAN_RESET_WAIT;
		# Setting the adapter to ON state
		sudo nmcli radio wifi on
		enotify "WLAN adapter switched ON"
		eok "WLAN reset successful"
		#$(date +"%Y-%m-%d %T")
		#sudo systemctl restart NetworkManager
	} &> /dev/null
}

# ------ DEFINITION OF FUNCTIONS END ------

# ----- MAIN BLOCK START ------


OPTIND=1
while getopts ":sCEWNVG" opt ; do
        case $opt in
        s)
                VERBOSITY=$SILENT_LVL
                edebug "-s specified: Silent mode"
                ;;
        C)
                VERBOSITY=$CRT_LVL
                edebug "-C specified: Critical mode"
                ;;
        E)
                VERBOSITY=$ERR_LVL
                edebug "-E specified: Error mode"
                ;;
        W)
                VERBOSITY=$WRN_LVL
                edebug "-W specified: Warning mode"
                ;;
        N)
                VERBOSITY=$NTF_LVL
                edebug "-N specified: Notify mode"
                ;;
        V)
                VERBOSITY=$INF_LVL
                edebug "-V specified: Verbose mode"
                ;;
        G)
                VERBOSITY=$DBG_LVL
                edebug "-G specified: Debug mode"
                ;;
        esac
done


einfo "------ WLAN Connection Check Routine START ------"

# Check whether that the device is currently connected to a network
checkWLAN
sleep 1;

pingConnection $RETRY_MAX

# Check whether the device is connected with a network or not 
if [[ ${CURR_NETWORK} != ${OFF_STATE} && $PING_OK -eq 1 ]]; then
	einfo "Current network SSID: " ${CURR_NETWORK}
else
	eerror "NO NETWORK CONNECTION!"
	# Retrying if reset fails
	for ((i=0;i<$RETRY_MAX;i++)); do
		enotify "Reset attempt: " $(($i + 1))
		resetWLAN
		sleep 10;
		checkWLAN
		if [ ${CURR_NETWORK} != ${OFF_STATE} ]; then
			#sleep 10;
			eok "Current network SSID: " ${CURR_NETWORK}
			pingConnection $RETRY_MAX
			if [ $PING_OK -eq 1 ]; then
				eok "Connected successfully to" ${PING_HOST}
				break
			fi
		fi
	done
	

	
	# Unable to connect after *n* replies
	#echo "[" $(date +"%Y-%m-%d %T") "]" "Unable to connect after "  $RETRY_MAX " retries" >> $LOGFILE

fi

einfo "------ WLAN Connection Check Routine END ------"

# ------ MAIN BLOCK END ------
