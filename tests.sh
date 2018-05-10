#!/bin/bash
#

source "./test-util.sh" >/dev/null 2>&1

# $1 is the test-nr as string
prepare_test() {
	mark_start_time
	set_test_name "$1"
	./versioning_install.sh 3 # delete old repo, install scripts but not branch setup.
	set_default_flags
	source ".git/hooks/versioning_tool_config" >/dev/null 2>&1
}

cleanup() {
	rm -r -f ".git" >/dev/null 2>&1
	rm -f "version" >/dev/null 2>&1
}

finish_test() {
	cleanup
}


test_001__test_flags_set_properly() {
	prepare_test "test_001"
	result=$(strict_assert_equal_string "$master_version_branch_name" "master")
	result=$(strict_assert_equal_string "$major_version_branch_name" "major")
	result=$(strict_assert_equal_string "$minor_version_branch_name" "minor")
	result=$(strict_assert_zero $default_behaviour_on_commit)
	result=$(strict_assert_not_zero $default_behaviour_on_merge)
	result=$(strict_assert_not_zero $commit_and_merge_only_if_increment_or_hotfix_argument_given)
	print_test_result "$test_name" "$result"
	finish_test
}

test_002__should_pass_on_initial_commit_without_staged_files_with_commit_message() {
	prepare_test "test_002"
	git commit -m 'Should pass' --no-increment >/dev/null 2>&1
	return_code=$?
	result=$(assert_zero $return_code)
	print_test_result "$test_name" "$result"
	finish_test
}

test_003__should_pass_on_initial_commit_with_staged_file_with_commit_message() {
	prepare_test "test_003"
	git add "versioning_hooks/post-commit" >/dev/null 2>&1
	git commit -m 'Should pass' --no-increment >/dev/null 2>&1
	return_code=$?
	result=$(assert_zero $return_code)
	print_test_result "$test_name" "$result"
	finish_test
}

# Master, major, minor, commit count.
test_004__pass_version_0_0_0_1_after_initial_commit_on_master() {
	prepare_test "test_004"
	git commit -m 'Should pass' --no-increment >/dev/null 2>&1
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.1")
	print_test_result "$test_name" "$result"
	finish_test
}

test_005__fail_second_commit_on_master_after_initial_commit_on_master() {
	prepare_test "test_005"
	git commit -m 'Should pass' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Should fail' --increment >/dev/null 2>&1
	result=$(assert_not_zero $?)
	print_test_result "$test_name" "$result"
	finish_test
}

test_006__pass_version_0_0_0_2_after_first_commit_on_major() {
	prepare_test "test_006"
	git commit -m 'Initial Commit' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$major_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Major Branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.2")
	print_test_result "$test_name" "$result"
	finish_test
}

test_007__fail_second_commit_on_major_after_first_commit_on_major() {
	prepare_test "test_007"
	git commit -m 'Should pass' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$major_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Should pass' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Should fail' --increment >/dev/null 2>&1
	result=$(assert_not_zero $?)
	print_test_result "$test_name" "$result"
	finish_test
}

test_008__pass_version_0_0_0_3_after_first_commit_on_minor() {
	prepare_test "test_008"
	git commit -m 'Initial Commit' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$major_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Major Branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$minor_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Minor Branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.3")
	print_test_result "$test_name" "$result"
	finish_test
}

test_009__pass_version_0_0_1_4_after_second_commit_on_minor() {
	prepare_test "test_009"
	git commit -m 'Initial Commit' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$major_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Major Branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$minor_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Minor Branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Second commit on Minor Branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.4")
	print_test_result "$test_name" "$result"
	finish_test
}

init_git_repo() {
	git commit -m 'Initial Commit' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$major_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Major Branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$minor_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Minor Branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.0.3")
}

test_010__pass_version_0_0_1_5_after_merge_from_develop_to_minor() {
	prepare_test "test_010"
	init_git_repo

	git checkout -b develop >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Develop Branch' >/dev/null 2>&1
	git checkout "$minor_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge develop -m 'Merge feature from develop to minor release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.1.5")

	print_test_result "$test_name" "$result"
	finish_test
}

common_buildup() {
	git checkout -b develop >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Develop Branch' >/dev/null 2>&1
	git checkout "$minor_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge develop -m 'Merge feature from develop to minor release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout "$major_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
}

# default_behaviour_on_(commit|merge) | commit_and_merge_only_if_increment_or_hotfix_argument_given | nothing (00) / increment (01) / hotfix (10) / no-increment (11)
#                  0                  |                               0                             |                    0     0
#                  0                  |                               0                             |                    0     1
#                  0                  |                               0                             |                    1     0
#                  0                  |                               0                             |                    1     1
#                  0                  |                               1                             |                    0     0
#                  0                  |                               1                             |                    0     1
#                  0                  |                               1                             |                    1     0
#                  0                  |                               1                             |                    1     1
#                  1                  |                               0                             |                    0     0
#                  1                  |                               0                             |                    0     1
#                  1                  |                               0                             |                    1     0
#                  1                  |                               0                             |                    1     1
#                  1                  |                               1                             |                    0     0
#                  1                  |                               1                             |                    0     1
#                  1                  |                               1                             |                    1     0
#                  1                  |                               1                             |                    1     1



# ++++++++++++++++++++++++++++++++++++++++++++++++ Minor to major ++++++++++++++++++++++++++++++++++++++++++++++++++++

# default_behaviour_on_commit and default_behaviour_on_merge both 0, means minor will be incremented if no arg given.
# commit_and_merge_only_if_increment_or_hotfix_argument_given = 0, means default values will actually be used.
common_minor_to_major_0_0() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_0
	common_buildup
}

test_011__merge_minor_to_major__settings_0_0_00() {
	prepare_test "test_011"
	common_minor_to_major_0_0

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.2.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_012__merge_minor_to_major__settings_0_0_01() {
	prepare_test "test_012"
	common_minor_to_major_0_0

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_013__merge_minor_to_major__settings_0_0_10() {
	prepare_test "test_013"
	common_minor_to_major_0_0

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.2.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_014__merge_minor_to_major__settings_0_0_11() {
	prepare_test "test_014"
	common_minor_to_major_0_0

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.6")

	print_test_result "$test_name" "$result"
	finish_test
}

# default_behaviour_on_commit and default_behaviour_on_merge both 0, means minor will be incremented if no arg given.
# commit_and_merge_only_if_increment_or_hotfix_argument_given = 1, means default values will be ignored and user will be prompted.
common_minor_to_major_0_1() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_1
	common_buildup
}

test_015__merge_minor_to_major__settings_0_1_00() {
	prepare_test "test_015"
	common_minor_to_major_0_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_016__merge_minor_to_major__settings_0_1_01() {
	prepare_test "test_016"
	common_minor_to_major_0_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_017__merge_minor_to_major__settings_0_1_10() {
	prepare_test "test_017"
	common_minor_to_major_0_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.2.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_018__merge_minor_to_major__settings_0_1_11() {
	prepare_test "test_018"
	common_minor_to_major_0_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.6")

	print_test_result "$test_name" "$result"
	finish_test
}

# default_behaviour_on_commit and default_behaviour_on_merge both 1, means major will be incremented if no arg given.
# commit_and_merge_only_if_increment_or_hotfix_argument_given = 0, means default values will actually be used.
common_minor_to_major_1_0() {
	init_git_repo
	set_mmm_commit_and_merge_1_arg_0
	common_buildup
}

test_019__merge_minor_to_major__settings_1_0_00() {
	prepare_test "test_019"
	common_minor_to_major_1_0

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_020__merge_minor_to_major__settings_1_0_01() {
	prepare_test "test_020"
	common_minor_to_major_1_0

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_021__merge_minor_to_major__settings_1_0_10() {
	prepare_test "test_021"
	common_minor_to_major_1_0

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.2.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_022__merge_minor_to_major__settings_1_0_11() {
	prepare_test "test_022"
	common_minor_to_major_1_0

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.6")

	print_test_result "$test_name" "$result"
	finish_test
}

# default_behaviour_on_commit and default_behaviour_on_merge both 1, means major will be incremented if no arg given.
# commit_and_merge_only_if_increment_or_hotfix_argument_given = 1, means default values will be ignored and user will be prompted.
common_minor_to_major_1_1() {
	init_git_repo
	set_mmm_commit_and_merge_1_arg_1
	common_buildup
}

test_023__merge_minor_to_major__settings_1_1_00() {
	prepare_test "test_023"
	common_minor_to_major_1_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_024__merge_minor_to_major__settings_1_1_01() {
	prepare_test "test_024"
	common_minor_to_major_1_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_025__merge_minor_to_major__settings_1_1_10() {
	prepare_test "test_025"
	common_minor_to_major_1_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.2.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_026__merge_minor_to_major__settings_1_1_11() {
	prepare_test "test_026"
	common_minor_to_major_1_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.6")

	print_test_result "$test_name" "$result"
	finish_test
}

# ++++++++++++++++++++++++++++++++++++++++++++++++ Major to master ++++++++++++++++++++++++++++++++++++++++++++++++++++

common_major_to_master_0_0() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_0
	common_buildup
	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
}

test_027__merge_major_to_master__settings_0_0_00() {
	prepare_test "test_027"
	common_major_to_master_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.1.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_028__merge_major_to_master__settings_0_0_01() {
	prepare_test "test_028"
	common_major_to_master_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_029__merge_major_to_master__settings_0_0_10() {
	prepare_test "test_029"
	common_major_to_master_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.1.1.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_030__merge_major_to_master__settings_0_0_11() {
	prepare_test "test_030"
	common_major_to_master_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.1.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}


common_major_to_master_0_1() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_1
	common_buildup
	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
}

test_031__merge_major_to_master__settings_0_1_00() {
	prepare_test "test_031"
	common_major_to_master_0_1

	git merge "$minor_version_branch_name" -m 'Merge feature from major to master release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_032__merge_major_to_master__settings_0_1_01() {
	prepare_test "test_032"
	common_major_to_master_0_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_033__merge_major_to_master__settings_0_1_10() {
	prepare_test "test_033"
	common_major_to_master_0_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.1.1.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_034__merge_major_to_master__settings_0_1_11() {
	prepare_test "test_034"
	common_major_to_master_0_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.1.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}

common_major_to_master_1_0() {
	init_git_repo
	set_mmm_commit_and_merge_1_arg_0
	common_buildup
	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
}

test_035__merge_major_to_master__settings_1_0_00() {
	prepare_test "test_035"
	common_major_to_master_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_036__merge_major_to_master__settings_1_0_01() {
	prepare_test "test_036"
	common_major_to_master_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_037__merge_major_to_master__settings_1_0_10() {
	prepare_test "test_037"
	common_major_to_master_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.1.1.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_038__merge_major_to_master__settings_1_0_11() {
	prepare_test "test_038"
	common_major_to_master_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.1.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}


common_major_to_master_1_1() {
	init_git_repo
	set_mmm_commit_and_merge_1_arg_1
	common_buildup
	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
}

test_039__merge_major_to_master__settings_1_1_00() {
	prepare_test "test_039"
	common_major_to_master_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_040__merge_major_to_master__settings_1_1_01() {
	prepare_test "test_040"
	common_major_to_master_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_041__merge_major_to_master__settings_1_1_10() {
	prepare_test "test_041"
	common_major_to_master_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.1.1.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_042__merge_major_to_master__settings_1_1_11() {
	prepare_test "test_042"
	common_major_to_master_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.1.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}


# ++++++++++++++++++++++++++++++++++++++++++++++++ Commit on Major ++++++++++++++++++++++++++++++++++++++++++++++++++++

# default_behaviour_on_commit and default_behaviour_on_merge both 0, means minor will be incremented if no arg given.
# commit_and_merge_only_if_increment_or_hotfix_argument_given = 0, means default values will actually be used.
common_major_commit_0_0() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_0
	common_buildup
}

test_043__commit_on_major__settings_0_0_00() {
	prepare_test "test_043"
	common_major_commit_0_0

	git commit -m 'Commit feature on major release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_044__commit_on_major__settings_0_0_01() {
	prepare_test "test_044"
	common_major_commit_0_0

	git commit -m 'Commit feature on major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_045__commit_on_major__settings_0_0_10() {
	prepare_test "test_045"
	common_major_commit_0_0

	git commit -m 'Commit feature on major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_046__commit_on_major__settings_0_0_11() {
	prepare_test "test_046"
	common_major_commit_0_0

	git commit -m 'Commit feature on major release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

# default_behaviour_on_commit and default_behaviour_on_merge both 0, means minor will be incremented if no arg given.
# commit_and_merge_only_if_increment_or_hotfix_argument_given = 1, means default values will be ignored and user will be prompted.
common_major_commit_0_1() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_1
	common_buildup
}

test_047__commit_on_major__settings_0_1_00() {
	prepare_test "test_047"
	common_major_commit_0_1

	git commit -m 'Commit feature on major release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_048__commit_on_major__settings_0_1_01() {
	prepare_test "test_048"
	common_major_commit_0_1

	git commit -m 'Commit feature on major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_049__commit_on_major__settings_0_1_10() {
	prepare_test "test_049"
	common_major_commit_0_1

	git commit -m 'Commit feature on major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_050__commit_on_major__settings_0_1_11() {
	prepare_test "test_050"
	common_major_commit_0_1

	git commit -m 'Commit feature on major release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}


# default_behaviour_on_commit and default_behaviour_on_merge both 1, means major will be incremented if no arg given.
# commit_and_merge_only_if_increment_or_hotfix_argument_given = 0, means default values will actually be used.
common_major_commit_1_0() {
	init_git_repo
	set_mmm_commit_and_merge_1_arg_0
	common_buildup
}

test_051__commit_on_major__settings_1_0_00() {
	prepare_test "test_051"
	common_major_commit_1_0

	git commit -m 'Commit feature on major release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_052__commit_on_major__settings_1_0_01() {
	prepare_test "test_052"
	common_major_commit_1_0

	git commit -m 'Commit feature on major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_053__commit_on_major__settings_1_0_10() {
	prepare_test "test_053"
	common_major_commit_1_0

	git commit -m 'Commit feature on major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_054__commit_on_major__settings_1_0_11() {
	prepare_test "test_054"
	common_major_commit_1_0

	git commit -m 'Commit feature on major release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

# default_behaviour_on_commit and default_behaviour_on_merge both 1, means major will be incremented if no arg given.
# commit_and_merge_only_if_increment_or_hotfix_argument_given = 1, means default values will be ignored and user will be prompted.
common_major_commit_1_1() {
	init_git_repo
	set_mmm_commit_and_merge_1_arg_1
	common_buildup
}

test_055__commit_on_major__settings_1_1_00() {
	prepare_test "test_055"
	common_major_commit_1_1

	git commit -m 'Commit feature on major release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_056__commit_on_major__settings_1_1_01() {
	prepare_test "test_056"
	common_major_commit_1_1

	git commit -m 'Commit feature on major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_057__commit_on_major__settings_1_1_10() {
	prepare_test "test_057"
	common_major_commit_1_1

	git commit -m 'Commit feature on major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_058__commit_on_major__settings_1_1_11() {
	prepare_test "test_058"
	common_major_commit_1_1

	git commit -m 'Commit feature on major release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}


# ++++++++++++++++++++++++++++++++++++++++++++++++ Commit on Master ++++++++++++++++++++++++++++++++++++++++++++++++++++

common_master_commit_0_0() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_0
	common_buildup
	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
}

test_059__commit_on_master__settings_0_0_00() {
	prepare_test "test_059"
	common_master_commit_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_060__commit_on_master__settings_0_0_01() {
	prepare_test "test_060"
	common_master_commit_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_061__commit_on_master__settings_0_0_10() {
	prepare_test "test_061"
	common_master_commit_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.1.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_062__commit_on_master__settings_0_0_11() {
	prepare_test "test_062"
	common_master_commit_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}


common_master_commit_0_1() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_1
	common_buildup
	git commit -m 'Commit feature on master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
}

test_063__commit_on_master__settings_0_1_00() {
	prepare_test "test_063"
	common_master_commit_0_1

	git commit -m 'Commit feature on master release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_064__commit_on_master__settings_0_1_01() {
	prepare_test "test_064"
	common_master_commit_0_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_065__commit_on_master__settings_0_1_10() {
	prepare_test "test_065"
	common_master_commit_0_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.1.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_066__commit_on_master__settings_0_1_11() {
	prepare_test "test_066"
	common_master_commit_0_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}


common_master_commit_1_0() {
	init_git_repo
	set_mmm_commit_and_merge_1_arg_0
	common_buildup
	git commit -m 'Commit feature on master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
}

test_067__commit_on_master__settings_1_0_00() {
	prepare_test "test_067"
	common_master_commit_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_068__commit_on_master__settings_1_0_01() {
	prepare_test "test_068"
	common_master_commit_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_069__commit_on_master__settings_1_0_10() {
	prepare_test "test_069"
	common_master_commit_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.1.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_070__commit_on_master__settings_1_0_11() {
	prepare_test "test_070"
	common_master_commit_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}


common_master_commit_1_1() {
	init_git_repo
	set_mmm_commit_and_merge_1_arg_1
	common_buildup
	git commit -m 'Commit feature on master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
}

test_071__commit_on_master__settings_1_1_00() {
	prepare_test "test_071"
	common_master_commit_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_072__commit_on_master__settings_1_1_01() {
	prepare_test "test_072"
	common_master_commit_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_073__commit_on_master__settings_1_1_10() {
	prepare_test "test_073"
	common_master_commit_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.1.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_074__commit_on_master__settings_1_1_11() {
	prepare_test "test_074"
	common_master_commit_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}


## Commit on minor and merge to minor. Tests for --increment and --no-increment on minor ##


common_buildup_minor() {
	git checkout -b develop >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Develop Branch' >/dev/null 2>&1
	git checkout "$minor_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
}

common_to_minor_0_0() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_0
	common_buildup_minor
}

test_075__merge_to_minor__settings_0_0_00() {
	prepare_test "test_075"
	common_to_minor_0_0

	git merge develop -m 'Merge feature from develop to minor release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.5")

	print_test_result "$test_name" "$result"
	finish_test
}

test_076__merge_to_minor__settings_0_0_01() {
	prepare_test "test_076"
	common_to_minor_0_0

	git merge develop -m 'Merge feature from develop to minor release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.5")

	print_test_result "$test_name" "$result"
	finish_test
}

test_077__merge_to_minor__settings_0_0_11() {
	prepare_test "test_077"
	common_to_minor_0_0

	git merge develop -m 'Merge feature from develop to minor release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.5")

	print_test_result "$test_name" "$result"
	finish_test
}

common_to_minor_0_1() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_1
	common_buildup_minor
}

test_078__merge_to_minor__settings_0_1_00() {
	prepare_test "test_078"
	common_to_minor_0_1

	git merge develop -m 'Merge feature from develop to minor release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_079__merge_to_minor__settings_0_1_01() {
	prepare_test "test_079"
	common_to_minor_0_1

	git merge develop -m 'Merge feature from develop to minor release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.5")

	print_test_result "$test_name" "$result"
	finish_test
}

test_080__merge_to_minor__settings_0_1_11() {
	prepare_test "test_080"
	common_to_minor_0_1

	git merge develop -m 'Merge feature from develop to minor release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.5")

	print_test_result "$test_name" "$result"
	finish_test
}

# Commit on minor

common_minor_commit_0_0() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_0
	common_buildup_minor
}

test_081__commit_on_minor__settings_0_0_00() {
	prepare_test "test_081"
	common_minor_commit_0_0

	git commit -m 'Commit feature on minor release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.4")

	print_test_result "$test_name" "$result"
	finish_test
}

test_082__commit_on_minor__settings_0_0_01() {
	prepare_test "test_082"
	common_minor_commit_0_0

	git commit -m 'Commit feature on minor release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.4")

	print_test_result "$test_name" "$result"
	finish_test
}

test_083__commit_on_minor__settings_0_0_11() {
	prepare_test "test_083"
	common_minor_commit_0_0

	git commit -m 'Commit feature on minor release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.4")

	print_test_result "$test_name" "$result"
	finish_test
}

common_minor_commit_0_1() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_1
	common_buildup_minor
}

test_084__commit_on_minor__settings_0_1_00() {
	prepare_test "test_084"
	common_minor_commit_0_1

	git commit -m 'Commit feature on minor release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_085__commit_on_minor__settings_0_1_01() {
	prepare_test "test_085"
	common_minor_commit_0_1

	git commit -m 'Commit feature on minor release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.4")

	print_test_result "$test_name" "$result"
	finish_test
}

test_086__commit_on_minor__settings_0_1_11() {
	prepare_test "test_086"
	common_minor_commit_0_1

	git commit -m 'Commit feature on minor release branch' --no-increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.4")

	print_test_result "$test_name" "$result"
	finish_test
}


##     Install script tests     ##


test_087__run_install_0() {
	mark_start_time
	set_test_name "test_087"
	./versioning_install.sh 0 >/dev/null 2>&1

	# 1. check if install script made alias to git on git-wrapper in bashrc
	result=$(grep 'alias git="~/.git-wrapper"' ~/.bashrc)
	result=$(strict_assert_not_equal_string "$result" "")

	# 2. check if install script made git-wrapper file in home dir.
	result=""
	[[ -f ~/.git-wrapper ]] || result="error"
	result=$(assert_not_equal_string "$result" "error")

	print_test_result "$test_name" "$result"
	finish_test
}

test_088__run_install_1() {
	mark_start_time
	set_test_name "test_088"
	./versioning_install.sh 1 >/dev/null 2>&1

	# 1. check if git repo exists (made by install script)
	result=""
	[[ -f ~/.git-wrapper ]] || result="error"
	result=$(strict_assert_not_equal_string "$result" "error")

	# 2. check if git repo has no commits
	git rev-parse HEAD &>/dev/null
	result=$(assert_not_zero "$?")

	print_test_result "$test_name" "$result"
	finish_test
}

test_089__run_install_2() {
	mark_start_time
	set_test_name "test_089"
	./versioning_install.sh 2 >/dev/null 2>&1

	result=$(assert_equal_string "$(read_version_file)" "0.0.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

initialize_git_repo_with_version_other_than_0_0_0_3() {
	echo "0.0.0.3" > version
	init_git_repo
	git checkout -b develop >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Develop Branch' >/dev/null 2>&1
	git commit -m 'Second commit on Develop Branch' >/dev/null 2>&1
	git commit -m 'Third commit on Develop Branch' >/dev/null 2>&1
	echo "0.0.0.6" > version
}

test_090__run_install_3() {
	mark_start_time
	set_test_name "test_090"
	
	# 1. initialize git repo with version other than 0.0.0.3
	initialize_git_repo_with_version_other_than_0_0_0_3

	# 2. install versioning-tool by deleting old repo and initializing new one without branch-setup.
	./versioning_install.sh 3 >/dev/null 2>&1

	# 3. there should not be a version file but a git repo.
	result=""
	[[ -f .git ]] || result="error"
	result=$(strict_assert_not_equal_string "$result" "error")

	# 4. check if git repo has no commits
	git rev-parse HEAD &>/dev/null
	result=$(assert_not_zero "$?")
	
	
	print_test_result "$test_name" "$result"
	finish_test
}

test_091__run_install_4() {
	mark_start_time
	set_test_name "test_091"
	
	# 1. initialize git repo with version other than 0.0.0.3
	initialize_git_repo_with_version_other_than_0_0_0_3
	
	# 2. install versioning tool + delete old repo + initiate branches.
	./versioning_install.sh 4 >/dev/null 2>&1
	
	# 3. read version file and expect 0.0.0.3
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.3")
	
	print_test_result "$test_name" "$result"
	finish_test
}




run_iniziation_tests() {
	test_001__test_flags_set_properly
	test_002__should_pass_on_initial_commit_without_staged_files_with_commit_message
	test_003__should_pass_on_initial_commit_with_staged_file_with_commit_message
	test_004__pass_version_0_0_0_1_after_initial_commit_on_master
	test_005__fail_second_commit_on_master_after_initial_commit_on_master
	test_006__pass_version_0_0_0_2_after_first_commit_on_major
	test_007__fail_second_commit_on_major_after_first_commit_on_major
	test_008__pass_version_0_0_0_3_after_first_commit_on_minor
	test_009__pass_version_0_0_1_4_after_second_commit_on_minor
	test_010__pass_version_0_0_1_5_after_merge_from_develop_to_minor
}

run_merge_minor_to_major_tests() {
	test_011__merge_minor_to_major__settings_0_0_00
	test_012__merge_minor_to_major__settings_0_0_01
	test_013__merge_minor_to_major__settings_0_0_10
	test_014__merge_minor_to_major__settings_0_0_11
	test_015__merge_minor_to_major__settings_0_1_00
	test_016__merge_minor_to_major__settings_0_1_01
	test_017__merge_minor_to_major__settings_0_1_10
	test_018__merge_minor_to_major__settings_0_1_11
	test_019__merge_minor_to_major__settings_1_0_00
	test_020__merge_minor_to_major__settings_1_0_01
	test_021__merge_minor_to_major__settings_1_0_10
	test_022__merge_minor_to_major__settings_1_0_11
	test_023__merge_minor_to_major__settings_1_1_00
	test_024__merge_minor_to_major__settings_1_1_01
	test_025__merge_minor_to_major__settings_1_1_10
	test_026__merge_minor_to_major__settings_1_1_11
}

run_merge_major_to_master_tests() {
	test_027__merge_major_to_master__settings_0_0_00
	test_028__merge_major_to_master__settings_0_0_01
	test_029__merge_major_to_master__settings_0_0_10
	test_030__merge_major_to_master__settings_0_0_11
	test_031__merge_major_to_master__settings_0_1_00
	test_032__merge_major_to_master__settings_0_1_01
	test_033__merge_major_to_master__settings_0_1_10
	test_034__merge_major_to_master__settings_0_1_11
	test_035__merge_major_to_master__settings_1_0_00
	test_036__merge_major_to_master__settings_1_0_01
	test_037__merge_major_to_master__settings_1_0_10
	test_038__merge_major_to_master__settings_1_0_11
	test_039__merge_major_to_master__settings_1_1_00
	test_040__merge_major_to_master__settings_1_1_01
	test_041__merge_major_to_master__settings_1_1_10
	test_042__merge_major_to_master__settings_1_1_11
}

run_commit_on_major_tests() {
	test_043__commit_on_major__settings_0_0_00
	test_044__commit_on_major__settings_0_0_01
	test_045__commit_on_major__settings_0_0_10
	test_046__commit_on_major__settings_0_0_11
	test_047__commit_on_major__settings_0_1_00
	test_048__commit_on_major__settings_0_1_01
	test_049__commit_on_major__settings_0_1_10
	test_050__commit_on_major__settings_0_1_11
	test_051__commit_on_major__settings_1_0_00
	test_052__commit_on_major__settings_1_0_01
	test_053__commit_on_major__settings_1_0_10
	test_054__commit_on_major__settings_1_0_11
	test_055__commit_on_major__settings_1_1_00
	test_056__commit_on_major__settings_1_1_01
	test_057__commit_on_major__settings_1_1_10
	test_058__commit_on_major__settings_1_1_11
}

run_commit_on_master_tests() {
	test_059__commit_on_master__settings_0_0_00
	test_060__commit_on_master__settings_0_0_01
	test_061__commit_on_master__settings_0_0_10
	test_062__commit_on_master__settings_0_0_11
	test_063__commit_on_master__settings_0_1_00
	test_064__commit_on_master__settings_0_1_01
	test_065__commit_on_master__settings_0_1_10
	test_066__commit_on_master__settings_0_1_11
	test_067__commit_on_master__settings_1_0_00
	test_068__commit_on_master__settings_1_0_01
	test_069__commit_on_master__settings_1_0_10
	test_070__commit_on_master__settings_1_0_11
	test_071__commit_on_master__settings_1_1_00
	test_072__commit_on_master__settings_1_1_01
	test_073__commit_on_master__settings_1_1_10
	test_074__commit_on_master__settings_1_1_11
}

run_merge_to_minor_tests() {
	test_075__merge_to_minor__settings_0_0_00
	test_076__merge_to_minor__settings_0_0_01
	test_077__merge_to_minor__settings_0_0_11
	test_078__merge_to_minor__settings_0_1_00
	test_079__merge_to_minor__settings_0_1_01
	test_080__merge_to_minor__settings_0_1_11
}

run_commit_on_minor_tests() {
	test_081__commit_on_minor__settings_0_0_00
	test_082__commit_on_minor__settings_0_0_01
	test_083__commit_on_minor__settings_0_0_11
	test_084__commit_on_minor__settings_0_1_00
	test_085__commit_on_minor__settings_0_1_01
	test_086__commit_on_minor__settings_0_1_11
}

run_install_tests() {
	test_087__run_install_0
	test_088__run_install_1
	test_089__run_install_2
	test_090__run_install_3
	test_091__run_install_4
}




run_all_tests() {
	mark_global_start_time
	cleanup
	run_iniziation_tests
	run_merge_minor_to_major_tests
	run_merge_major_to_master_tests
	run_commit_on_major_tests
	run_commit_on_master_tests
	run_merge_to_minor_tests
	run_commit_on_minor_tests
	run_install_tests
	echo "Finished all tests in $(get_global_time_diff) seconds."
}



# ------------------------ RUN TESTS ----------------------- #
#test_strict_assert_not_zero
#test_strict_assert_zero
#test_strict_assert_equal_number
#test_strict_assert_not_equal_number
#test_strict_assert_one
#test_strict_assert_equal_string
#test_strict_assert_not_equal_string

echo "Note: Running the tests will install the git-wrapper script into the home directory and will add a line to the ~/.bashrc file! This will not be removed automatically after the tests finished. You can uninstall these things with the uninstall script."
prompt_user_for_confirm_cancel "Attention! If there is a .git folder in this directory, it will be deleted!! Are you sure you want to run the tests within this folder?"
run_all_tests
