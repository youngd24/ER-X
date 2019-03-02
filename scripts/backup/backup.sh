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
#   * www.cyberciti.biz/faq/install-configure-tftp-server-ubuntu-debian-howto/
#   * Adjust variables then run it manually or schedule it.
#   * Copy to /config/scripts so it survives upgrades.
#   * Change the save command to ftp or other if you want.
#     - Options are:
#         scp://<user>:<passwd>@<host>/<file>
#         sftp://<user>:<passwd>@<host>/<file>
#         ftp://<user>:<passwd>@<host>/<file>
#         tftp://<host>/<file>
#   * Run the following to schedule it to run daily at 03:00:
#     (DO NOT use spaces in the task name, it'll error out)
#     - set system task-scheduler task 'DailyBackup' executable path <script>
#     - set system task-scheduler task 'DailyBackup' crontab-spec '0 3 * * * '
#   * It logs to syslog as well as to a log file, if you want to monitor it
#     catch for "backup.sh" from syslog in your SIEM, monitor system, etc.
#   * Purge old backups on the TFTP server, cron this daily:
#     - find <tftp_dir> -type f -mtime +30 -exec rm -fr {} \;
#
###############################################################################
#
# TODO/ISSUES:
# 
#   * This is a constant work in progress so caveat emptor.
#   * Add more [better|reliable] error detection.
#   * Needs better debug logging.
#   * Start to use getopt for command line args.
#   * Add emailing of results, need to see how the ER-X email works.
#   * Find a way to make sure we're running on an ER-X and bomb out if not.
#   * Add backup methods other than TFTP.
#   * Find a better way to capture the output of the Vyatta cmd.
#     - Maybe pipe it to logmsg somehow using $1? 
#
###############################################################################


###############################################################################
#                              V A R I A B L E S
###############################################################################
MYNAME=$(basename $0)                           # Our name
DEBUG=""                                        # Set to anything for debug
EMAIL="No"                                      # Not working yet
MAILTO="me@you.com"                             # Not working yet

VYCMD="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper" # command line tool
CFGDIR="/config"                                # ER-X config dir

USE_SYSLOG="true"                               # Set to anything non-null to use
LOGGER="/usr/bin/logger"                        # logger location on disk
PRIORITY="local0.notice"                        # What to set logs to
LOGFILE="/tmp/erx-backup.log"                   # Physical log file

BKPFILE="$(hostname).cnf.$(date +%m%d%y-%H%M)"  # Name of the backup file
BKPHOSTS="dns01 dns02"                          # Hosts to backup to
FAILHOSTS=""                                    # Running failure tally


###############################################################################
#                              F U N C T I O N S
###############################################################################

# I honestly don't remember why I started doing this, leftover ksh memories?
typeset -f logmsg
typeset -f errmsg
typeset -f debug
typeset -f run_command

# -----------------------------------------------------------------------------
#        NAME: logmsg
# DESCRIPTION: Print a log formatted message
#        ARGS: string(message)
#     RETURNS: 0
#      STATUS: Stable 
#       NOTES: logger format: logger -i -p local0.notice -t $NAME <message>
# -----------------------------------------------------------------------------
function logmsg() {
    if [[ -z "$1" ]]
    then
        errmsg "Usage: logmsg <message>"
        return 0
    else
        local MESSAGE=$1

        # Log to syslog if set to do so using the logger command
        # TODO: add error detection/correction on the command
        if [[ ! -z $USE_SYSLOG ]]; then
            local CMD="$LOGGER -i -p $PRIORITY -t $MYNAME $MESSAGE"
            debug "CMD: $CMD"
            ${CMD}
        fi

        # If there's a logfile defined, log to it
        # otherwise send to STDOUT (>&1)
        if [[ ! -z $LOGFILE ]]; then
            local NOW=`date +"%b %d %Y %T"`
            echo $NOW $1 >> $LOGFILE
        else
            local NOW=`date +"%b %d %Y %T"`
            >&1 echo "$NOW $MESSAGE"
            return 0
        fi
    fi
}

# -----------------------------------------------------------------------------
#        NAME: errmsg
# DESCRIPTION: Print an error message to stderr and the log file
#        ARGS: string(message)
#     RETURNS: 0 or 1
#      STATUS: Stable
#       NOTES: 
# -----------------------------------------------------------------------------
function errmsg() {
    if [[ -z "$1" ]]; then
        >&2 echo "Usage: errmsg <message>"
        return 0
    else

        # Print to both STDERR and the logmsg dest
        >&2 echo "ERROR: $1"
        logmsg "ERROR: $1"
        return 1
    fi
}

# -----------------------------------------------------------------------------
#        NAME: debug
# DESCRIPTION: Print a debug message
#        ARGS: string(message)
#     RETURNS: 0 or 1
#      STATUS: Stable
#       NOTES: 
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
#        NAME: run_command
# DESCRIPTION: Run an OS command (safely)
#        ARGS: string(command)
#     RETURNS: 0 or 1
#      STATUS: Under Development
#       NOTES: 
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
#                                   M A I N
###############################################################################

# Remove the log file if it's there
if [[ -f $LOGFILE ]]; then
	rm -f $LOGFILE
fi

# Make sure we're actually on an ER-X here
# if [ ! $isERX ]; then
#    boom "message"
# fi

# Make sure we have the Vyatta command, if not exit with something funky
if [[ ! -f $VYCMD ]]; then
    errmsg "Vyatta command not installed"
    #exit 22
fi


logmsg "Starting on $(hostname)"

# Iterate through the backup hosts and do it
for host in $BKPHOSTS; do
    logmsg "Backing up $BKPFILE to $host"
    ${VYCMD} begin >> $LOGFILE 2>&1
    ${VYCMD} save tftp://$host/$BKPFILE >> $LOGFILE 2>&1
    RETVAL=$?
    if [[ $RETVAL != 0 ]]; then
        logmsg "Backup to $host failed" 
        FAILHOSTS="$FAILHOSTS $host"
    else
        logmsg "Backup to $host successful" 
    fi
done

# If the running failure tally is non-null, log that message
if [[ ! -z $FAILHOSTS ]]; then
    logmsg "The following hosts failed as backup targets: $FAILHOSTS"
fi

logmsg "Done, buh bye"
exit 0








###############################################################################
#                         S E C T I O N   T E M P L A T E
###############################################################################

# -----------------------------------------------------------------------------
#        NAME: function_template
# DESCRIPTION: 
#        ARGS: 
#     RETURNS: 
#      STATUS: 
#       NOTES: 
# -----------------------------------------------------------------------------
