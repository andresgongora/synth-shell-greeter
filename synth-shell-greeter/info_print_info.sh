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
[ "$(type -t include)" != 'function' ]&&{ include(){ { [ -z "$_IR" ]&&_IR="$PWD"&&cd $(dirname "${BASH_SOURCE[0]}")&&include "$1"&&cd "$_IR"&&unset _IR;}||{ local d=$PWD&&cd "$(dirname "$PWD/$1")"&&. "$(basename "$1")"&&cd "$d";}||{ echo "Include failed $PWD->$1"&&exit 1;};};}

include '../bash-tools/bash-tools/print_bar.sh'
include '../bash-tools/bash-tools/assert.sh'






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
	assert_is_set $fc_ok
	assert_is_set $fc_info
	assert_is_set $fc_deco
	assert_is_set $fc_crit
	assert_is_set $fc_error

	local state=$1
	local E_PARAM_ERR=98
	local fc_none="\e[0m"

	case $state in
		nominal)	echo $fc_ok ;;
		critical)	echo $fc_crit ;;
		error)		echo $fc_error ;;
		*)		echo $fc_none ; exit $E_PARAM_ERR
	esac

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
	assert_is_set $info_label_width


	## ARGUMENTS
	local label=$1
	local value=$2
	local state=${3:-nominal}


	## FORMAT
	local fc_label=${fc_info}
	local fc_value=$(_getStateColor $state)
	local fc_none="\e[0m"
	local padding_label=$info_label_width


	## PRINT LABEL AND VALUE
	printf "${fc_label}%-${padding_label}s${fc_value}${value}${fc_none}\n" "$label"
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
printInfoMonitor()
{
	assert_is_set $info_label_width
	assert_is_set $bar_num_digits
	assert_is_set $bar_length
	assert_is_set $bar_padding_after


	## ARGUMENTS
	local label=$1
	local value=$2
	local max=$3
	local units=$4
	local format=${5:-fraction}
	local state=${6:-nominal}	


	## FORMAT OPTIONS
	local fc_label=${fc_info}
	local fc_value=$(_getStateColor $state)
	local fc_units=$fc_info
	local fc_fill_color=$fc_value
	local fc_bracket_color=$fc_deco
	local fc_none="\e[0m"
	local padding_label=$info_label_width
	local padding_value=$bar_num_digits
	local padding_bar=$bar_padding_after


	## COMPOSE CHARACTERS FOR BAR
	local bracket_left=$fc_bracket_color$bar_bracket_char_left
	local fill=$fc_fill_color$bar_fill_char
	local background=$fc_none$bar_background_char
	local bracket_right=$fc_bracket_color$bar_bracket_char_right$fc_none


	## PRINT LABEL
	printf "${fc_label}%-${padding_label}s" "$label"


	## PRINT BAR
	printBar "$value" "$max" "$bar_length" \
	         "$bracket_left" "$fill" "$background" "$bracket_right"
	printf "%${bar_padding_after}s" ""


	## PRINT VALUE
	case $format in
		"a/b")	
			printf "${fc_value}%${padding_value}s" $value
			printf "${fc_deco}/"
			printf "${fc_value}%-${padding_value}s" $max
			printf "${fc_units} ${units}${fc_none}"
			;;

		'0/0')		
			if [ -z $(which 'bc' 2>/dev/null) ]; then
				printf "${fc_error} bc not installed${fc_none}"
			else
				local percent=$('bc' <<< "$value*100/$max")
				printf "${fc_value}%${padding_value}s${fc_units}%%%%${fc_none}" $percent
			fi
			;;

		*)	
			echo "Invalid format option $format"
	esac
}

	

