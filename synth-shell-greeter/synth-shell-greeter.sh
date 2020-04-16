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
##	This script prints to terminal a summary of your system's status. This
##	includes basic information about the OS and the CPU, as well as
##	system resources, possible errors, and suspicions system activity.
##
##



## INCLUDE EXTERNAL DEPENDENCIES
include(){ [ -z "$_IR" ]&&_IR="$PWD"&&cd $( dirname "$PWD/$0" )&&. "$1"&&cd "$_IR"&&unset _IR||. $1;}
include '../bash-tools/bash-tools/color.sh'
include '../bash-tools/bash-tools/print_utils.sh'
include 'info.sh'


greeter()
{


##==============================================================================
##	CONFIGURATION
##==============================================================================


## LOAD CONFIGURATION
## Load default configuration file with all arguments, then try to load any of
## following in order, until first match, to override some or all config params.
## 1. Apply specific configuration file if specified as argument.
## 2. User specific configuration if in user's home folder.
## 3. If root, apply root configuration file if it exists in the system.
## 4. System wide configuration file if it exists.
## 5. Fall back to defaults.
##
include '../config/synth-shell-greeter.config.default'
local target_config_file="$1"
local user_config_file="~/.config/synth-shell/synth-shell-greeter.config"
local root_config_file="/etc/synth-shell/os/synth-shell-greeter.root.config"
local sys_config_file="/etc/synth-shell/synth-shell-greeter.config"

if   [ -f "$target_config_file" ]; then source "$target_config_file" ;
elif [ -f "$user_config_file" ]; then source "$user_config_file" ;
elif [ -f $root_config_file -a "$USER" == "root" ]; then source "$root_config_file" ;
elif [ -f "$sys_config_file" ]; then source "$sys_config_file" ;
else : # Default config already "included" ; 
fi



## COLOR AND TEXT FORMAT CODE
local fc_info=$(getFormatCode $format_info)
local fc_highlight=$(getFormatCode $format_highlight)
local fc_crit=$(getFormatCode $format_crit)
local fc_deco=$(getFormatCode $format_deco)
local fc_ok=$(getFormatCode $format_ok)
local fc_error=$(getFormatCode $format_error)
local fc_logo=$(getFormatCode $format_logo)
local fc_none=$(getFormatCode -e reset)

#fc_logo
#fc_ok
#fc_crit
#fc_error
#fc_none
local fc_label="$fc_info"
local fc_text="$fc_highlight"






##==============================================================================
##	INFO
##==============================================================================








##==============================================================================
##	
##==============================================================================










##==============================================================================
##	STATUS INFO COMPOSITION
##==============================================================================

##------------------------------------------------------------------------------
##
printStatusInfo()
{
	## HELPER FUNCTION
	statusSwitch()
	{
		case $1 in
		## 	INFO (TEXT ONLY)
		##	NAME            FUNCTION
			OS)             printInfoOS;;
			KERNEL)         printInfoKernel;;
			CPU)            printInfoCPU;;
			GPU)            printInfoGPU;;
			SHELL)          printInfoShell;;
			DATE)           printInfoDate;;
			UPTIME)         printInfoUptime;;
			USER)           printInfoUser;;
			NUMLOGGED)      printInfoNumLoggedIn;;
			NAMELOGGED)     printInfoNameLoggedIn;;
			LOCALIPV4)      printInfoLocalIPv4;;
			EXTERNALIPV4)   printInfoExternalIPv4;;
			SERVICES)       printInfoSystemctl;;
			PALETTE_SMALL)  printInfoColorpaletteSmall;;
			PALETTE)        printInfoColorpaletteFancy;;
			SPACER)         printInfoSpacer;;
			CPULOAD) 	printInfoCPULoad;;
			CPUTEMP)        printInfoCPUTemp;;

		## 	USAGE MONITORS (BARS)
		##	NAME            FUNCTION               AS %
			SYSLOAD_MON)    printMonitorCPU        'a/b';;
			SYSLOAD_MON%)   printMonitorCPU        '0/0';;
			MEMORY_MON)     printMonitorRAM        'a/b';;
			MEMORY_MON%)    printMonitorRAM        '0/0';;
			SWAP_MON)       printMonitorSwap       'a/b';;
			SWAP_MON%)      printMonitorSwap       '0/0';;
			HDDROOT_MON)    printMonitorHDD        'a/b';;
			HDDROOT_MON%)   printMonitorHDD        '0/0';;
			HDDHOME_MON)    printMonitorHome       'a/b';;
			HDDHOME_MON%)   printMonitorHome       '0/0';;
			CPUTEMP_MON)    printMonitorCPUTemp;;

			*)              printInfoLine "Unknown" "Check your config";;
		esac
	}


	## ASSEMBLE INFO PANE
	local status_info=""
	for key in $print_info; do
		if [ -z "$status_info" ]; then
			local status_info="$(statusSwitch $key)"
		else
			local status_info="${status_info}\n$(statusSwitch $key)"
		fi
	done
	printf "${status_info}\n"
}






##==============================================================================
##	PRINT
##==============================================================================

##------------------------------------------------------------------------------
##
printHeader()
{
	## GET ELEMENTS TO PRINT
	local logo=$(echo "$fc_logo$logo$fc_none")
	local info=$(printStatusInfo)


	## GET ELEMENT SIZES
	local term_cols=$(getTerminalNumCols)
	local logo_cols=$(getTextNumCols "$logo")
	local info_cols=$(getTextNumCols "$info")


	## PRINT ONLY WHAT FITS IN THE TERMINAL
	if [ $(( $logo_cols + $info_cols )) -le $term_cols ]; then
		: # everything fits
	else
		local logo=""
	fi
	if $print_logo_right ; then
		local right="$logo"
		local left="$info"
	else
		local right="$info"
		local left="$logo"
	fi
	printTwoElementsSideBySide "$left" "$right" "$print_cols_max"
}



##------------------------------------------------------------------------------
##
printLastLogins()
{
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
printSystemctl()
{
	systcl_num_failed=$(systemctl --failed |\
	                    grep "loaded units listed" |\
	                    head -c 1)

	if [ "$systcl_num_failed" -ne "0" ]; then
		local failed=$(systemctl --failed | awk '/UNIT/,/^$/')
		printf "\n${fc_crit}SYSTEMCTL FAILED SERVICES:\n"
		printf "${fc_info}${failed}${fc_none}\n"

	fi
}



##------------------------------------------------------------------------------
##
printHogsCPU()
{
	export LC_NUMERIC="C"

	## EXIT IF NOT ENABLED
	if [ "$cpu_crit_print"==true ]; then
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
printHogsMemory()
{
	## EXIT IF NOT ENABLED
	if [ "$ram_crit_print"==true ]; then
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
		## If tehre is at least one swap partition listed, proceed
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






##==============================================================================
##	MAIN
##==============================================================================

## PRINT TOP SPACER
#if $clear_before_print; then clear; fi
if $print_extra_new_line_top; then echo ""; fi



## PRINT GREETER ELEMENTS
printHeader
#printLastLogins
#printSystemctl
#printHogsCPU
#printHogsMemory



## PRINT BOTTOM SPACER
if $print_extra_new_line_bot; then echo ""; fi
}



## RUN SCRIPT
## This whole script is wrapped with "{}" to avoid environment pollution.
## It's also called in a subshell with "()" to REALLY avoid pollution.
(greeter $1)
unset greeter


