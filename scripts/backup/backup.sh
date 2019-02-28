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
#   * Added error detection, there's none right now.
#   * Added emailing of results, need to see how the ERX email works.
#
###############################################################################


###############################################################################
#                              V A R I A B L E S
###############################################################################
DEBUG=""
EMAIL="No"
MAILTO="me@you.com"

VYCMD="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper"
CFGDIR="/config"

DATE=`date +%m%d%y-%H%M%S`
HOSTNAME=`hostname`
BKPFILE="$HOSTNAME.config.$DATE"
TFTP_HOSTS="dns01 dns02"


###############################################################################
#                                   M A I N
###############################################################################
for host in $TFTP_HOSTS; do
	echo "Backing up to $host"
	${VYCMD} begin
	${VYCMD} save tftp://$host/$BKPFILE
done


exit 0
