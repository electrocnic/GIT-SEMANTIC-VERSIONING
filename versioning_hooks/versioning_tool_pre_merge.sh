#!/bin/sh
#

this_script_path=$(readlink -f "$0")
path_to_this_dir=$(dirname "$this_script_path")
source "${path_to_this_dir}/versioning_tool_config" 2>/dev/null
source "${path_to_this_dir}/versioning_tool_util.sh" 2>/dev/null

# What this script does:
# 1. git stash -> checkout other branch -> remember version number -> checkout back -> git stash pop. (REMEMBER: you are NOT in a mergeconflict at this point!)
# 2. both version-branches are remembered within this script.
# 3. compare and get greater version-branch ours or theirs.
# 4. 3 possibilities:
#
# 1. git merge does not produce conflicts. Then the version is already correct.
# 2. git merge does produce a version-file conflict: git checkout --ours/theirs version, then: delete backup and
# 3. no other files corrupt: commit directly, else, let user change their breaks and let them commit by hand.

contains() {
	string="$1"
	substring="$2"
	if test "${string#*$substring}" != "$string"
	then
		return 0    # $substring is in $string
	else
		return 1    # $substring is not in $string
	fi
}

correct_args() {
	result=""
	for i
	do
		whitespace_check=$(echo "$i" | sed -rne "s~(([[:graph:]]* [[:graph:]]*)+)~\1~p")
		if [ "$whitespace_check" == "" ]; then
			result="$result $i"
		else
			result="$result '$i'"
		fi
	done
	echo "$result"
}

get_other_branch_name() {
	#log "Get-other-branch-name: args are: $@"
	corrected_args=$(correct_args "$@")
	#corrected_args="$@"
	branchname=$(echo "$corrected_args" | sed -rne "s~merge((\s(-(S|(s|m|X)\s)('[[:print:]]+'|[[:graph:]]+)|(--[[:graph:]]+(=[[:graph:]]+)?|-n|-e|-q|-v|-S)))*\s)([[:graph:]]+)(\s(-(S|(s|m|X)\s)('[[:print:]]+'|[[:graph:]]+)|(--[[:graph:]]+(=[[:graph:]]+)?|-n|-e|-q|-v|-S)))*~\9~p")
	branchname=$(echo "$branchname" | sed -re "s~^ *~~g")
	if [ "$branchname" == "" ]; then
		echo ""
		return 1
	fi
	echo "$branchname"
}

backup_their_versions() {
	their_master="$master"
	their_major="$major"
	their_minor="$minor"
}

backup_our_versions() {
	our_master="$master"
	our_major="$major"
	our_minor="$minor"
}

get_greater_version() {
	parse_master_major_minor_count "$1"
	backup_their_versions
	parse_master_major_minor_count "$2"
	backup_our_versions

	if [ $our_master -gt $their_master ]; then
		result="our_version"
	elif [ $their_master -gt $our_master ]; then
		result="their_version"
	else
		if [ $our_major -gt $their_major ]; then
			result="our_version"
		elif [ $their_major -gt $our_major ]; then
			result="their_version"
		else
			if [ $our_minor -gt $their_minor ]; then
				result="our_version"
			else
				result="their_version"
			fi
		fi
	fi

	echo "$result"
}

parse_commit_message() {
	commit_msg=$(echo "$@" | sed -re "s~([[:print:]]*)(-m ((\'|\")[[:print:]]+(\'|\")|[[:graph:]]+))([[:print:]]*)~\2~g")
	contains "$commit_msg" "merge"
	res=$?
	if [ $res -eq 0 ]; then
		echo ""
		return 1
	fi
	echo "$commit_msg"
}

get_branch_names() {
	their_branch=$(get_other_branch_name "$@")
	log "Their branch: $their_branch"

	if [ "$their_branch" == "" ]; then
		echo "Could not parse remote branch to merge from. Aborting pre-merge hook"
		exit 0 #e.g. merge --abort has no other branch, so we must not stop the whole thing but just this script here.
	fi

	our_branch=$(get_branch_name)
	log "Our branch: $our_branch"
}

get_version_files() {
	stash_result=$(\git stash)
	log "Result of stash: $stash_result"
	\git checkout "$their_branch" >/dev/null 2>&1
	their_version=$(read_version_file)
	\git checkout "$our_branch" >/dev/null 2>&1
	if [ "$stash_result" != "No local changes to save" ]; then
		log "stash pop"
		\git stash pop >/dev/null 2>&1
	fi
	our_version=$(read_version_file)

	log "Our version: $our_version"
	log "Their version: $their_version"
}

merge_greater_version_and_remember_conflicts() {
	greater_version=$(get_greater_version "$their_version" "$our_version")
	log "Greater version: $greater_version"

	\git "$@" #>/dev/null 2>&1
	conflict_list=$(\git diff --name-only --diff-filter=U)
	log "Conflicts: $conflict_list"
}

resolve_and_commit_version_conflict() {
	if [ "$conflict_list" != "" ]; then
		delete_file "${backup_file}"

		if [ "$greater_version" == "our_version" ]; then
			\git checkout --ours "${version_file}"
		elif [ "$greater_version" == "their_version" ]; then
			\git checkout --theirs "${version_file}"
		fi

		if [ "$conflict_list" == "$version_file" ]; then
			commit_message=$(parse_commit_message "$@")
			"${path_to_this_dir}/versioning_tool_pre_commit.sh" "merge"
			\git add "${version_file}"
			if [ "$commit_message" != "" ]; then
				\git commit "$commit_message" # -m is in commit_message.
			else
				\git commit
			fi
		fi
	fi
}

set_merge_flag_for_post_commit_hook() {
	touch "${path_to_this_dir}/../merging"
}

set_merge_flag_for_post_commit_hook
get_branch_names "$@"
get_version_files
merge_greater_version_and_remember_conflicts "$@"
resolve_and_commit_version_conflict
