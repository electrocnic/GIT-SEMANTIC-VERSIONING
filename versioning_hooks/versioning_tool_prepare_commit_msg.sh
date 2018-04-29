#!/bin/bash
#
# Call this shell script from within git's prepare-commit-msg file.
# Simply do .git/hooks/versioning_tool_prepare_commit_msg.sh "$1" inside prepare-commit-msg
# Don't forget to append "$1" as argument for versioning_tool_prepare_commit_msg.sh!
#

this_script_path=$(readlink -f "$0")
path_to_this_dir=$(dirname "$this_script_path")
source "${path_to_this_dir}/versioning_tool_config" 2>/dev/null
source "${path_to_this_dir}/versioning_tool_util.sh" 2>/dev/null

log "versioning_tool_prepare_commit_msg.sh: Adding version to commit message."

if [ -f ".git/hooks-disabled" ]; then
	exit 0
fi

if [ "$1" = ".git/MERGE_MSG" ]; then
	log "MERGE! calling versioning_tool_pre_commit.sh from within versioning_tool_prepare_commit_msg.sh"
	.git/hooks/versioning_tool_pre_commit.sh "merge"
fi

full_version=$(read_version_file)
log "Full version: ${full_version}"
short_version=$(echo "${full_version}" | sed -re "s~([0-9]+.[0-9]+.[0-9]+.[0-9]+)~\1~g") #TODO: if does not match, add any char any times to end of regex.
log "Short version: ${short_version}"

if [ $version_in_commit_message -eq 1 ]; then
	sed -i.bak -e "1s~^~[$short_version]: ~g" "$1"
fi

exit 0
