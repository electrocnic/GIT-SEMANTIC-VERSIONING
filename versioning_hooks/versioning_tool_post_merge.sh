#!/bin/bash
#
# Call this shell script from within git's post-merge file.
#
# Updates the commit count of the version file.
# Updates also the commit message if version_in_commit_message is true.
#


source .git/hooks/versioning_tool_config 2>/dev/null
source .git/hooks/versioning_tool_util.sh 2>/dev/null

log "POST-MERGE HOOK"

disable_hooks() {
	touch ".git/hooks-disabled" 2>/dev/null
}

enable_hooks() {
	rm ".git/hooks-disabled" 2>/dev/null
}

prepare_new_merge_message() {
	old_message=$(\git log -1 --pretty=%B)
	old_message_without_version=$(echo "$old_message" | sed -re "s~(\[[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+]:)?( )*([[:print:]]*)~\3~g")
	if [ $version_in_commit_message -eq 1 ]; then
		echo "[$1]: $old_message_without_version"
	else
		echo "$old_message_without_version"
	fi
}

# ---------------------- Start ---------------------- #
if [ -e "${path_to_this_dir}/../pull" ]; then
	rm "${path_to_this_dir}/../pull" 2>/dev/null
	exit 0
fi

disable_hooks
# read version file
full_version_string=$(read_version_file)
# set last number to commit-count
parse_master_major_minor_count "$full_version_string"
count=$(\git rev-list --count HEAD 2>/dev/null)
# prepare version string
new_version="${master}.${major}.${minor}.${count}"
# write version file.
log "Writing new version POST-MERGE to file: $new_version"
write_version_to_file "$new_version"
\git add "$version_file" 2>/dev/null
new_message=$(prepare_new_merge_message "$new_version")
\git commit --amend -m "$new_message"
enable_hooks

rm ".git/merging" 2>/dev/null

# Delete backup file as commit was successful:
delete_file "${backup_file}"