#!/bin/bash

##  +-----------------------------------+-----------------------------------+
##  |                                                                       |
##  | Copyright (c) 2019-2020, Andres Gongora <mail@andresgongora.com>.     |
##  | Copyright (c) 2019, Sami Olmari <sami@olmari.fi>.                     |
##  |                                                                       |
##  | This program is free software: you can redistribute it and/or modify  |
##  | it under the terms of the GNU General Public License as published by  |
##  | the Free Software Foundation, either version 3 of the License, or     |
##  | (at your option) any later version.                                   |
##  |                                                                       |
##  | This program is distributed in the hope that it will be useful,       |
##  | but WITHOUT ANY WARRANTY; without even the implied warranty of        |
##  | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         |
##  | GNU General Public License for more details.                          |
##  |                                                                       |
##  | You should have received a copy of the GNU General Public License     |
##  | along with this program. If not, see <http://www.gnu.org/licenses/>.  |
##  |                                                                       |
##  +-----------------------------------------------------------------------+


##
##	DESCRIPTION:
##	Network related functions for synth-shell-greeter
##
##






##==============================================================================
##
##	getLocalIPv6()
##
##	Looks up and returns local IPv6-address.
##	Test for the presence of several programs in case one is missing.
##	Program search ordering is based on timed tests, fastest to slowest.
##
##	!!! NOTE: Still need to figure out how to look for IP address that
##	!!!       have a default gateway attached to related interface,
##	!!!       otherwise this returns a list of IPv6's if there are many.
##
getLocalIPv6()
{

	## GREP REGGEX EXPRESSION TO RETRIEVE IP STRINGS
	##
	## The following string is intuitive and easy to read, but only parses
	## strings that look like IPs without checking their value. For instance,
	## it does NOT check value ranges of IPv6
	##
	## grep explanation:
	## -oP				only return matching parts of a line, and use perl regex
	## \s*inet6\s+			any-spaces "inet6" at-least-1-space
	## (addr:?\s*)?			optionally, followed by addr or addr:
	## \K				everything until here, omit
	## (){1,8}			repeat block at least 1 time, up to 8
	## ([0-9abcdef]){0,4}:*		up to 4 chars from [] followed by :
	##
	#local grep_reggex='\s*inet6\s+(addr:?\s*)?\K(([0-9abcdef]){0,4}:*){1,8}'
	##
	## The following string, on the other hand, is harder to read and
	## understand, but is MUCH safer, as it ensures that the IP
	## fulfills some criteria.
	local grep_reggex='^\s*inet6\s+(addr:?\s*)?\K((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?'


	if   ( which ip > /dev/null 2>&1 ); then
		local result=$($(which ip) -family inet6 addr show |\
		grep -oP "$grep_reggex" |\
		sed '/::1/d;:a;N;$!ba;s/\n/,/g')

	elif ( which ifconfig > /dev/null 2>&1 ); then
		local result=$($(which ifconfig) |\
		grep -oP "$grep_reggex" |\
		sed '/::1/d;:a;N;$!ba;s/\n/,/g')

	else
		local result="Error"
	fi


	## Returns "N/A" if actual query result is empty,
	## and returns "Error" if no programs found
	[ $result ] && printf $result || printf "N/A"
}






##==============================================================================
##
##	getExternalIPv6()
##
##	Makes an query to internet-server and returns public IPv6-address.
##	Tests for the presence of several programs in case one is missing.
##	Program search ordering is based on timed tests, fastest to slowest.
##	DNS-based queries are always faster, ~0.1 seconds.
##	URL-queries are relatively slow, ~1 seconds.
##
getExternalIPv6()
{
	if   ( which dig > /dev/null 2>&1 ); then
		local result=$($(which dig) TXT -6 +short o-o.myaddr.l.google.com @ns1.google.com |\
		               awk -F\" '{print $2}')

	elif ( which nslookup > /dev/nul 2>&1 ); then
		local result=$($(which nslookup) -q=txt o-o.myaddr.l.google.com 2001:4860:4802:32::a |\
		               awk -F \" 'BEGIN{RS="\r\n"}{print $2}END{RS="\r\n"}')

	elif ( which curl > /dev/null 2>&1 ); then
		local result=$($(which curl) -s https://api6.ipify.org)

	elif ( which wget > /dev/null 2>&1 ); then
		local result=$($(which wget) -q -O - https://api6.ipify.org)

	else
		local result="Error"
	fi


	## Returns "N/A" if actual query result is empty,
	## and returns "Error" if no programs found
	[ $result ] && printf $result || printf "N/A"
}





##==============================================================================
##
##	getLocalIPv4()
##
##	Looks up and returns local IPv4-address.
##	Tries first program found.
##	!!! NOTE: Still needs to figure out how to look for IP address that
##	!!!       have a default gateway attached to related interface,
##	!!!       otherwise this returns list of IPv4's if there are many
##
getLocalIPv4()
{
	## GREP REGEX EXPRESSION TO RETRIEVE IP STRINGS
	##
	## The following string is intuitive and easy to read, but only parses
	## strings that look like IPs, without checking their value. For instance,
	## it does NOT check whether the IP bytes are [0-255], rather it
	## accepts values from [0-999] as valid.
	##
	## grep explanation:
	## -oP				only return matching parts of a line, and use perl regex
	## \s*inet\s+			any-spaces "inet6" at-least-1-space
	## (addr:?\s*)?			optionally, followed by addr or addr:
	## \K				everything until here, omit
	## (){4}			repeat block at least 1 time, up to 8
	## ([0-9]){1,4}:*		1 to 3 integers [0-9] followed by "."
	##
	#local grep_reggex='^\s*inet\s+(addr:?\s*)?\K(([0-9]){1,3}\.*){4}'
	##
	## The following string, on the other hand, is harder to read and
	## understand, but is MUCH safer, as it ensure that the IP
	## fulfills some criteria.
	local grep_reggex='^\s*inet\s+(addr:?\s*)?\K(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))'


	if   ( which ip > /dev/null 2>&1 ); then
		local ip=$('ip' -family inet addr show |\
		           grep -oP "$grep_reggex" |\
		           sed '/127.0.0.1/d;:a;N;$!ba;s/\n/, /g')

	elif ( which ifconfig > /dev/null 2>&1 ); then
		local ip=$('ifconfig' |\
		           grep -oP "$grep_reggex"|\
		           sed '/127.0.0.1/d;:a;N;$!ba;s/\n/, /g')
	else
		local ip="N/A"
	fi


	## FIX IP FORMAT AND RETURN
	## Add extra space after commas for readibility
	local ip=$(echo "$ip" | sed 's/,/, /g')
	printf "$ip"
}






##==============================================================================
##
##	getExternalIPv4()
##
##	Makes a query to internet-server and returns public IPv4-address.
##	Test for the presence of several programs in case one is missing.
##	Program search ordering is based on timed tests, fastest to slowest.
##	DNS-based queries are always faster, ~0.1 seconds.
##	URL-queries are relatively slow, ~1 seconds.
##
getExternalIPv4()
{
	if   ( which dig > /dev/null 2>&1 ); then
		local ip=$(dig +time=3 +tries=1 TXT -4 +short \
		           o-o.myaddr.l.google.com @ns1.google.com |\
		           awk -F\" '{print $2}')

	elif ( which drill > /dev/null 2>&1 ); then
		local ip=$(drill +time=3 +tries=1 TXT -4 +short \
		           o-o.myaddr.l.google.com @ns1.google.com |\
		           grep IN | tail -n 1 | cut -f5 -s |\
		           awk -F\" '{print $2}')

	elif ( which nslookup > /dev/null 2>&1 ); then
		local ip=$(nslookup -timeout=3 -q=txt \
		           o-o.myaddr.l.google.com 216.239.32.10 |\
		           awk -F \" 'BEGIN{RS="\r\n"}{print $2}END{RS="\r\n"}')

	elif ( which curl > /dev/null 2>&1 ); then
		local ip=$(curl -s https://api.ipify.org)

	elif ( which wget > /dev/null 2>&1 ); then
		local ip=$(wget -q -O - https://api.ipify.org)
	else
		local result="N/A"
	fi


	printf "$ip"
}

