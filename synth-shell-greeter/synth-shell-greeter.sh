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



##==============================================================================
##	EXTERNAL DEPENDENCIES
##==============================================================================
[ "$(type -t include)" != 'function' ]&&{ include(){ { [ -z "$_IR" ]&&_IR="$PWD"&&cd "$(dirname "${BASH_SOURCE[0]}")"&&include "$1"&&cd "$_IR"&&unset _IR;}||{ local d="$PWD"&&cd "$(dirname "$PWD/$1")"&&. "$(basename "$1")"&&cd "$d";}||{ echo "Include failed $PWD->$1"&&exit 1;};};}

include '../bash-tools/bash-tools/color.sh'
include '../bash-tools/bash-tools/print_utils.sh'
include 'info.sh'
include 'reports.sh'
include '../config/synth-shell-greeter.config.default'






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
local target_config_file="$1"
local user_config_file="$HOME/.config/synth-shell/synth-shell-greeter.config"
local root_config_file="/etc/synth-shell/os/synth-shell-greeter.root.config"
local sys_config_file="/etc/synth-shell/synth-shell-greeter.config"

if   [ -f "$target_config_file" ]; then source "$target_config_file" ;
elif [ -f "$user_config_file" ]; then source "$user_config_file" ;
elif [ -f $root_config_file ] && [ "$USER" == "root" ]; then source "$root_config_file" ;
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
##	STATUS INFO COMPOSITION
##==============================================================================

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
			local status_info="$(statusSwitch "$key")"
		else
			local status_info="${status_info}\n$(statusSwitch "$key")"
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
	if [ $(( $logo_cols + $info_cols )) -le "$term_cols" ]; then
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



printReports()
{
	reportLastLogins
	reportSystemctl
	reportHogsCPU
	reportHogsMemory
}






##==============================================================================
##	MAIN
##==============================================================================


## CHECKS
if [ -z "$(which 'bc' 2>/dev/null)" ]; then
	printf "${fc_error}synth-shell-greeter: 'bc' not installed${fc_none}"
	exit 1
fi


## PRINT TOP SPACER
if $clear_before_print; then clear; fi
if $print_extra_new_line_top; then echo ""; fi


## PRINT GREETER ELEMENTS
printHeader
printReports


## PRINT BOTTOM SPACER
if $print_extra_new_line_bot; then echo ""; fi
}



## RUN SCRIPT
## This whole script is wrapped with "{}" to avoid environment pollution.
## It's also called in a subshell with "()" to REALLY avoid pollution.
## If not running interactively, don't do anything
## Run only in interactive session
## If not running interactively, don't do anything.
## Run with `LANG=C` so the code uses `.` as decimal separator.
if [ -n "$( echo $- | grep i )" ]; then
	(LC_ALL=C greeter "$1") 
fi
unset greeter


