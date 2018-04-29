#!/bin/bash
#
# Call this shell script from within git's post-commit file.
# Simply do .git/hooks/versioning_tool_post_commit.sh inside post-commit
#

source .git/hooks/versioning_tool_config 2>/dev/null
source .git/hooks/versioning_tool_util.sh 2>/dev/null

if [ -f ".git/hooks-disabled" ]; then
	exit 0
fi

log "versioning_tool_post_commit.sh: Deleting backup as commit was successful."
delete_file "${backup_file}"

if [ -f ".git/merging" ]; then
	.git/hooks/versioning_tool_post_merge.sh "$@"
fi

log "POST COMMIT Called with \"$@\""
