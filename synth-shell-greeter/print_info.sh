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
##	DEPENDENCIES
##==============================================================================

include() { source "$( cd $( dirname "${BASH_SOURCE[0]}" ) >/dev/null 2>&1 && pwd )/$1" ; }
include '../bash-tools/bash-tools/print_bar.sh'
include '../bash-tools/bash-tools/assert.sh'


## CHECK EXTERNAL VARIABLES
assert_is_set $fc_ok
assert_is_set $fc_info
assert_is_set $fc_deco
assert_is_set $fc_crit
assert_is_set $fc_error
assert_is_set $fc_none
assert_not_empty $bar_num_digits






##==============================================================================
##	HELPERS
##==============================================================================



##==============================================================================
##	_getStateColor()
##	Select color formating code according to state:
##	nominal/critical/error
##
_getStateColor()
{
	local state=$1
	local E_PARAM_ERR=98

	case $state in
		nominal)	echo $fc_ok ;;
		critical)	echo $fc_crit ;;
		error)		echo $fc_error ;;
		*)		echo "$state not valid" ; exit $E_PARAM_ERR
	esac

}







##==============================================================================
##	printFraction()
##
##	Prints a color-formatted fraction with padding to reach MAX_DIGITS.
##
##	Arguments:
##	1. NUMERATOR:      first shown number
##	2. DENOMINATOR:    second shown number
##	3. PADDING_DIGITS: determines the minimum length of NUMERATOR and
##	                   DENOMINATOR. If they have less digits than this,
##	                   then extra spaces are appended for padding.
##	4. UNITS: a string that is attached to the end of the fraction,
##	          meant to include optional units (e.g. MB) for display purposes.
##	          If "none", no units are displayed.
##
##	Optional arguments:
##	5. STATE	Determines the color (nominal/critical/error)
##
_printFraction()
{
	local a=$1
	local b=$2
	local padding=$3
	local units=$4
	local state=${5:-nominal}

	local deco_color=$fc_info
	local num_color=$(_getStateColor $state)
	local units_color=$num_color

	if [ $units == "none" ]; then local units=""; fi

	printf "${num_color}%${padding}s" $a
	printf "${deco_color}/"
	printf "${num_color}%-${padding}s" $b
	printf "${units_color} ${units}${fc_none}"
}






##==============================================================================
##	_printResourceBar()
##
##
_printResourceBar()
{
	local label=$1
	local current=$2
	local max=$3
	local bar_length=$4
	local state=${5:-nominal}


	## CHOOSE COLORS AND PADDING
	local fc_label=${fc_info}
	local pad=$info_label_width
	local fc_fill_color=$(_getStateColor $state)
	local fc_bracket_color=$fc_deco


	## COMPOSE CHARACTERS FOR BAR
	local bracket_left=$fc_bracket_color$bar_bracket_char_left
	local fill=$fc_fill_color$bar_fill_char
	local background=$fc_none$bar_background_char
	local bracket_right=$fc_bracket_color$bar_bracket_char_right$fc_none


	## PRINT LABEL AND BAR
	printf "${fc_label}%-${pad}s" "$label"
	printBar "$current" "$max" "$bar_length" \
	         "$bracket_left" "$fill" "$background" "$bracket_right"
}





##==============================================================================
##	FUNCTIONS
##==============================================================================



##==============================================================================
##	printInfoLine()
##	Print a formatted message comprised of a label and a value
##
##	Arguments:
##	1. LABEL
##	2. VALUE
##
##	Optional arguments:
##	3. STATE	Determines the color (nominal/critical/error)
##
printInfoLine()
{
	local label=$1
	local value=$2
	local state=${3:-nominal}

	local fc_label=${fc_info}
	local fc_value=$(_getStateColor $state)
	local pad=$info_label_width

	printf "${fc_label}%-${pad}s${fc_value}${value}${fc_none}\n" "$label"
}






##==============================================================================
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
printResourceMonitor()
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
	local state="nominal"
	if   [ $percent -gt 99 ]; then
		local fc_bar_2=$fc_error
		local fc_txt_2=$fc_crit
		local state="error"
	elif [ $percent -gt $crit_percent ]; then
		local fc_bar_2=$fc_crit
		local fc_txt_2=$fc_crit
		local state="critical"
	fi


	## PRINT BAR
	_printResourceBar "$label" "$current" "$max" "$bar_length" "$state"

	## PRINT NUMERIC VALUE
	if $print_as_percentage; then
		printf "${fc_txt_2}%${bar_num_digits}s${fc_txt_1} %%%%${fc_none}" $percent
	else
		printf " "
		_printFraction "$current" "$max" "$bar_num_digits" "$units" "$state"
	fi
}



