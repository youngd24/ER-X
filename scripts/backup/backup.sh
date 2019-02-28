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
#   * Copy to /config/scripts so it survives upgrades.
#   * Change the save command to ftp or other if you want.
#     - Options are:
#         scp://<user>:<passwd>@<host>/<file>
#         sftp://<user>:<passwd>@<host>/<file>
#         ftp://<user>:<passwd>@<host>/<file>
#         tftp://<host>/<file>
#
#   * Run the following to schedule it to run daily:
#     - set system task-scheduler task 'Daily backup' executable path <script>
#     - set system task-scheduler task 'Daily backup' interval days1
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

# Remove the log file if it's there
if [ -f $LOGFILE ]; then
	rm -f $LOGFILE
fi

# Iterate through the backup hosts and do it
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

echo "Done" | tee -a $LOGFILE
exit 0
