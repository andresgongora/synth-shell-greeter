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
getNameOS()
{
	if   [ -f /etc/os-release ]; then
		local os_name=$(sed -En 's/PRETTY_NAME="(.*)"/\1/p' /etc/os-release)
	elif [ -f /usr/lib/os-release ]; then
		local os_name=$(sed -En 's/PRETTY_NAME="(.*)"/\1/p' /usr/lib/os-release)
	else
		local os_name=$(uname -sr)
	fi

	printf "$os_name"
}






##==============================================================================
##
getNameKernel()
{
	local kernel=$(uname -r)
	printf "$kernel"
}






##==============================================================================
##
getNameShell()
{
	local shell=$(readlink /proc/$$/exe)
	printf "$shell"
}






##==============================================================================
##
getDate()
{
	local sys_date=$(date +"$date_format")
	printf "$sys_date"
}






##==============================================================================
##
getUptime() {
	$(uptime -p >/dev/null 2>&1) && local pretty=true

	if [ $pretty==true ]; then
		local uptime=$(uptime -p | sed 's/^[^,]*up *//g;
			                        s/s//g;
			                        s/ year/y/g;
			                        s/ month/m/g;
			                        s/ week/w/g;
			                        s/ day/d/g;
			                        s/ hour, /:/g;
			                        s/ minute//g')
	else
		local uptime=$(uptime | sed 's/^[^,]*up *//g;
		                             s/,.*$//g')
	fi

	printf "$uptime"
}






##==============================================================================
##
getUserHost()
{
	printf "$USER@$HOSTNAME"
}






##==============================================================================
##
getNumberLoggedInUsers()
{
	## -n	silent
	## 	replace everything with content of the group inside \( \)
	## p	print
	num_users=$(uptime |\
	            sed -n 's/.*\([[0-9:]]* users\).*/\1/p')

	printf "$num_users"
}





##==============================================================================
##
getNameLoggedInUsers()
{
	## who			See who is logged in
	## awk '{print $1;}'	First word of each line
	## sort -u		Sort and remove duplicates
	local name_users=$(who | awk '{print $1;}' | sort -u)

	printf "$name_users"
}








