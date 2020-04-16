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
##	QUICK INSTALLER
##




##==============================================================================
##
include(){ [ -z "$_IR" ]&&_IR="$PWD"&&cd $( dirname "$PWD/$0" )&&. "$1"&&cd "$_IR"&&unset _IR||. $1;}
include 'bash-tools/bash-tools/user_io.sh'
include 'bash-tools/bash-tools/hook_script.sh'
include 'bash-tools/bash-tools/assemble_script.sh'


## SWITCH BETWEEN AUTOMATIC AND USER INSTALLATION
if [ "$#" -eq 0 ]; then
	OUTPUT_SCRIPT="$HOME/.config/synth-shell/synth-shell-greeter.sh"
	OUTPUT_CONFIG_DIR="$HOME/.config/synth-shell"
	cp "$OUTPUT_CONFIG_DIR/synth-shell-greeter.config" \
		 "$OUTPUT_CONFIG_DIR/synth-shell-greeter.config.backup"
	printInfo "Installing script as $OUTPUT_SCRIPT"
	USER_CHOICE=$(promptUser "Add hook your .bashrc file or equivalent?\n\tRequired for autostart on new terminals" "[Y]/[n]?" "yYnN" "y")
	case "$USER_CHOICE" in
		""|y|Y )	hookScript $OUTPUT_SCRIPT ;;
		n|N )		;;
		*)		printError "Invalid option"; exit 1
	esac
		
else
	OUTPUT_SCRIPT="$1"
	OUTPUT_CONFIG_DIR="$2"
fi


## DEFINE LOCAL VARIABLES
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
INPUT_SCRIPT="$DIR/synth-shell-greeter/synth-shell-greeter.sh"
INPUT_CONFIG_DIR="$DIR/config"


## HEADER TO BE ADDED AT THE TOP OF THE ASSEMBLED SCRIPT
OUTPUT_SCRIPT_HEADER=$(printf '%s'\
	"##\n"\
	"##\n"\
	"##  =======================\n"\
	"##  WARNING!!\n"\
	"##  DO NOT EDIT THIS FILE!!\n"\
	"##  =======================\n"\
	"##\n"\
	"##  This file was generated by an installation script.\n"\
	"##  It might be overwritten without warning at any time\n"\
	"##  and you will lose all your changes.\n"\
	"##\n"\
	"##  Visit for instructions and more information:\n"\
	"##  https://github.com/andresgongora/synth-shell/\n"\
	"##\n"\
	"##\n\n\n")


## SETUP SCRIPT
assembleScript "$INPUT_SCRIPT" "$OUTPUT_SCRIPT" "$OUTPUT_SCRIPT_HEADER"


## SETUP CONFIGURATION FILES
[ -d "$OUTPUT_CONFIG_DIR" ] || mkdir -p "$OUTPUT_CONFIG_DIR"
cp -r "$INPUT_CONFIG_DIR/." "$OUTPUT_CONFIG_DIR/"


## SETUP DEFAULT SYNTH-SHELL-GREETER CONFIG FILE
CONFIG_FILE="$OUTPUT_CONFIG_DIR/synth-shell-greeter.config"
if [ ! -f  "$CONFIG_FILE" ]; then
	local DISTRO=$(cat /etc/os-release | grep "ID=" | sed 's/ID=//g' | head -n 1)		
	case "$DISTRO" in
		'arch' )	cp "$OUTPUT_CONFIG_DIR/os/synth-shell-greeter.archlinux.config" "$CONFIG_FILE" ;;
		'manjaro' )	cp "$OUTPUT_CONFIG_DIR/os/synth-shell-greeter.manjaro.config" "$CONFIG_FILE" ;;
		*)		cp "$OUTPUT_CONFIG_DIR/synth-shell-greeter.config.default" "$CONFIG_FILE" ;;
	esac
fi
