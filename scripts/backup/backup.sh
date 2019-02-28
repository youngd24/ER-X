#!/bin/vbash
###############################################################################
#
# backup.sh
#
# EdgeRouter-X Backup Script
#
# Darren Young <darren@yhlsecurity.com>
#
###############################################################################
#
# USAGE:
#
#   * Destinations must have TFTP installed and working.
#   * Adjust variables then run it manually or schedule it.
#
###############################################################################
#
# TODO/ISSUES:
# 
#   * Add better error detection.
#   * Added better logging.
#   * Added emailing of results, need to see how the ERX email works.
#
###############################################################################


###############################################################################
#                              V A R I A B L E S
###############################################################################
EMAIL="No"
MAILTO="me@you.com"

VYCMD="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper"
CFGDIR="/config"
LOGFILE="/tmp/erx-backup.log"

DATE=`date +%m%d%y-%H%M%S`
HOSTNAME=`hostname`
BKPFILE="$HOSTNAME.config.$DATE"
TFTP_HOSTS="dns01 dns02"

###############################################################################
#                                   M A I N
###############################################################################
for host in $TFTP_HOSTS; do
	echo "Backing up to $host" | tee -a $LOGFILE
	${VYCMD} begin | tee -a $LOGFILE
	${VYCMD} save tftp://$host/$BKPFILE | tee -a $LOGFILE
	RETVAL=$?
	if [ $RETVAL != 0 ]; then
		echo "Backup to $host failed" | tee -a $LOGFILE
	else
		echo "Backup to $host successful" | tee -a $LOGFILE
	fi
done

exit 0
