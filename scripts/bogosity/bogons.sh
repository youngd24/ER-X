#!/bin/bash
################################################################################
#
# bogons.sh
#
# EdgeRouter-X Script to add bogon net blocks
#
# Darren Young <darren@yhlsecurity.com>
#
################################################################################
#
# Copyright (C) 2018 Darren Young <darren@yhlsecurity.com>
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
################################################################################
#
# USAGE:
#
################################################################################
#
# STATUS: 
#
# VERY (very) under development still, DO NOT USE FOR REAL
#
################################################################################
#
# LOGICAL DESIGN
#
# 1) Check if BOGON network-group already exists
#    a) If it does, remove it
#    b) Else, create it
#       - Default action drop
#       - Make it as an early order rule, perhaps no 5
# 2) Add BOGON nets to the network-group
#
# Things to consider:
#   - Should we assume the basic setup wizard was run and use the WAN_IN rule?
#
################################################################################

# Sample firewall commands
#stig@ER-bgp-test# set firewall group network-group DROP
#stig@ER-bgp-test# commit
#stig@ER-bgp-test# set firewall name WAN_IN rule 10 action drop
#stig@ER-bgp-test# set firewall name WAN_IN rule 10 source group network-group DROP
#stig@ER-bgp-test# set firewall name WAN_IN rule 10 description "networks to drop"
#stig@ER-bgp-test# commit
#stig@ER-bgp-test# save; exit

# What it will have to do
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper begin
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON description BOGON Nets
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 0.0.0.0/8
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 10.0.0.0/8
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 100.64.0.0/10
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 127.0.0.0/8
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 169.254.0.0/16
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 172.16.0.0/12
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 192.0.0.0/24
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 192.0.2.0/24
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 192.168.0.0/16
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 192.18.0.0/15
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 198.51.100.0/24
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 203.0.113.0/24
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 224.0.0.0/4
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set firewall group network-group BOGON network 240.0.0.0/4
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper commit
#/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper end

################################################################################
#
################################################################################

# Set for this script run
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
vCmd="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper"

# Nets to block
BOGON_NETS="0.0.0.0/8 \
           10.0.0.0/8 \
           100.64.0.0/10 \
           127.0.0.0/8 \
           169.254.0.0/16 \
           172.16.0.0/12 \
           192.0.0.0/24 \
           192.0.2.0/24 \
           192.168.0.0/16 \
           192.18.0.0/15 \
           198.51.100.0/24 \
           203.0.113.0/24 \
           224.0.0.0/4 \
           240.0.0.0/4"

BOGON_NAME="BOGONS"         # The name of things to use
WAN_RULE="WAN_IN"           # The existing WAN_IN rule
WAN_RULE_NO="5"             # Rule no to use
WAN_FW_INT="eth3"           # The outside interface, usually eth0


################################################################################
#
################################################################################
${vCmd} begin 
${vCmd} set firewall group network-group BOGONS description "BOGONS to block"
${vCmd} commit
${vCmd} set firewall name $WAN_RULE rule $WAN_RULE_NO action drop
${vCmd} set firewall name $WAN_RULE rule $WAL_RULE_NO source group network-group $BOGON_NAME
${vCmd} set firewall name $WAN_RULE rule $WAN_RULE_NO description "BOGON nets"
${vCmd} commit
${vCmd} end
exit 1





exit 0
