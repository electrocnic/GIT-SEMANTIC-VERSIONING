#!/bin/sh
#
# Call this shell script from within git's pre-commit file.
# Simply do .git/hooks/versioning_tool_pre_commit.sh inside pre-commit
#

#source .git/hooks/versioning_tool_config
#source .git/hooks/versioning_tool_util.sh
this_script_path=$(readlink -f "$0")
path_to_this_dir=$(dirname "$this_script_path")
source "${path_to_this_dir}/versioning_tool_config" 2>/dev/null
source "${path_to_this_dir}/versioning_tool_util.sh" 2>/dev/null

log "versioning_tool_pre_commit.sh: Calculating new version"

parse_master_major_minor_buildup() {
	# only if both, m and d are 1, the next commit on d will increment d.
	# if m is 1 but d is 0, the next commit should fail.
	# m 0 d 1 is not possible.
	log "parse_master_major_minor_buildup."
	if [ "$1" == "" ]; then
		master_commit=0
		major_commit=0
		minor_commit=0
	else
		master_commit=$(echo "$1" | sed -re "s~mas([01])maj([01])min([01])~\1~g")
		major_commit=$(echo "$1" | sed -re "s~mas([01])maj([01])min([01])~\2~g")
		minor_commit=$(echo "$1" | sed -re "s~mas([01])maj([01])min([01])~\3~g")
	fi
}

read_buildup_file_if_exists_and_parse_m_m_m() {
	log "read_buildup_file_if_exists_and_parse_m_m_m..."
	if [ -f "${buildup_file}" ]; then
		log "...read_buildup_file_if_exists_and_parse_m_m_m file exists"
		build_up=$(read_line_of_file "${buildup_file}")
	fi
	parse_master_major_minor_buildup "${build_up}"
}

read_version_file_if_exists_and_parse_m_m_m_c() {
	log "read_version_file_if_exists_and_parse_m_m_m_c..."
	# if version file exists, this is not the initial commit.
	if [ -f "${version_file}" ]; then
		log "...read_version_file_if_exists_and_parse_m_m_m_c read file."
		version=$(read_version_file)
		parse_master_major_minor_count "${version}"
	fi
}

set_current_commit_count() {
	log "set_current_commit_count."
	commit_count=$(\git rev-list --count HEAD 2>/dev/null)
	if [ $? -ne 0 ]; then
		commit_count=0
	fi
	log "Commit count: ${commit_count}"
}

initialize() {
	log "initialize."
	branch_name=$(get_branch_name)
	set_current_commit_count
	state_init=1
	state_build_up=2
	state_common=0
	read_buildup_file_if_exists_and_parse_m_m_m
	read_version_file_if_exists_and_parse_m_m_m_c
}

delete_buildup_file() {
	log "delete_buildup_file."
	delete_file "${buildup_file}"
}

delete_version_file() {
	log "delete_version_file."
	delete_file "${version_file}"
}

get_current_version_state_and_parse_and_delete_buildup_file() {
	# if version file data exists, this means the branches are currently in construction:
	# Thus, major should not be incremented, minor should not be incremented.
	log "get_current_version_state_and_parse_and_delete_buildup_file..."
	if [ -f "${buildup_file}" ]; then
		log "...get_current_version_state_.. buildup file EXISTS"
		if [ -f "${version_file}" ]; then
			log "...get_current_version_state_.. version file EXISTS"
			# if m1 m1 m1, common phase + delete file.
			# else build up phase.
			if [ "${master_commit}" -eq "1" -a "${major_commit}" -eq "1" -a "${minor_commit}" -eq "1" ]; then
				delete_buildup_file
				return $state_common
			fi
		fi
		return $state_build_up
	else
		log "...get_current_version_state_.. buildup file NOT THERE"
		if [ -f "${version_file}" ]; then
			log "...get_current_version_state_.. version file EXISTS"
			# a but not b: common state, else: initial commit.
			return $state_common
		else
			log "...get_current_version_state_.. version file NOT THERE"
			return $state_init
		fi
	fi
}


master_increment() {
	new_master="$((master+1))"
	log "Incrementing master_version from ${master} to ${new_master}."
	log "Reset major and minor to 0."
	new_major=0
	new_minor=0
}

major_increment() {
	new_major="$((major+1))"
	log "Incrementing major_version from ${major} to ${new_major}."
	log "Reset minor to 0."
	new_minor=0
}

master_major_increment() {
	if [ "$branch_name" = "$master_version_branch_name" ]; then
		master_increment
	elif [ "$branch_name" = "$major_version_branch_name" ]; then
		major_increment
	fi
}

resolve_increment() {
	if [ -e ".git/--increment" ]; then
		versioning_arg="--increment"
	elif [ -e ".git/--hotfix" ]; then
		versioning_arg="--hotfix"
	else
		versioning_arg=""
	fi
	log "resolve_increment: Git_operation=\"$git_operation\", versioning_arg=\"$versioning_arg\", default_behaviour_on_commit=\"$default_behaviour_on_commit\", default_behaviour_on_merge=\"$default_behaviour_on_merge\""
	if [ "$git_operation" == "commit" ]; then
		if [ "$versioning_arg" == "--hotfix" ] || [ "$versioning_arg" == "" -a $default_behaviour_on_commit -eq 0 ]; then
			new_minor="$((minor+1))"
		elif [ "$versioning_arg" == "--increment" -o $default_behaviour_on_commit -eq 1 ]; then
			master_major_increment
		fi
	elif [ "$git_operation" == "merge" ]; then
		if [ "$versioning_arg" == "--hotfix" ] || [ "$versioning_arg" == "" -a $default_behaviour_on_merge -eq 0 ]; then
			new_minor="$((minor+1))"
		elif [ "$versioning_arg" == "--increment" -o $default_behaviour_on_merge -eq 1 ]; then
			master_major_increment
		fi
	fi
}

resolve_minor_increment() {
	log "...increment_version minor-branch"
	new_minor="$((minor+1))"
	log "Incrementing minor_version from ${minor} to ${new_minor}"
}

resolve_increment_master_major_minor() {
	if [ "$branch_name" = "$minor_version_branch_name" ]; then
		resolve_minor_increment
	elif [ "$branch_name" = "$master_version_branch_name" -o "$branch_name" = "$major_version_branch_name" ]; then
		resolve_increment
	fi
}

increment_version() {
	log "increment_version..."
	# if version file data not exists, this means, the branches are already committed:
	# Thus, minor or major need to be incremented, depending on current active branch.
	new_master="$((master))"
	new_major="$((major))"
	new_minor="$((minor))"
	new_commit_count="$((commit_count+1))"

	resolve_increment_master_major_minor

	new_version="${new_master}.${new_major}.${new_minor}.${new_commit_count}"
	log "New version will be ${new_version}"
}

write_version_and_stage() {
	log "write_version. ($1)"
	log "Current path: $PWD"
	write_version_to_file "$1"
	log "version-file = $version_file"
	log "version should be $1"
	\git add "${version_file}" 2>/dev/null
	log "Staged version return code: $?"
}

write_buildup() {
	log "write_buildup. ($1)"
	touch "${buildup_file}"
	echo "$1" > "${buildup_file}"
}

increment_and_set_version() {
	log "increment_and_set_version"
	increment_version
	write_version_and_stage "${new_version}"
}

update_buildup_and_set_version() {
	log "update_buildup_and_set_version..."
	new_commit_count="$((commit_count+1))"
	if [ "${branch_name}" == "${master_version_branch_name}" ]; then
		if [ "${master_commit}" == "0" ]; then
			log "...update_buildup_and_set_version master commit was 0, set to 1..."
			write_buildup "mas1maj0min0"
			write_version_and_stage "0.0.0.${new_commit_count}"
		else
			echo "Not yet finished git branch-setup: You need exactly one commit in master, one in major and one in minor to be able to commit in master again, using this versioning script!"
			echo "ABORTING commit!"
			exit_1
		fi
	elif [ "${branch_name}" == "${major_version_branch_name}" ]; then
		log "...update_buildup_and_set_version major..."
		if [ "${major_commit}" == "0" ]; then
			log "...update_buildup_and_set_version major commit was 0, set to 1..."
			write_buildup "mas1maj1min0"
			write_version_and_stage "0.0.0.${new_commit_count}"
		else
			# commit should fail: commit to master not allowed in this state.
			echo "Not yet finished git branch-setup: You need exactly one commit in master, one in major and one in minor to be able to commit in master again, using this versioning script!"
			echo "ABORTING commit!"
			exit_1
		fi
	elif [ "${branch_name}" = "${minor_version_branch_name}" ]; then
		log "...update_buildup_and_set_version minor"
		# master+major must be 1 already, any other is not possible. thus, build-up will be finished here:
		write_buildup "mas1maj1min1"
		write_version_and_stage "0.0.0.${new_commit_count}"
	fi
}

update_version() {
	log "update_version... state=$1"
	if [ "$(($1))" -eq "$((state_common))" ]; then
		log "...update_version common"
		increment_and_set_version
	else
		log "...update_version build-up"
		update_buildup_and_set_version
	fi
}

try_init_buildup() {
	log "try_init_buildup..."
	if [ "$(($1))" -eq "$((state_init))" ]; then
		log "...try_init_buildup"
		write_buildup "mas0maj0min0"
	fi
}

checkout_version() {
	log "checkout_version."
	\git reset "${version_file}" >/dev/null 2>&1
	\git checkout "${version_file}" 2>/dev/null
	checkout_result=$?
	log "Checkout return code was: ${checkout_result}"
	if [ $checkout_result -ne 0 ]; then
		log "deleting version file due to restore backup"
		# if version could not be checked out: initial commit, thus delete the file as this
		# is expected.
		delete_version_file
	fi
}

restore_backup() {
	log "restore_backup."
	delete_buildup_file
	rename_file "${backup_file}" "${buildup_file}"
	is_file_empty "${buildup_file}"
	f_empty=$?
	log "File is empty: ${f_empty}"
	if [ $f_empty -eq 1 ]; then
		delete_buildup_file
	fi
}

verify_last_commit_was_successful() {
	log "verify_last_commit_was_successful."
	if [ -f "${backup_file}" ]; then
		log " - false"
		checkout_version
		restore_backup
	else
		log " - true"
	fi
}

backup_current_version_tmp() {
	log "backup_current_version_tmp."
	copy_file "${buildup_file}" "${backup_file}"
	if [ $? -ne 0 ]; then
		log "create empty backup file due to first commit."
		echo "" > "${backup_file}"
	fi
	# version does not need to be backupped, as that file simply can be checked out.
}


# ---------------- START ---------------- #

git_operation="$1"
log "git_operation in pre-commit.sh = \"$git_operation\""
if [ "$git_operation" != "merge" ]; then
	git_operation="commit"
fi

log "PRE-COMMIT HOOK on ${branch_name}: Update version-file."

# if backup exists, we should simply checkout the version file from git and
# restore version_tmp from backup file
verify_last_commit_was_successful

# backup this state to be able to load afterwards
backup_current_version_tmp

# initialize
initialize

# get current project state: initial commit? or committing first master and develop?
# or normal commit, master and develop already exist? This is necessary to keep
# version number 0.0.x for first commits on master and develop.
get_current_version_state_and_parse_and_delete_buildup_file
state=$?

log "Old version: ${version}"
log "State: ${state}"
log "Master commit done: ${master_commit}"
log "Develop commit done: ${minor_commit}"

# state = common:
# simply increment the current branch and set counter.
# state = buildup:
# do not increment current branch, but set counter. and update buildup file.
# state = initial:
# make buildup file with m0d0. this will be set to m1d0 in this run
# version result will be 0.0.1;

# initial commit: write buildup file m0d0
try_init_buildup "${state}"

# update version depending on common commit or buildup commit.
update_version "${state}"

wrote_version=$(read_version_file)
log "Wrote new version to file: ${wrote_version}"

exit 0
