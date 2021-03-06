#!/bin/sh
#  pp - the text preprocessor
#  Copyright (C) 2020  Joe Jenne
#  
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#  

VERSION_STRING='pp - preprocessing script\nversion: 0.1.0\nlicense: GNU General Public License, version 3\n'

die() {
	# Fail in style, exit with 1, arg 3 means no fail
	#
	printf '\033[1;33m%s \033[1;36m%s\033[m %s\n' "${3-!>}" "$1" "$2" >&2
	[ -z "$3" ] && exit 1
}

usage() {
	# Print help message
	#
	printf '\nUsage: %s INPUT-FILE\n' "${0##*/}"
	printf '  -h, --help                Display help\n'
	printf '  -v, --version             Print version information\n'
	printf 'Syntax:\n'
	printf '  * A line beginning with !! has the following text evaluated\n    as a shell command.\n'
	printf '  * $FILE is the filename, relative to PWD\n'
	printf '  * $line refers to the contents of the line itself\n'
	printf '  * $ln is the current line number\n'
	printf '%s also accept stdin if no INPUT-FILE is given' "${0##*/}"
	printf '\n'
}

args(){
	# Parse arguments, 
	#
	# Parse 0 or 1 arguments
	case $# in
		0) # Standard input or fail
			[ -t 0 ] && die "IN_ERR" "No input text provided" ||
				FILE='/dev/stdin'
			;;
		1) # Parse the lone argument, no '-' prefix means filename
			case $1 in
				--help|-h) usage; exit;;
				--version|-v) printf '%b' "$VERSION_STRING"; exit;;
				-*) die "FLAG_ERR" "unrecognized option \`$1'" "!>"
					usage; exit 1;;
				*) FILE="$1";;
			esac
			;;
		*) # More than one argument is too many
			die "IN_ERR" "Too many arugments";;
	esac

	# Make sure the input now exists: -e option to capture the
	# symbolic link '/dev/stdin' too
	[ ! -e "$FILE" ] && 
		die "IN_ERR" "${FILE}: no such file exists"
}

process(){
	# Takes its first argument and runs the substitution and expansion logic on it.
	while IFS= read -r line; do
		ln=$((ln+1))
		case $line in
			!!*) line="${line##!!}"
				line="${line#${line%%[![:space:]]*}}"
				eval " $line" 2>/dev/null|| 
				die "EVAL_ERR" "LINE $ln: evaluation error";;
			*) echo "$line";;
		esac
	done < "$FILE"
}

args "$@"
process
