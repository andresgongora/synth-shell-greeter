#!/bin/bash

##  +-----------------------------------+-----------------------------------+
##  |                                                                       |
##  | Copyright (c) 2019-2020, Andres Gongora <mail@andresgongora.com>.     |
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
##
##
##



##==============================================================================
##	EXTERNAL DEPENDENCIES
##==============================================================================
[ "$(type -t include)" != 'function' ]&&{ include(){ { [ -z "$_IR" ]&&_IR="$PWD"&&cd "$(dirname "${BASH_SOURCE[0]}")"&&include "$1"&&cd "$_IR"&&unset _IR;}||{ local d="$PWD"&&cd "$(dirname "$PWD/$1")"&&. "$(basename "$1")"&&cd "$d";}||{ echo "Include failed $PWD->$1"&&exit 1;};};}

include '../bash-tools/bash-tools/color.sh'
include '../bash-tools/bash-tools/print_utils.sh'
include '../bash-tools/bash-tools/assert.sh'






##==============================================================================
##	
##==============================================================================

##------------------------------------------------------------------------------
##
reportLastLogins()
{
	assert_is_set ${fc_highlight}
	assert_is_set ${fc_info}

	## DO NOTHING FOR NOW -> This is disabled intentionally for now.
	## Printing logins should only be done under special circumstances:
	## 1. User configurable set to always on
	## 2. If the IP/terminal is very different from usual
	## 3. Other anomalies...
	if false; then
		printf "${fc_highlight}\nLAST LOGINS:\n${fc_info}"
		last -iwa | head -n 4 | grep -v "reboot"
	fi
}



##------------------------------------------------------------------------------
##
reportSystemctl()
{
	assert_is_set ${fc_highlight}
	assert_is_set ${fc_info}
	assert_is_set ${fc_crit}
	assert_is_set ${fc_none}

    ## 1. Check if systemd is running (it might not on some distros/Windows)
    ## 2. Get number of failed daemons
    ## 3. Report those that failed
    if [ -n "$(pidof systemd)" ]; then
	    systcl_num_failed=$(systemctl --failed |\
	                        grep "loaded units listed" |\
	                        head -c 1)

	    if [ "$systcl_num_failed" -ne "0" ]; then
		    local failed=$(systemctl --failed | awk '/UNIT/,/^$/')
		    printf "\n${fc_crit}SYSTEMCTL FAILED SERVICES:\n"
		    printf "${fc_info}${failed}${fc_none}\n"

	    fi
    fi
}



##------------------------------------------------------------------------------
##
reportHogsCPU()
{
	assert_is_set ${cpu_crit_print}
	assert_is_set ${bar_cpu_crit_percent}
	assert_is_set ${fc_highlight}
	assert_is_set ${fc_info}
	assert_is_set ${fc_crit}
	assert_is_set ${fc_none}

	export LC_NUMERIC="C"


	## EXIT IF NOT ENABLED
	if [ "$cpu_crit_print" == true ]; then
		## CHECK CPU LOAD
		local current=$(awk '{avg_1m=($1)} END {printf "%3.2f", avg_1m}' /proc/loadavg)
		local max=$(nproc --all)
		local percent=$(bc <<< "$current*100/$max")


		if [ "$percent" -gt "$bar_cpu_crit_percent" ]; then
			## CALL TOP IN BATCH MODE
			## Check if "%Cpus(s)" is shown, otherwise, call "top -1"
			## Escape all '%' characters
			local top=$(nice 'top' -b -d 0.01 -n 1 )
			local cpus=$(echo "$top" | grep "Cpu(s)" )
			if [ -z "$cpus" ]; then
				local top=$(nice 'top' -b -d 0.01 -1 -n 1 )
				local cpus=$(echo "$top" | grep "Cpu(s)" )
			fi
			local top=$(echo "$top" | sed 's/\%/\%\%/g' )


			## EXTRACT ELEMENTS FROM TOP
			## - load:    summary of cpu time spent for user/system/nice...
			## - header:  the line just above the processes
			## - procs:   the N most demanding procs in terms of CPU time
			local load=$(echo "${cpus:9:36}" | tr '', ' ' )
			local header=$(echo "$top" | grep "%CPU" )
			local procs=$(echo "$top" |\
				      sed  '/top - /,/%CPU/d' |\
				      head -n "$cpu_crit_print_num" )


			## PRINT WITH FORMAT
			printf "\n${fc_crit}SYSTEM LOAD:${fc_info}  ${load}\n"
			printf "${fc_crit}$header${fc_none}\n"
			printf "${fc_text}${procs}${fc_none}\n"
		fi
	fi
}



##------------------------------------------------------------------------------
##
reportHogsMemory()
{
	assert_is_set ${ram_crit_print}
	assert_is_set ${bar_ram_crit_percent}
	assert_is_set ${fc_highlight}
	assert_is_set ${fc_info}
	assert_is_set ${fc_crit}
	assert_is_set ${fc_none}


	## EXIT IF NOT ENABLED
	if [ "$ram_crit_print" == true ]; then
		## CHECK RAM
		local ram_is_crit=false
		local mem_info=$('free' -m | head -n 2 | tail -n 1)
		local current=$(echo "$mem_info" | awk '{mem=($2-$7)} END {printf mem}')
		local max=$(echo "$mem_info" | awk '{mem=($2)} END {printf mem}')
		local percent=$(bc <<< "$current*100/$max")
		if [ $percent -gt $bar_ram_crit_percent ]; then
			local ram_is_crit=true
		fi


		## CHECK SWAP
		## First check if there is any swap at all by checking /proc/swaps
		## If there is at least one swap partition listed, proceed
		local swap_is_crit=false
		local num_swap_devs=$(($(wc -l /proc/swaps | awk '{print $1;}') -1))	
		if [ "$num_swap_devs" -ge 1 ]; then
			local swap_info=$('free' -m | tail -n 1)
			local current=$(echo "$swap_info" | awk '{SWAP=($3)} END {printf SWAP}')
			local max=$(echo "$swap_info" | awk '{SWAP=($2)} END {printf SWAP}')
			local percent=$(bc <<< "$current*100/$max")
			if [ $percent -gt $bar_swap_crit_percent ]; then
				local swap_is_crit=true
			fi
		fi

		## PRINT IF RAM OR SWAP ARE ABOVE THRESHOLD
		if $ram_is_crit || $swap_is_crit ; then
			local available=$(echo $mem_info | awk '{print $NF}')
			local procs=$(ps --cols=80 -eo pmem,size,pid,cmd --sort=-%mem |\
				      head -n $(($ram_crit_print_num + 1)) |\
			              tail -n $ram_crit_print_num |\
				      awk '{$2=int($2/1024)"MB";}
				           {printf("%5s%8s%8s\t%s\n", $1, $2, $3, $4)}')

			printf "\n${fc_crit}MEMORY:\t "
			printf "${fc_info}Only ${available} MB of RAM available!!\n"
			printf "${fc_crit}    %%\t SIZE\t  PID\tCOMMAND\n"
			printf "${fc_info}${procs}${fc_none}\n"
		fi
	fi
}


