#!/bin/bash
#

log_active=0
ok="OK"
failed="FAILED"
print_passed_tests=1
version_file="version"

log() {
	if [ "$((log_active))" -eq 1 ]; then
		echo "$1"
	fi
}

git() {
	".git/hooks/pre-git" "$@"
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
	rm -r -f "$1" 2>/dev/null
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

prompt_user_for_confirm_cancel() {
	# Allows us to read user input below, assigns stdin to keyboard
	exec < /dev/tty
	
	while true; do
		read -p "$1 Confirm (y/N): " yn
		if [ "$yn" = "" ]; then
			yn='N'
		fi
		case $yn in
			[Yy] )
				exec <&-
				return 0
				;;
			[Nn] )
				exec <&-
				exit 1
				;;
			* ) echo "Please answer y or n for yes or no.";;
		esac
	done
}



# --- Asserts echo "OK" if assert is true, "FAILED" if assert is false --- #


assert_equal_number() {
	if [ $1 -eq $2 ]; then
		echo $ok
	else
		echo $failed
	fi
}

assert_not_equal_number() {
	if [ $1 -eq $2 ]; then
		echo $failed
	else
		echo $ok
	fi
}

assert_zero() {
	echo $(assert_equal_number $1 0)
}

assert_one() {
	echo $(assert_equal_number $1 1)
}

assert_not_zero() {
	echo $(assert_not_equal_number $1 0)
}

assert_equal_string() {
	if [ "$1" == "$2" ]; then
		echo $ok
	else
		echo $failed
	fi
}

assert_not_equal_string() {
	if [ "$1" == "$2" ]; then
		echo $failed
	else
		echo $ok
	fi
}

mark_global_start_time() {
	global_start_time=$(date +%s)
}

get_global_time_diff() {
	global_end_time=$(date +%s)
	echo $(( $global_end_time - $global_start_time ))
}

mark_start_time() {
	start_time=$(date +%s)
}

get_time_diff() {
	end_time=$(date +%s)
	echo $(( $end_time - $start_time ))
}

# $1 is test name, $2 is the result
print_test_result() {
	if [ "$2" == "$ok" ]; then
		if [ $print_passed_tests -eq 1 ]; then
			echo "$1 ($(get_time_diff)s): $2"
		fi
	else
		echo "$1: $2"
	fi
}

# Strict asserts take 2 or 3 arguments, the last is the test-name. These asserts print the error message on failure, then they will exit 1. On OK they will echo "OK".

strict_assert_not_zero() {
	result=$(assert_not_zero $1)
	if [ "$result" == "$failed" ]; then
		print_test_result "$2" $result
		exit 1
	fi
	echo $result
}

strict_assert_zero() {
	result=$(assert_zero $1)
	if [ "$result" == "$failed" ]; then
		print_test_result "$2" $result
		exit 1
	fi
	echo $result
}

strict_assert_equal_number() {
	result=$(assert_equal_number $1 $2)
	if [ "$result" == "$failed" ]; then
		print_test_result "$3" $result
		exit 1
	fi
	echo $result
}

strict_assert_not_equal_number() {
	result=$(assert_not_equal_number $1 $2)
	if [ "$result" == "$failed" ]; then
		print_test_result "$3" $result
		exit 1
	fi
	echo $result
}

strict_assert_one() {
	result=$(assert_one $1)
	if [ "$result" == "$failed" ]; then
		print_test_result "$2" $result
		exit 1
	fi
	echo $result
}

strict_assert_equal_string() {
	result=$(assert_equal_string "$1" "$2")
	if [ "$result" == "$failed" ]; then
		print_test_result "$3" $result
		exit 1
	fi
	echo $result
}

strict_assert_not_equal_string() {
	result=$(assert_not_equal_string "$1" "$2")
	if [ "$result" == "$failed" ]; then
		print_test_result "$3" $result
		exit 1
	fi
	echo $result
}


test_strict_assert_zero() {
	result=$(strict_assert_zero 0 "test_strict_assert")
	print_test_result "test_strict_assert" $result 
	strict_assert_zero 2 "test_strict_assert"
}

test_strict_assert_not_zero() {
	result=$(strict_assert_not_zero 2 "test_strict_assert")
	print_test_result "test_strict_assert" $result 
	strict_assert_not_zero 0 "test_strict_assert"
}

test_strict_assert_equal_number() {
	result=$(strict_assert_equal_number 2 2)
	print_test_result "test_strict_assert" $result 
	strict_assert_equal_number 0 1 "test_strict_assert"
}

test_strict_assert_not_equal_number() {
	result=$(strict_assert_not_equal_number 1 2)
	print_test_result "test_strict_assert" $result 
	strict_assert_not_equal_number 1 1 "test_strict_assert"
}

test_strict_assert_one() {
	result=$(strict_assert_one 1 "test_strict_assert")
	print_test_result "test_strict_assert" $result 
	strict_assert_one 0 "test_strict_assert"
}

test_strict_assert_equal_string() {
	result=$(strict_assert_equal_string "0.0.2.3" "0.0.2.3")
	print_test_result "test_strict_assert" $result 
	strict_assert_equal_string "0.0.2.3" "0.0.2.4" "test_strict_assert"
}

test_strict_assert_not_equal_string() {
	result=$(strict_assert_not_equal_string "0.0.2.3" "0.0.2.4")
	print_test_result "test_strict_assert" $result 
	strict_assert_not_equal_string "0.0.2.3" "0.0.2.3" "test_strict_assert"
}

set_test_name() {
	test_name="$1"
	log "$test_name"
}


# $1 = master_version_branch_name
# $2 = major_version_branch_name
# $3 = minor_version_branch_name
# $4 = default_behaviour_on_commit
# $5 = default_behaviour_on_merge
# $6 = commit_and_merge_only_if_increment_or_hotfix_argument_given
set_flags() {
	sed -i "s~.*master_version_branch_name=.*~master_version_branch_name=\"$1\"~g" .git/hooks/versioning_tool_config
	sed -i "s~.*major_version_branch_name=.*~major_version_branch_name=\"$2\"~g" .git/hooks/versioning_tool_config
	sed -i "s~.*minor_version_branch_name=.*~minor_version_branch_name=\"$3\"~g" .git/hooks/versioning_tool_config
	sed -i "s~.*default_behaviour_on_commit=.*~default_behaviour_on_commit=$4~g" .git/hooks/versioning_tool_config
	sed -i "s~.*default_behaviour_on_merge=.*~default_behaviour_on_merge=$5~g" .git/hooks/versioning_tool_config
	sed -i "s~.*commit_and_merge_only_if_increment_or_hotfix_argument_given=.*~commit_and_merge_only_if_increment_or_hotfix_argument_given=$6~g" .git/hooks/versioning_tool_config
}

# $1 = default_behaviour_on_commit
# $2 = default_behaviour_on_merge
# $3 = commit_and_merge_only_if_increment_or_hotfix_argument_given
set_default_branches_and() {
	set_flags "master" "major" "minor" "$1" "$2" "$3"
}

set_mmm_commit_0_merge_0_arg_0() {
	set_default_branches_and 0 0 0
}

set_mmm_commit_0_merge_0_arg_1() {
	set_default_branches_and 0 0 1
}

set_mmm_commit_0_merge_1_arg_0() {
	set_default_branches_and 0 1 0
}

set_mmm_commit_0_merge_1_arg_1() {
	set_default_branches_and 0 1 1
}

set_mmm_commit_1_merge_0_arg_0() {
	set_default_branches_and 1 0 0
}

set_mmm_commit_1_merge_0_arg_1() {
	set_default_branches_and 1 0 1
}

set_mmm_commit_1_merge_1_arg_0() {
	set_default_branches_and 1 1 0
}

set_mmm_commit_1_merge_1_arg_1() {
	set_default_branches_and 1 1 1
}


set_mmm_commit_and_merge_0_arg_0() {
	set_mmm_commit_0_merge_0_arg_0
}

set_mmm_commit_and_merge_0_arg_1() {
	set_mmm_commit_0_merge_0_arg_1
}

set_mmm_commit_and_merge_1_arg_0() {
	set_mmm_commit_1_merge_1_arg_0
}

set_mmm_commit_and_merge_1_arg_1() {
	set_mmm_commit_1_merge_1_arg_1
}


set_default_flags() {
	set_mmm_commit_0_merge_1_arg_1
}
