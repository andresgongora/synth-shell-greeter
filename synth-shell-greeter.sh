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
##==============================================================================
##	INFO AND MONITOR PRINTING HELPERS
##==============================================================================

##------------------------------------------------------------------------------
##
##	printInfo(LABEL, VALUE)
##	Print a formatted message comprised of a label and a value
##	1. LABEL will be printed with info color
##	2. VALUE will be printed with highlight color
##
printInfo()
{
	label=$1
	value=$2
	pad=$info_label_width

	printf "${fc_info}%-${pad}s${fc_highlight}${value}${fc_none}\n" "$label"
}



##------------------------------------------------------------------------------
##
##	printBar(CURRENT, MAX, SIZE, COLOR, COLOR)
##
##	Prints a bar that is filled depending on the relation between
##	CURRENT and MAX
##
##	1. CURRENT:       amount to display on the bar.
##	2. MAX:           amount that means that the bar should be printed
##	                  completely full.
##	3. SIZE:          length of the bar as number of characters.
##	4. BRACKET_COLOR: Color for the brackets. May be empty for not colored.
##	5. BAR_COLOR:	  Color for the bars. May be empty for not colored.
##
printBar()
{
	## VARIABLES
	local current=$1
	local max=$2
	local size=$3
	local bracket_color=$4
	local bar_color=$5


	## COMPUTE VARIABLES
	local num_bars=$(bc <<< "$size * $current / $max")
	if [ $num_bars -gt $size ]; then
		num_bars=$size
	fi


	## PRINT BAR
	## - Opening bracket
	## - Full bars
	## - Remaining empty space
	## - Closing bracket
	printf "${bracket_color}[${bar_color}"
	i=0
	while [ $i -lt $num_bars ]; do
		printf "|"
		i=$[$i+1]
	done
	while [ $i -lt $size ]; do
		printf " "
		i=$[$i+1]
	done
	printf "${bracket_color}]${fc_none}"
}



##------------------------------------------------------------------------------
##
##	printFraction(NUMERATOR, DENOMINATOR, PADDING_DIGITS, UNITS)
##
##	Prints a color-formatted fraction with padding to reach MAX_DIGITS.
##
##	1. NUMERATOR:      first shown number
##	2. DENOMINATOR:    second shown number
##	3. PADDING_DIGITS: determines the minimum length of NUMERATOR and
##	                   DENOMINATOR. If they have less digits than this,
##	                   then extra spaces are appended for padding.
##	4. UNITS: a string that is attached to the end of the fraction,
##	          meant to include optional units (e.g. MB) for display purposes.
##	          If "none", no units are displayed.
##	5,6,7. COLORS: of decoration (/), numbers, and units.
##
printFraction()
{
	local a=$1
	local b=$2
	local padding=$3
	local units=$4
	local deco_color=$5
	local num_color=$6
	local units_color=$7

	if [ $units == "none" ]; then local units=""; fi

	printf "${num_color}%${padding}s" $a
	printf "${deco_color}/"
	printf "${num_color}%-${padding}s" $b
	printf "${units_color} ${units}${fc_none}"
}



##------------------------------------------------------------------------------
##
##	printMonitor()
##
##	Prints a resource utilization monitor, comprised of a bar and a fraction.
##
##	1. CURRENT: current resource utilization (e.g. occupied GB in HDD)
##	2. MAX: max resource utilization (e.g. HDD size)
##	3. CRIT_PERCENT: point at which to warn the user (e.g. 80 for 80%)
##	4. PRINT_AS_PERCENTAGE: whether to print a simple percentage after
##	   the utilization bar (true), or to print a fraction (false).
##	5. UNITS: units of the resource, for display purposes only. This are
##	   not shown if PRINT_AS_PERCENTAGE=true, but must be set nonetheless.
##	6. LABEL: A description of the resource that will be printed in front
##	   of the utilization bar.
##
printMonitor()
{
	## CHECK EXTERNAL CONFIGURATION
	if [ -z $bar_num_digits ]; then exit 1; fi
	if [ -z $fc_deco        ]; then exit 1; fi
	if [ -z $fc_ok          ]; then exit 1; fi
	if [ -z $fc_info        ]; then exit 1; fi
	if [ -z $fc_crit        ]; then exit 1; fi


	## VARIABLES
	local current=$1
	local max=$2
	local crit_percent=$3
	local print_as_percentage=$4
	local units=$5
	local label=${@:6}
	local pad=$info_label_width


	## CHECK VARIABLES
	## If max is empty, assign 0
	## If crit percent is empty, assign 100
	## If crit_percent > 100, assign 100
	if [ -z $max ]; then local max=0; fi
	if [ -z $crit_percent ]; then local local crit_percent=100; fi
	if [ "$crit_percent" -gt 100 ]; then local crit_percent=100; fi


	## COMPUTE PERCENT
	## If max=0, then avoid division
	## Otherwise compute as usual
	if [ "$max" -eq 0 ]; then
		local percent=100
	else
		local percent=$(bc <<< "$current*100/$max")
	fi


	## SET COLORS DEPENDING ON LOAD
	local fc_bar_1=$fc_deco
	local fc_bar_2=$fc_ok
	local fc_txt_1=$fc_info
	local fc_txt_2=$fc_ok
	local fc_txt_3=$fc_ok
	if   [ $percent -gt 99 ]; then
		local fc_bar_2=$fc_error
		local fc_txt_2=$fc_crit
	elif [ $percent -gt $crit_percent ]; then
		local fc_bar_2=$fc_crit
		local fc_txt_2=$fc_crit
	fi


	## PRINT BAR
	printf "${fc_info}%-${pad}s" "$label"
	printBar $current $max $bar_length $fc_bar_1 $fc_bar_2


	## PRINT NUMERIC VALUE
	if $print_as_percentage; then
		printf "${fc_txt_2}%${bar_num_digits}s${fc_txt_1} %%%%${fc_none}" $percent
	else
		printf " "
		printFraction $current $max $bar_num_digits $units \
		              $fc_txt_1 $fc_txt_2 $fc_txt_3
	fi
}





##==============================================================================
##	INFO
##==============================================================================

include() { source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/$1" ; }
include 'functions/info_os.sh'
include 'functions/info_hardware.sh'
include 'functions/info_network.sh'

printInfoOS() { printInfo "OS" "$(getNameOS)" ; }
printInfoKernel() { printInfo "Kernel" "$(getNameKernel)" ; }
printInfoShell() { printInfo "Shell" "$(getNameShell)" ; }
printInfoDate() { printInfo "Date" "$(getDate)" ; }
printInfoUptime() { printInfo "Uptime" "$(getUptime)" ; }
printInfoUser() { printInfo "User" "$(getUserHost)" ; }
printInfoNumLoggedIn() { printInfo "Logged in" "$(getNumberLoggedInUsers)" ; }
printInfoNameLoggedIn() { printInfo "Logged in" "$(getNameLoggedInUsers)" ; }

printInfoCPU() { printInfo "CPU" "$(getNameCPU)" ; }
printInfoGPU() { printInfo "GPU" "$(getNameGPU)" ; }
printInfoCPUUtilization() { printInfo "Sys load" "$(getCPUUtilization)" ; }

printInfoLocalIPv4() { printInfo "Local IPv4" "$(getLocalIPv4)" ; }
printInfoExternalIPv4() { printInfo "External IPv4" "$(getExternalIPv4)" ; }

printInfoSpacer() { printInfo "" "" ; }




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
	elif [ "$systcl_num_failed" -eq "1" ]; then
		local sysctl="${fc_error}1 service failed!${fc_none}"
	else
		local sysctl="${fc_error}$systcl_num_failed services failed!${fc_none}"
	fi

	printInfo "Services" "$sysctl"
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

	printInfo "Color palette" "$palette"
}



##------------------------------------------------------------------------------
##
printInfoColorpaletteFancy()
{
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

	printInfo "Color palette" "$palette_top"
	printInfo "" "$palette_bot"
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


		## COMPOSE MESSAGE
		if   (( $(echo "$current < $high" |bc -l) )); then 
			local temp="$current$units";
		elif (( $(echo "$current < $max" |bc -l) )); then 
			local temp="$fc_crit$current$units";
		else                             
			local temp="$fc_error$current$units";
		fi

		
		## PRINT MESSAGE
		printInfo "CPU temp" "$temp"
	else
		printInfo "CPU temp" "lm-sensors not installed"
	fi

	
}



##------------------------------------------------------------------------------
##
printMonitorCPU()
{
	local message="Sys load avg"
	local units="none"
	local current=$(awk '{avg_1m=($1)} END {printf "%3.2f", avg_1m}' /proc/loadavg)
	local max=$(nproc --all)


	local as_percentage=$1
	if [ -z "$as_percentage" ]; then local as_percentage=false; fi


	printMonitor $current $max $crit_cpu_percent \
	             $as_percentage $units $message
}



##------------------------------------------------------------------------------
##
printMonitorRAM()
{
	## CHOOSE UNITS
	case "$memory_units" in
		"MB")		local units="MB"; local option="--mega" ;;
		"TB")		local units="TB"; local option="--tera" ;;
		"PB")		local units="PB"; local option="--peta" ;;
		*)		local units="GB"; local option="--giga" ;;
	esac


	local message="Memory"
	local mem_info=$('free' "$option" | head -n 2 | tail -n 1)
	local current=$(echo "$mem_info" | awk '{mem=($2-$7)} END {printf mem}')
	local max=$(echo "$mem_info" | awk '{mem=($2)} END {printf mem}')


	local as_percentage=$1
	if [ -z "$as_percentage" ]; then local as_percentage=false; fi


	printMonitor $current $max $crit_ram_percent \
	             $as_percentage $units $message
}



##------------------------------------------------------------------------------
##
printMonitorSwap()
{
	## CHOOSE UNITS
	case "$swap_units" in
		"MB")		local units="MB"; local option="--mebi" ;;
		"TB")		local units="TB"; local option="--tebi" ;;
		"PB")		local units="PB"; local option="--pebi" ;;
		*)		local units="GB"; local option="--gibi" ;;
	esac


	local message="Swap"
	local as_percentage=$1
	if [ -z "$as_percentage" ]; then local as_percentage=false; fi


	## CHECK IF SYSTEM HAS SWAP
	## Count number of lines in /proc/swaps, excluding the header (-1)
	## This is not fool-proof, but if num_swap_devs>=1, there should be swap
	local num_swap_devs=$(($(wc -l /proc/swaps | awk '{print $1;}') -1))
	
	if [ "$num_swap_devs" -lt 1 ]; then ## NO SWAP
		

		local pad=${info_label_width}
		printf "${fc_info}%-${pad}s${fc_highlight}N/A${fc_none}" "${message}"
	
	else ## HAS SWAP	
		local swap_info=$('free' "$option" | tail -n 1)
		local current=$(echo "$swap_info" |\
		                awk '{SWAP=($3)} END {printf SWAP}')
		local max=$(echo "$swap_info" |\
		            awk '{SWAP=($2)} END {printf SWAP}')

		printMonitor $current $max $crit_swap_percent \
		             $as_percentage $units $message
	fi
}



##------------------------------------------------------------------------------
##
printMonitorHDD()
{
	local as_percentage=$1
	if [ -z "$as_percentage" ]; then local as_percentage=false; fi


	## CHOOSE UNITS
	case "$hdd_units" in
		"MB")		local units="MB"; local option="M" ;;
		"TB")		local units="TB"; local option="T" ;;
		"PB")		local units="PB"; local option="P" ;;
		*)		local units="GB"; local option="G" ;;
	esac


	local message="Storage /"
	local units="GB"
	local current=$(df "-B1${option}" / | grep "/" |awk '{key=($3)} END {printf key}')
	local max=$(df "-B1${option}" / | grep "/" | awk '{key=($2)} END {printf key}')


	printMonitor $current $max $crit_hdd_percent \
	             $as_percentage $units $message
}



##------------------------------------------------------------------------------
## 
printMonitorHome()
{
	local as_percentage=$1
	if [ -z "$as_percentage" ]; then local as_percentage=false; fi

	
	## CHOOSE UNITS
	case "$home_units" in
		"MB")		local units="MB"; local option="M" ;;
		"TB")		local units="TB"; local option="T" ;;
		"PB")		local units="PB"; local option="P" ;;
		*)		local units="GB"; local option="G" ;;
	esac


	local message="Storage /home"
	local current=$(df "-B1${option}" ~ | grep "/" |awk '{key=($3)} END {printf key}')
	local max=$(df "-B1${option}" ~ | grep "/" | awk '{key=($2)} END {printf key}')


	printMonitor $current $max $crit_home_percent \
	             $as_percentage $units $message
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
		printMonitor $current $max $crit_percent \
	        	     false $units "CPU temp"
	else
		printInfo "CPU temp" "lm-sensors not installed"
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
			CPUUTILIZATION) printInfoCPUUtilization;;
			CPUTEMP)        printInfoCPUTemp;;

		## 	USAGE MONITORS (BARS)
		##	NAME            FUNCTION               AS %
			SYSLOAD_MON)    printMonitorCPU;;
			SYSLOAD_MON%)   printMonitorCPU        true;;
			MEMORY_MON)     printMonitorRAM;;
			MEMORY_MON%)    printMonitorRAM        true;;
			SWAP_MON)       printMonitorSwap;;
			SWAP_MON%)      printMonitorSwap       true;;
			HDDROOT_MON)    printMonitorHDD;;
			HDDROOT_MON%)   printMonitorHDD        true;;
			HDDHOME_MON)    printMonitorHome;;
			HDDHOME_MON%)   printMonitorHome       true;;
			CPUTEMP_MON)    printMonitorCPUTemp;;

			*)              printInfo "Unknown" "Check your config";;
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

	## CHECK GLOBAL PARAMETERS
	if [ -z $crit_cpu_percent   ]; then return ; fi
	if [ -z $print_cpu_hogs_num ]; then local print_cpu_hogs_num=3 ; fi
	if [ -z $print_cpu_hogs     ]; then return ; fi


	## EXIT IF NOT ENABLED
	if [ "$print_cpu_hogs"==true] ; then
		## CHECK CPU LOAD
		local current=$(awk '{avg_1m=($1)} END {printf "%3.2f", avg_1m}' /proc/loadavg)
		local max=$(nproc --all)
		local percent=$(bc <<< "$current*100/$max")


		if [ $percent -gt $crit_cpu_percent ]; then
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
				      head -n "$print_cpu_hogs_num" )


			## PRINT WITH FORMAT
			printf "\n${fc_crit}SYSTEM LOAD:${fc_info}  ${load}\n"
			printf "${fc_crit}$header${fc_none}\n"
			printf "${fc_info}${procs}${fc_none}\n"
		fi
	fi
}



##------------------------------------------------------------------------------
##
printHogsMemory()
{
	## CHECK GLOBAL PARAMETERS
	if [ -z $crit_ram_percent  ]; then return; fi
	if [ -z $crit_swap_percent ]; then return; fi
	if [ -z $print_memory_hogs ]; then local print_memory_hogs=3 ; fi


	## EXIT IF NOT ENABLED
	if [ "$print_memory_hogs"==true ]; then
		## CHECK RAM
		local ram_is_crit=false
		local mem_info=$('free' -m | head -n 2 | tail -n 1)
		local current=$(echo "$mem_info" | awk '{mem=($2-$7)} END {printf mem}')
		local max=$(echo "$mem_info" | awk '{mem=($2)} END {printf mem}')
		local percent=$(bc <<< "$current*100/$max")
		if [ $percent -gt $crit_ram_percent ]; then
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
			if [ $percent -gt $crit_swap_percent ]; then
				local swap_is_crit=true
			fi
		fi

		## PRINT IF RAM OR SWAP ARE ABOVE THRESHOLD
		if $ram_is_crit || $swap_is_crit ; then
			local available=$(echo $mem_info | awk '{print $NF}')
			local procs=$(ps --cols=80 -eo pmem,size,pid,cmd --sort=-%mem |\
				      head -n 4 | tail -n 3 |\
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
##	MAIN FUNCTION
##==============================================================================


## INCLUDE EXTERNAL DEPENDENCIES
include() { source "$( cd $( dirname "${BASH_SOURCE[0]}" ) >/dev/null 2>&1 && pwd )/$1" ; }
include 'bash-tools/bash-tools/color.sh'
include 'bash-tools/bash-tools/print_utils.sh'
include 'config/synth-shell-greeter.config.default'



## LOAD USER CONFIGURATION
local target_config_file=$1
local user_config_file="$HOME/.config/synth-shell/synth-shell-greeter.config"
local root_config_file="/etc/synth-shell/os/synth-shell-greeter.root.config"
local sys_config_file="/etc/synth-shell/synth-shell-greeter.config"
if   [ -f "$target_config_file" ]; then source "$target_config_file" ;
elif [ -f "$user_config_file" ]; then   source "$user_config_file" ;
elif [ "$USER" == "root" -a -f $root_config_file ]; then source "$root_config_file" ;
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



### EOF ###
