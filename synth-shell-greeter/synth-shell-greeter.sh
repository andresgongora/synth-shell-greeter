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



greeter()
{
## INCLUDE EXTERNAL DEPENDENCIES
include() { source "$( cd $( dirname "${BASH_SOURCE[0]}" ) >/dev/null 2>&1 && pwd )/$1" ; }
include '../bash-tools/bash-tools/color.sh'
include '../bash-tools/bash-tools/print_utils.sh'




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

include 'print_info.sh'

include 'info_os.sh'
printInfoOS()           { printInfoLine "OS" "$(getNameOS)" ; }
printInfoKernel()       { printInfoLine "Kernel" "$(getNameKernel)" ; }
printInfoShell()        { printInfoLine "Shell" "$(getNameShell)" ; }
printInfoDate()         { printInfoLine "Date" "$(getDate)" ; }
printInfoUptime()       { printInfoLine "Uptime" "$(getUptime)" ; }
printInfoUser()         { printInfoLine "User" "$(getUserHost)" ; }
printInfoNumLoggedIn()  { printInfoLine "Logged in" "$(getNumberLoggedInUsers)" ; }
printInfoNameLoggedIn() { printInfoLine "Logged in" "$(getNameLoggedInUsers)" ; }

include 'info_hardware.sh'
printInfoCPU()          { printInfoLine "CPU" "$(getNameCPU)" ; }
printInfoGPU()          { printInfoLine "GPU" "$(getNameGPU)" ; }
printInfoCPULoad()      { printInfoLine "Sys load" "$(getCPULoad)" ; }

include 'info_network.sh'
printInfoLocalIPv4()    { printInfoLine "Local IPv4" "$(getLocalIPv4)" ; }
printInfoExternalIPv4() { printInfoLine "External IPv4" "$(getExternalIPv4)" ; }

printInfoSpacer()       { printInfoLine "" "" ; }




##==============================================================================
##	
##==============================================================================



##------------------------------------------------------------------------------
##
printInfoSystemctl()
{
	local systcl_num_failed=$(systemctl --failed |\
	                          grep "loaded units listed" |\
	                          head -c 1)

	if   [ "$systcl_num_failed" -eq "0" ]; then
		local sysctl="All services OK"
		local state="nominal"
	elif [ "$systcl_num_failed" -eq "1" ]; then
		local sysctl="1 service failed!"
		local state="error"
	else
		local sysctl="$systcl_num_failed services failed!"
		local state="error"
	fi

	printInfoLine "Services" "$sysctl" "$state"
}



##------------------------------------------------------------------------------
##
printInfoColorpaletteSmall()
{
	local char="▀▀"

	local palette=$(printf '%s'\
	"$(formatText "$char" -c black -b dark-gray)"\
	"$(formatText "$char" -c red -b light-red)"\
	"$(formatText "$char" -c green -b light-green)"\
	"$(formatText "$char" -c yellow -b light-yellow)"\
	"$(formatText "$char" -c blue -b light-blue)"\
	"$(formatText "$char" -c magenta -b light-magenta)"\
	"$(formatText "$char" -c cyan -b light-cyan)"\
	"$(formatText "$char" -c light-gray -b white)")

	printInfoLine "Color palette" "$palette"
}



##------------------------------------------------------------------------------
##
printInfoColorpaletteFancy()
{
	## Line 1:	▄▄█ ▄▄█ ▄▄█ ▄▄█ ▄▄█ ▄▄█ ▄▄█ ▄▄█ 
	## Line 2:	██▀ ██▀ ██▀ ██▀ ██▀ ██▀ ██▀ ██▀ 

	local palette_top=$(printf '%s'\
		"$(formatText "▄" -c dark-gray)$(formatText "▄" -c dark-gray -b black)$(formatText "█" -c black) "\
		"$(formatText "▄" -c light-red)$(formatText "▄" -c light-red -b red)$(formatText "█" -c red) "\
		"$(formatText "▄" -c light-green)$(formatText "▄" -c light-green -b green)$(formatText "█" -c green) "\
		"$(formatText "▄" -c light-yellow)$(formatText "▄" -c light-yellow -b yellow)$(formatText "█" -c yellow) "\
		"$(formatText "▄" -c light-blue)$(formatText "▄" -c light-blue -b blue)$(formatText "█" -c blue) "\
		"$(formatText "▄" -c light-magenta)$(formatText "▄" -c light-magenta -b magenta)$(formatText "█" -c magenta) "\
		"$(formatText "▄" -c light-cyan)$(formatText "▄" -c light-cyan -b cyan)$(formatText "█" -c cyan) "\
		"$(formatText "▄" -c white)$(formatText "▄" -c white -b light-gray)$(formatText "█" -c light-gray) ")

	local palette_bot=$(printf '%s'\
		"$(formatText "██" -c dark-gray)$(formatText "▀" -c black) "\
		"$(formatText "██" -c light-red)$(formatText "▀" -c red) "\
		"$(formatText "██" -c light-green)$(formatText "▀" -c green) "\
		"$(formatText "██" -c light-yellow)$(formatText "▀" -c yellow) "\
		"$(formatText "██" -c light-blue)$(formatText "▀" -c blue) "\
		"$(formatText "██" -c light-magenta)$(formatText "▀" -c magenta) "\
		"$(formatText "██" -c light-cyan)$(formatText "▀" -c cyan) "\
		"$(formatText "██" -c white)$(formatText "▀" -c light-gray) ")

	printInfoLine "" "$palette_top"
	printInfoLine "Color palette" "$palette_bot"
}



##------------------------------------------------------------------------------
##
printInfoCPUTemp()
{
	if ( which sensors > /dev/null 2>&1 ); then

		## GET VALUES
		local temp_line=$(sensors 2>/dev/null |\
		                  grep Core |\
		                  head -n 1 |\
		                  sed 's/^.*:[ \t]*//g;s/[\(\),]//g')
		local units=$(echo $temp_line |\
		              sed -n 's/.*\(°[[CF]]*\).*/\1/p')
		local current=$(echo $temp_line |\
		                sed -n 's/^.*+\(.*\)°[[CF]]*[ \t]*h.*/\1/p')
		local high=$(echo $temp_line |\
		             sed -n 's/^.*high = +\(.*\)°[[CF]]*[ \t]*c.*/\1/p')
		local max=$(echo $temp_line |\
		            sed -n 's/^.*crit = +\(.*\)°[[CF]]*[ \t]*.*/\1/p')


		## DETERMINE STATE
		if   (( $(echo "$current < $high" |bc -l) )); then 
			local state="nominal"
		elif (( $(echo "$current < $max" |bc -l) )); then 
			local state="critical";
		else                             
			local state="error";
		fi

		
		## PRINT MESSAGE
		local temp="$current$units"
		printInfoLine "CPU temp" "$temp" "$state"
	else
		printInfoLine "CPU temp" "lm-sensors not installed"
	fi

	
}



printResourceMonitor()
{
	local label=$1
	local value=$2
	local max=$3
	local units=$4
	local format=$5
	local crit_percent=$6	
	local error_percent=${7:-99}


	## CHECK STATE
	local percent=$('bc' <<< "$value*100/$max")
	local state="nominal"
	if   [ $percent -gt $error_percent ]; then
		local state="error"
	elif [ $percent -gt $crit_percent ]; then
		local state="critical"
	fi


	printInfoMonitor "$label" "$current_value" "$max" "$units" "$format" "$state"
}




##------------------------------------------------------------------------------
##
printMonitorCPU()
{
	assert_is_set $bar_cpu_units
	#assert_is_set $bar_cpu_crit_percent

	local format=$1
	local label="Sys load avg"
	local units=""
	local current_value=$(awk '{avg_1m=($1)} END {printf "%3.2f", avg_1m}' /proc/loadavg)
	local max=$(nproc --all)
	local crit_percent=$bar_cpu_crit_percent

	printResourceMonitor "$label" "$current_value" "$max" "$units" "$format" "$crit_percent"
}



##------------------------------------------------------------------------------
##
printMonitorRAM()
{
	assert_is_set $bar_ram_units
	assert_is_set $bar_ram_crit_percent

	local format=$1
	local label="Memory"

	case "$bar_ram_units" in
		"MB")		local units="MB"; local option="--mega" ;;
		"TB")		local units="TB"; local option="--tera" ;;
		"PB")		local units="PB"; local option="--peta" ;;
		*)		local units="GB"; local option="--giga" ;;
	esac

	local mem_info=$('free' "$option" | head -n 2 | tail -n 1)
	local current_value=$(echo "$mem_info" | awk '{mem=($2-$7)} END {printf mem}')
	local max=$(echo "$mem_info" | awk '{mem=($2)} END {printf mem}')
	local crit_percent=$bar_ram_crit_percent

	printResourceMonitor "$label" "$current_value" "$max" "$units" "$format" "$crit_percent"
}



##------------------------------------------------------------------------------
##
printMonitorSwap()
{
	assert_is_set $bar_swap_units
	assert_is_set $bar_swap_crit_percent

	local format=$1
	local label="Swap"

	case "$bar_swap_units" in
		"MB")		local units="MB"; local option="--mega" ;;
		"TB")		local units="TB"; local option="--tera" ;;
		"PB")		local units="PB"; local option="--peta" ;;
		*)		local units="GB"; local option="--giga" ;;
	esac

	## CHECK IF SYSTEM HAS SWAP
	## Count number of lines in /proc/swaps, excluding the header (-1)
	## This is not fool-proof, but if num_swap_devs>=1, there should be swap
	local num_swap_devs=$(($(wc -l /proc/swaps | awk '{print $1;}') -1))
	
	if [ "$num_swap_devs" -lt 1 ]; then
		printInfoLine "$label" "N/A"
	
	else
		local swap_info=$('free' "$option" | tail -n 1)
		local current_value=$(echo "$swap_info" | awk '{SWAP=($3)} END {printf SWAP}')
		local max=$(echo "$swap_info" | awk '{SWAP=($2)} END {printf SWAP}')
		local crit_percent=$bar_swap_crit_percent

		printResourceMonitor "$label" "$current_value" "$max" "$units" "$format" "$crit_percent"
	fi
}


##------------------------------------------------------------------------------
##
printStorageMonitor()
{
	local label=$1
	local device=$2
	local units=$3
	local format=$4
	local crit_percent=$5	
	local error_percent=${6:-99}

	case "$units" in
		"MB")		local units="MB"; local option="M" ;;
		"TB")		local units="TB"; local option="T" ;;
		"PB")		local units="PB"; local option="P" ;;
		*)		local units="GB"; local option="G" ;;
	esac

	local current_value=$(df "-B1${option}" "${device}" | grep / | awk '{key=($3)} END {printf key}')
	local max=$(df "-B1${option}" "${device}" | grep / | awk '{key=($2)} END {printf key}')
	printResourceMonitor "$label" "$current_value" "$max" "$units" "$format" "$crit_percent" "$error_percent"

}


##------------------------------------------------------------------------------
##
printMonitorHDD()
{
	assert_is_set $bar_hdd_units
	assert_is_set $bar_hdd_crit_percent

	local format=$1
	local label="Storage /"	
	local device="/"
	local units=$bar_hdd_units
	local crit_percent=$bar_hdd_crit_percent

	printStorageMonitor "$label" "$device" "$units" "$format" "$crit_percent"
}



##------------------------------------------------------------------------------
## 
printMonitorHome()
{
	assert_is_set $bar_home_units
	assert_is_set $bar_home_crit_percent

	local format=$1
	local label="Storage /home"	
	local device=$HOME
	local units=$bar_home_units
	local crit_percent=$bar_home_crit_percent

	printStorageMonitor "$label" "$device" "$units" "$format" "$crit_percent"
}



##------------------------------------------------------------------------------
##
printMonitorCPUTemp()
{
	if ( which sensors > /dev/null 2>&1 ); then

		## GET VALUES
		local temp_line=$(sensors |\
		                  grep Core |\
		                  head -n 1 |\
		                  sed 's/^.*:[ \t]*//g;s/[\(\),]//g')
		local units=$(echo $temp_line |\
		              sed -n 's/.*\(°[[CF]]*\).*/\1/p' )
		local current=$(echo $temp_line |\
		                sed -n 's/^.*+\(.*\)°[[CF]]*[ \t]*h.*/\1/p' )
		local high=$(echo $temp_line |\
		            sed -n 's/^.*high = +\(.*\)°[[CF]]*[ \t]*c.*/\1/p' )
		local max=$(echo $temp_line |\
		              sed -n 's/^.*crit = +\(.*\)°[[CF]]*[ \t]*.*/\1/p' )
		local crit_percent=$(bc <<< "$high*100/$max")

		
		## PRINT MONITOR
		printResourceMonitor $current $max $crit_percent \
	        	     false $units "CPU temp"
	else
		printInfoLine "CPU temp" "lm-sensors not installed"
	fi
}







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
			CPULOAD) printInfoCPULoad;;
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


		if [ $percent -gt $bar_cpu_crit_percent ]; then
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
if $clear_before_print; then clear; fi
if $print_extra_new_line_top; then echo ""; fi



## PRINT GREETER ELEMENTS
printHeader
printLastLogins
printSystemctl
printHogsCPU
printHogsMemory



## PRINT BOTTOM SPACER
if $print_extra_new_line_bot; then echo ""; fi
}



## RUN SCRIPT
## This whole script is wrapped with "{}" to avoid environment pollution.
## It's also called in a subshell with "()" to REALLY avoid pollution.
(greeter $1)
unset greeter


