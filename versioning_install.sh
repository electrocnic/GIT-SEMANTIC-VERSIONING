#!/bin/sh
#

log_active=0

log() {
	if [ $log_active -eq 1 ]; then
		echo "$1"
	fi
}

git() {
	".git/hooks/pre-git" "$@"
}

generate_git_pre_merge_hook_file() {
	printf "#!/bin/sh\n#\n\nfind_and_invoke_pre_git_hook() {\n\tfull_path_to_hook=\$(\git rev-parse --show-toplevel 2>/dev/null)\n\tif [ \"\$full_path_to_hook\" == \"\" ]; then\n\t\techo \"Git-Wrapper: Could not find a git repository. Invoking command directly.\"\n\t\t\\git \"$@\"\n\telse\n\t\t\"\${full_path_to_hook}/.git/hooks/pre-git\" \"\$@\"\n\tfi\n}\n\nfind_and_invoke_pre_git_hook \"\$@\"\n" > ~/.git-wrapper
}

add_alias_unless_existing_for_pre_merge_hook() {
	# 1. scan ./bashrc for git alias.
	result=$(grep 'alias git="./.git-wrapper"' ~/.bashrc)
	if [ "$result" == "" ]; then
		# 2. if not found add alias
		printf "\n%s\n" "alias git=\"./.git-wrapper\"" >> "~/.bashrc"
		#source "~/.bashrc"
		# 3. add script to user home dir where bashrc is too: this is the merge hook.
		generate_git_pre_merge_hook_file
		#source ~/.bashrc
	fi
}

delete_old_git_repo() {
	rm -r -f ".git" >/dev/null 2>&1
	rm -f "version" >/dev/null 2>&1
}

init_git_repo() {
	versioning_hooks/pre-git init >/dev/null 2>&1
}

# only removes sample files.
remove_old_hooks() {
	rm -f .git/hooks/*.sample >/dev/null 2>&1
}

install_new_hooks() {
	cp versioning_hooks/* .git/hooks/ >/dev/null 2>&1
}

install() {
	if [ "$1" == "FRESH_INSTALL!" ]; then
		log "Deleting old git repo"
		delete_old_git_repo
	fi
	if [ ! -d ".git" ]; then
		log "Creating new git repo"
		init_git_repo
	fi
	log "Remove sample hooks in git repo"
	remove_old_hooks
	log "Install hooks from versioning_hooks/"
	install_new_hooks
	add_alias_unless_existing_for_pre_merge_hook
}

setup() {
	git commit -m 'Initial Commit' --increment #>/dev/null 2>&1
	git checkout -b major #>/dev/null 2>&1
	git commit -m 'Initialize Major Branch' --increment #>/dev/null 2>&1
	git checkout -b minor #>/dev/null 2>&1
	git commit -m 'Initialize Minor Branch' #>/dev/null 2>&1
	git checkout -b develop #>/dev/null 2>&1
}

install "$1"
if [ "$2" = "" ]; then
	setup
fi



