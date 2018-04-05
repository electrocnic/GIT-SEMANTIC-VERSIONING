#!/bin/sh
#

source "./test-util.sh" >/dev/null 2>&1

# $1 is the test-nr as string
prepare_test() {
	mark_start_time
	set_test_name "$1"
	./versioning_install.sh "FRESH_INSTALL!" "NO_SETUP"
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
	git commit -m 'Should pass' --increment >/dev/null 2>&1
	return_code=$?
	result=$(assert_zero $return_code)
	print_test_result "$test_name" "$result"
	finish_test
}

test_003__should_pass_on_initial_commit_with_staged_file_with_commit_message() {
	prepare_test "test_003"
	git add "versioning_hooks/post-commit" >/dev/null 2>&1
	git commit -m 'Should pass' --increment >/dev/null 2>&1
	return_code=$?
	result=$(assert_zero $return_code)
	print_test_result "$test_name" "$result"
	finish_test
}

# Master, major, minor, commit count.
test_004__pass_version_0_0_0_1_after_initial_commit_on_master() {
	prepare_test "test_004"
	git commit -m 'Should pass' --increment >/dev/null 2>&1
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.1")
	print_test_result "$test_name" "$result"
	finish_test
}

test_005__fail_second_commit_on_master_after_initial_commit_on_master() {
	prepare_test "test_005"
	git commit -m 'Should pass' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Should fail' --increment >/dev/null 2>&1
	result=$(assert_not_zero $?)
	print_test_result "$test_name" "$result"
	finish_test
}

test_006__pass_version_0_0_0_2_after_first_commit_on_major() {
	prepare_test "test_006"
	git commit -m 'Initial Commit' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$major_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Major Branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.2")
	print_test_result "$test_name" "$result"
	finish_test
}

test_007__fail_second_commit_on_major_after_first_commit_on_major() {
	prepare_test "test_007"
	git commit -m 'Should pass' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$major_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Should pass' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Should fail' --increment >/dev/null 2>&1
	result=$(assert_not_zero $?)
	print_test_result "$test_name" "$result"
	finish_test
}

test_008__pass_version_0_0_0_3_after_first_commit_on_minor() {
	prepare_test "test_008"
	git commit -m 'Initial Commit' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$major_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Major Branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$minor_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Minor Branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.0.3")
	print_test_result "$test_name" "$result"
	finish_test
}

test_009__pass_version_0_0_1_4_after_second_commit_on_minor() {
	prepare_test "test_009"
	git commit -m 'Initial Commit' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$major_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Major Branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$minor_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Minor Branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Second commit on Minor Branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.4")
	print_test_result "$test_name" "$result"
	finish_test
}

init_git_repo() {
	git commit -m 'Initial Commit' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$major_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Major Branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout -b "$minor_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Minor Branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.0.3")
}


#TODO: add following test cases:
# OK: 1. merge feature branch commits into minor
# OK 2. merge minor commits into major (OK 1 without --increment/--hotfix, OK 1 with one, OK 1 with the other)
# OK 3. merge major commits into master (OK 1 without --increment/--hotfix, OK 1 with one, OK 1 with the other)
# OK 4. merge feature into major/master for hotfix.
# OK 5. commit on major/master for hotfix.
# OK 6. commit on major/master for increment.
# Merge conflicts cannot be handeled in tests sadly.
# OK Test default behaviour flags and incremental-flag.



test_010__pass_version_0_0_1_5_after_merge_from_develop_to_minor() {
	prepare_test "test_010"
	init_git_repo

	git checkout -b develop >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Initialize Develop Branch' >/dev/null 2>&1
	git checkout "$minor_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge develop -m 'Merge feature from develop to minor release branch' >/dev/null 2>&1
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
	git merge develop -m 'Merge feature from develop to minor release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git checkout "$major_version_branch_name" >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
}

# default_behaviour_on_(commit|merge) | commit_and_merge_only_if_increment_or_hotfix_argument_given | nothing (00) / increment (01) / hotfix (10)
#                  0                  |                               0                             |                    0     0                 
#                  0                  |                               0                             |                    0     1                 
#                  0                  |                               0                             |                    1     0                 
#                  0                  |                               1                             |                    0     0                 
#                  0                  |                               1                             |                    0     1                 
#                  0                  |                               1                             |                    1     0                 
#                  1                  |                               0                             |                    0     0                 
#                  1                  |                               0                             |                    0     1                 
#                  1                  |                               0                             |                    1     0                 
#                  1                  |                               1                             |                    0     0                 
#                  1                  |                               1                             |                    0     1                 
#                  1                  |                               1                             |                    1     0                 


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

# default_behaviour_on_commit and default_behaviour_on_merge both 0, means minor will be incremented if no arg given.
# commit_and_merge_only_if_increment_or_hotfix_argument_given = 1, means default values will be ignored and user will be prompted.
common_minor_to_major_0_1() {
	init_git_repo
	set_mmm_commit_and_merge_0_arg_1
	common_buildup
}

test_014__merge_minor_to_major__settings_0_1_00() {
	prepare_test "test_014"
	common_minor_to_major_0_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_015__merge_minor_to_major__settings_0_1_01() {
	prepare_test "test_015"
	common_minor_to_major_0_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_016__merge_minor_to_major__settings_0_1_10() {
	prepare_test "test_016"
	common_minor_to_major_0_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.2.6")

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

test_017__merge_minor_to_major__settings_1_0_00() {
	prepare_test "test_017"
	common_minor_to_major_1_0

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_018__merge_minor_to_major__settings_1_0_01() {
	prepare_test "test_018"
	common_minor_to_major_1_0

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_019__merge_minor_to_major__settings_1_0_10() {
	prepare_test "test_019"
	common_minor_to_major_1_0

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.2.6")

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

test_020__merge_minor_to_major__settings_1_1_00() {
	prepare_test "test_020"
	common_minor_to_major_1_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_021__merge_minor_to_major__settings_1_1_01() {
	prepare_test "test_021"
	common_minor_to_major_1_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.6")

	print_test_result "$test_name" "$result"
	finish_test
}

test_022__merge_minor_to_major__settings_1_1_10() {
	prepare_test "test_022"
	common_minor_to_major_1_1

	git merge "$minor_version_branch_name" -m 'Merge feature from minor to major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.2.6")

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

test_023__merge_major_to_master__settings_0_0_00() {
	prepare_test "test_023"
	common_major_to_master_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.1.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_024__merge_major_to_master__settings_0_0_01() {
	prepare_test "test_024"
	common_major_to_master_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_025__merge_major_to_master__settings_0_0_10() {
	prepare_test "test_025"
	common_major_to_master_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.1.1.7")

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

test_026__merge_major_to_master__settings_0_1_00() {
	prepare_test "test_026"
	common_major_to_master_0_1

	git merge "$minor_version_branch_name" -m 'Merge feature from major to master release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_027__merge_major_to_master__settings_0_1_01() {
	prepare_test "test_027"
	common_major_to_master_0_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_028__merge_major_to_master__settings_0_1_10() {
	prepare_test "test_028"
	common_major_to_master_0_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.1.1.7")

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

test_029__merge_major_to_master__settings_1_0_00() {
	prepare_test "test_029"
	common_major_to_master_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_030__merge_major_to_master__settings_1_0_01() {
	prepare_test "test_030"
	common_major_to_master_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_031__merge_major_to_master__settings_1_0_10() {
	prepare_test "test_031"
	common_major_to_master_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.1.1.7")

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

test_032__merge_major_to_master__settings_1_1_00() {
	prepare_test "test_032"
	common_major_to_master_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_033__merge_major_to_master__settings_1_1_01() {
	prepare_test "test_033"
	common_major_to_master_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.7")

	print_test_result "$test_name" "$result"
	finish_test
}

test_034__merge_major_to_master__settings_1_1_10() {
	prepare_test "test_034"
	common_major_to_master_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git merge "$major_version_branch_name" -m 'Merge feature from major to master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.1.1.7")

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

test_035__commit_on_major__settings_0_0_00() {
	prepare_test "test_035"
	common_major_commit_0_0

	git commit -m 'Commit feature on major release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_036__commit_on_major__settings_0_0_01() {
	prepare_test "test_036"
	common_major_commit_0_0

	git commit -m 'Commit feature on major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_037__commit_on_major__settings_0_0_10() {
	prepare_test "test_037"
	common_major_commit_0_0

	git commit -m 'Commit feature on major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.3")

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

test_038__commit_on_major__settings_0_1_00() {
	prepare_test "test_038"
	common_major_commit_0_1

	git commit -m 'Commit feature on major release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_039__commit_on_major__settings_0_1_01() {
	prepare_test "test_039"
	common_major_commit_0_1

	git commit -m 'Commit feature on major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_040__commit_on_major__settings_0_1_10() {
	prepare_test "test_040"
	common_major_commit_0_1

	git commit -m 'Commit feature on major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.3")

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

test_041__commit_on_major__settings_1_0_00() {
	prepare_test "test_041"
	common_major_commit_1_0

	git commit -m 'Commit feature on major release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_042__commit_on_major__settings_1_0_01() {
	prepare_test "test_042"
	common_major_commit_1_0

	git commit -m 'Commit feature on major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_043__commit_on_major__settings_1_0_10() {
	prepare_test "test_043"
	common_major_commit_1_0

	git commit -m 'Commit feature on major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.3")

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

test_044__commit_on_major__settings_1_1_00() {
	prepare_test "test_044"
	common_major_commit_1_1

	git commit -m 'Commit feature on major release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_045__commit_on_major__settings_1_1_01() {
	prepare_test "test_045"
	common_major_commit_1_1

	git commit -m 'Commit feature on major release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.1.0.3")

	print_test_result "$test_name" "$result"
	finish_test
}

test_046__commit_on_major__settings_1_1_10() {
	prepare_test "test_046"
	common_major_commit_1_1

	git commit -m 'Commit feature on major release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.3")

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

test_047__commit_on_master__settings_0_0_00() {
	prepare_test "test_047"
	common_master_commit_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "0.0.1.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_048__commit_on_master__settings_0_0_01() {
	prepare_test "test_048"
	common_master_commit_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_049__commit_on_master__settings_0_0_10() {
	prepare_test "test_049"
	common_master_commit_0_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.1.2")

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

test_050__commit_on_master__settings_0_1_00() {
	prepare_test "test_050"
	common_master_commit_0_1

	git commit -m 'Commit feature on master release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_051__commit_on_master__settings_0_1_01() {
	prepare_test "test_051"
	common_master_commit_0_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_052__commit_on_master__settings_0_1_10() {
	prepare_test "test_052"
	common_master_commit_0_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.1.2")

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

test_053__commit_on_master__settings_1_0_00() {
	prepare_test "test_053"
	common_master_commit_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_054__commit_on_master__settings_1_0_01() {
	prepare_test "test_054"
	common_master_commit_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_055__commit_on_master__settings_1_0_10() {
	prepare_test "test_055"
	common_master_commit_1_0

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.1.2")

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

test_056__commit_on_master__settings_1_1_00() {
	prepare_test "test_056"
	common_master_commit_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' >/dev/null 2>&1
	result=$(assert_one $? "$test_name")

	print_test_result "$test_name" "$result"
	finish_test
}

test_057__commit_on_master__settings_1_1_01() {
	prepare_test "test_057"
	common_master_commit_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --increment >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(assert_equal_string "$(read_version_file)" "1.0.0.2")

	print_test_result "$test_name" "$result"
	finish_test
}

test_058__commit_on_master__settings_1_1_10() {
	prepare_test "test_058"
	common_master_commit_1_1

	git checkout master >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	git commit -m 'Commit feature on master release branch' --hotfix >/dev/null 2>&1
	result=$(strict_assert_zero $? "$test_name")
	result=$(strict_assert_equal_string "$(read_version_file)" "0.0.1.2")

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
	test_014__merge_minor_to_major__settings_0_1_00
	test_015__merge_minor_to_major__settings_0_1_01
	test_016__merge_minor_to_major__settings_0_1_10
	test_017__merge_minor_to_major__settings_1_0_00
	test_018__merge_minor_to_major__settings_1_0_01
	test_019__merge_minor_to_major__settings_1_0_10
	test_020__merge_minor_to_major__settings_1_1_00
	test_021__merge_minor_to_major__settings_1_1_01
	test_022__merge_minor_to_major__settings_1_1_10
}

run_merge_major_to_master_tests() {
	test_023__merge_major_to_master__settings_0_0_00
	test_024__merge_major_to_master__settings_0_0_01
	test_025__merge_major_to_master__settings_0_0_10
	test_026__merge_major_to_master__settings_0_1_00
	test_027__merge_major_to_master__settings_0_1_01
	test_028__merge_major_to_master__settings_0_1_10
	test_029__merge_major_to_master__settings_1_0_00
	test_030__merge_major_to_master__settings_1_0_01
	test_031__merge_major_to_master__settings_1_0_10
	test_032__merge_major_to_master__settings_1_1_00
	test_033__merge_major_to_master__settings_1_1_01
	test_034__merge_major_to_master__settings_1_1_10
}

run_commit_on_major_tests() {
	test_035__commit_on_major__settings_0_0_00
	test_036__commit_on_major__settings_0_0_01
	test_037__commit_on_major__settings_0_0_10
	test_038__commit_on_major__settings_0_1_00
	test_039__commit_on_major__settings_0_1_01
	test_040__commit_on_major__settings_0_1_10
	test_041__commit_on_major__settings_1_0_00
	test_042__commit_on_major__settings_1_0_01
	test_043__commit_on_major__settings_1_0_10
	test_044__commit_on_major__settings_1_1_00
	test_045__commit_on_major__settings_1_1_01
	test_046__commit_on_major__settings_1_1_10
}

run_commit_on_master_tests() {
	test_047__commit_on_master__settings_0_0_00
	test_048__commit_on_master__settings_0_0_01
	test_049__commit_on_master__settings_0_0_10
	test_050__commit_on_master__settings_0_1_00
	test_051__commit_on_master__settings_0_1_01
	test_052__commit_on_master__settings_0_1_10
	test_053__commit_on_master__settings_1_0_00
	test_054__commit_on_master__settings_1_0_01
	test_055__commit_on_master__settings_1_0_10
	test_056__commit_on_master__settings_1_1_00
	test_057__commit_on_master__settings_1_1_01
	test_058__commit_on_master__settings_1_1_10
}

run_all_tests() {
	mark_global_start_time
	cleanup
	run_iniziation_tests
	run_merge_minor_to_major_tests
	run_merge_major_to_master_tests
	run_commit_on_major_tests
	run_commit_on_master_tests
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


prompt_user_for_confirm_cancel "Attention! If there is a .git folder in this directory, it will be deleted!! Are you sure you want to run the tests within this folder?"
run_all_tests