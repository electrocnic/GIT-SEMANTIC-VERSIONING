#!/bin/bash

this_script_path=$(readlink -f "$0")
path_to_this_dir=$(dirname "$this_script_path")
source "${path_to_this_dir}/versioning_tool_config" 2>/dev/null


log() {
	if [ $log_active -eq 1 ]; then
		echo "$1"
	fi
}

write_version_to_file() {
	log "write_version_to_file: \"$1\""
	touch "${version_file}"
	echo "$1" > "${version_file}"
	# TODO: Uncomment the lines below if you want to automatically adapt the version in a pom file.
	#POM_LINE="<version>$1</version>"
	#sed -i "s~.*<version>[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+</version>~  ${POM_LINE}~g" pom.xml
}

parse_master_major_minor_count() {
	#log "parse_master_major_minor_count."
	master=$(echo "$1" | sed -re "s~([0-9]+).([0-9]+).([0-9]+).([0-9]+)~\1~g")
	major=$(echo "$1" | sed -re "s~([0-9]+).([0-9]+).([0-9]+).([0-9]+)~\2~g")
	minor=$(echo "$1" | sed -re "s~([0-9]+).([0-9]+).([0-9]+).([0-9]+)~\3~g")
	count=$(echo "$1" | sed -re "s~([0-9]+).([0-9]+).([0-9]+).([0-9]+)~\4~g")
}

get_branch_name() {
	branch_name="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
	if [ $? -ne 0 ]; then
		branch_name="master"
	fi
	echo "$branch_name"
}

exit_1() {
	git reset "${version_file}" 2>/dev/null
	rm -f "${version_file}" 2>/dev/null
	exit 1
}

read_line_of_file() {
	while read -r line || [[ -n "$line" ]]; do
		result="${line}"
	done < "$1"
	echo "${result}"
}

copy_file() {
	log "copy_file: $1"
	cp "$1" "$2" 2>/dev/null
}

rename_file() {
	log "rename_file: $1"
	mv "$1" "$2" 2>/dev/null
}

delete_file() {
	log "delete_file: $1"
	rm "$1" 2>/dev/null
}

read_version_file() {
	echo $(read_line_of_file "${version_file}")
}

is_file_empty() {
	word_count=$(wc -w "$1")
	log "Word count in file is: $word_count"
	if [[ $word_count == 0* ]]; then
		return 1
	fi
	return 0
}
