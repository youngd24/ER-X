#!/bin/vbash
###############################################################################
#
# backup.sh
#
# EdgeRouter-X Backup Script
#
# Copyright (C) 2018-2019 Darren Young <darren@yhlsecurity.com>
#
################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
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
#   * Run the following to schedule it to run daily at 03:00:
#     (DO NOT use spaces in the task name, it'll error out)
#     - set system task-scheduler task 'DailyBackup' executable path <script>
#     - set system task-scheduler task 'DailyBackup' crontab-spec '0 3 * * * '
#
#   * Purge old backups on the TFTP server, cron this daily:
#     - find <tftp_dir> -type f -mtime +30 -exec rm -fr {} \;
#
###############################################################################
#
# TODO/ISSUES:
# 
#   * This is a constant work in progress so caveat emptor.
#   * Add more [better|reliable] error detection.
#   * Add better logging (using syslog too).
#   * Add emailing of results, need to see how the ER-X email works.
#   * Find a way to make sure we're running on an ER-X and bomb out if not.
#
###############################################################################


###############################################################################
#                              F U N C T I O N S
###############################################################################

# I honestly don't remember why I started doing this, leftover ksh memories?
typeset -f logmsg
typeset -f errmsg
typeset -f debug
typeset -f run_command

# -----------------------------------------------------------------------------
# Print a log formatted message
# * logger format: logger -s -i -p local0.notice -t info <message>
# -----------------------------------------------------------------------------
function logmsg() {
    if [[ -z "$1" ]]
    then
        errmsg "Usage: logmsg <message>"
        return 0
    else
        local MESSAGE=$1
        if [[ ! -z $LOGFILE ]]; then
            local NOW=`date +"%b %d %Y %T"`
            echo $NOW $1 >> $LOGFILE
        else
            local NOW=`date +"%b %d %Y %T"`
            msg "$NOW $MESSAGE"
            return 0
        fi
    fi
}

# -----------------------------------------------------------------------------
# Print a message to stderr so it doens't become part of a function return
# -----------------------------------------------------------------------------
function errmsg() {
    if [[ -z "$1" ]]; then
        logmsg "Usage: errmsg <message>"
        return 0
    else
        logmsg "ERROR: $1"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Print a message if global $DEBUG is set to true
# -----------------------------------------------------------------------------
function debug() {
    if [[ -z "$1" ]]
    then
        errmsg "Usage: debug <message>"
        return 0
    else
        if [ "$DEBUG" == "true" ]
        then
            local message="$1"
            logmsg "DEBUG: $message"
            return 1
        else
            return 1
        fi
    fi
}

# -----------------------------------------------------------------------------
# Run a command
# -----------------------------------------------------------------------------
function run_command() {
    debug "${FUNCNAME[0]}: entering"

    if [[ -z "$1" ]]
    then
        errmsg "Usage: run_command <command>"
        return 0
    else
        local CMD="$1"
        debug "CMD: $CMD"
        RET=$($CMD >> $LOGFILE 2>>$LOGFILE)
        RETVAL=$?

        debug "return: $RET"
        debug "retval: $RETVAL"

        if [[ $RETVAL != 0 ]]; then
            logmsg "Failed to run command"
            return 0
        else
            debug "SUCCESS"
            return 1
    fi
        return 1
    fi
}


###############################################################################
#                              V A R I A B L E S
###############################################################################
EMAIL="No"
MAILTO="me@you.com"

VYCMD="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper"
CFGDIR="/config"

USE_SYSLOG="true"
LOGGER="/usr/bin/logger"
PRIORITY="local0.notice"
LOGFILE="/tmp/erx-backup.log"

DATE=`date +%m%d%y-%H%M%S`
HOSTNAME=`hostname`
BKPFILE="$HOSTNAME.config.$DATE"
TFTP_HOSTS="dns01 dns02"

HAD_FAILED="false"


###############################################################################
#                                   M A I N
###############################################################################

# Make sure we're actually on an ER-X here
# if [ ! $isERX ]; then
#    boom "message"
# fi

# Make sure we have the Vyatta command, if not exit with something funky
if [ ! -f $VYCMD ]; then
    echo "Vyatta command not installed"
    exit 22
fi

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
        HAD_FAILED="true"
	else
		echo "Backup to $host successful" | tee -a $LOGFILE
	fi
done

echo "Done" | tee -a $LOGFILE
exit 0
