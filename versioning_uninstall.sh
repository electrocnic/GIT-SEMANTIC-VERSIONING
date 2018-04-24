#!/bin/bash
#

git_wrapper_file=~/.git-wrapper
bashrc_file=~/.bashrc

print_usage() {
	echo "versioning_uninstall.sh - Usage:"
	echo ""
	echo "\"versioning_uninstall.sh 0\":	Uninstall wrapper only:"
	echo "					This will remove the file \"~/.git-wrapper\""
	echo "					and the entry \"alias git=~/.git-wrapper\""
	echo "					from the ~/.bashrc. Note, that you have to"
	echo "					remove the PS1-entry manually, if you no"
	echo "					longer want it, as you also added it by hand!"
	echo ""
	echo "\"versioning_uninstall.sh 1\":	Same like 0 but also uninstall the scripts"
	echo "					in the git repo in the current directory"
	echo "					This will not remove the whole files of"
	echo "					the standard git hooks, but will eliminate"
	echo "					the individual lines which are from this"
	echo "					tool."
	echo ""
	echo "\"versioning_uninstall.sh 2\":	Same like 0 but also remove the git repo"
	echo "					of the current directory."
	echo ""
}


uninstall_wrapper() {
	if [ -f "$git_wrapper_file" ];then
		rm "$git_wrapper_file"
	fi

	result=$(sed -i.bak '\#alias git=\"~\/\.git-wrapper\"#d' "$bashrc_file" 2>&1)
	if [ "$result" == "" ]; then
		echo "Removed git alias for versioning tool. Generated backup of the old bashrc in ~/.bashrc.bak!"
	else
		echo "Removing alias in bashrc failed: $result"
	fi	
}

print_notification() {
	if [ "$2" == "" ]; then
                echo "Removed (line in) $1 successfully."
        else
                echo "Removing (line in) $1 failed: $2"
        fi
}

uninstall_scripts_in_repo() {
	full_path_to_hook=$(\git rev-parse --show-toplevel 2>/dev/null)
        if [ "$full_path_to_hook" == "" ]; then
                echo "Could not find a git repository. No need to uninstall scripts."
        else
		# remove versioning-hook in post-commit:
		result=$(sed -i '\~\.git/hooks/versioning_tool_post_commit\.sh~d' "${full_path_to_hook}/.git/hooks/post-commit" 2>&1)
		print_notification "post-commit" "$result"

		# remove versioning-hook in post-merge:
		result=$(sed -i '\~\.git/hooks/versioning_tool_post_merge\.sh \"\$@\"~d' "${full_path_to_hook}/.git/hooks/post-merge" 2>&1)
		print_notification "post-merge" "$result"

		# remove versioning-hook in prepare-commit-msg
		result=$(sed -i '\~\.git/hooks/versioning_tool_prepare_commit_msg\.sh \"\$1\"~d' "${full_path_to_hook}/.git/hooks/prepare-commit-msg" 2>&1)
		print_notification "prepare-commit-msg" "$result"

		# remove pre-git
		result=$(rm "${full_path_to_hook}/.git/hooks/pre-git" 2>&1)
		print_notification "pre-git" "$result"

		# remove all versioning_tool_* files
		vh_files=$(echo ${full_path_to_hook}/.git/hooks/versioning_tool_*)
		result=$(rm $vh_files 2>&1)
		print_notification "versioning_tool_*" "$result"
        fi
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

uninstall_repo() {
	full_path_to_hook=$(\git rev-parse --show-toplevel 2>/dev/null)
        if [ "$full_path_to_hook" == "" ]; then
                echo "Could not find a git repository."
        else
		result=$(rm -r "${full_path_to_hook}/.git" 2>&1)
        	print_notification ".git/" "$result"
	fi
}


if [ "$1" == "0" ]; then
	uninstall_wrapper
elif [ "$1" == "1" ]; then
	uninstall_wrapper
	uninstall_scripts_in_repo
elif [ "$1" == "2" ]; then
	prompt_user_for_confirm_cancel "WARNING! You are about to DELETE your git REPO, NOT the versioning_tool!!"
	uninstall_wrapper
	uninstall_repo
else
	print_usage
fi



