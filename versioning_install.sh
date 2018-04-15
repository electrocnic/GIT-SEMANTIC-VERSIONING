#!/bin/bash
#

log_active=0
bash_file=~/.bashrc
git_wrapper_file=~/.git-wrapper

log() {
	if [ $log_active -eq 1 ]; then
		echo "$1"
	fi
}

git() {
	".git/hooks/pre-git" "$@"
}

generate_git_pre_merge_hook_file() {
	printf "#!/bin/bash\n#\n\nfind_and_invoke_pre_git_hook() {\n\tfull_path_to_hook=\$(\git rev-parse --show-toplevel 2>/dev/null)\n\tif [ \"\$full_path_to_hook\" == \"\" ]; then\n\t\techo \"Git-Wrapper: Could not find a git repository. Invoking command directly.\"\n\t\t\\git \"\$@\"\n\telse\n\t\t\"\${full_path_to_hook}/.git/hooks/pre-git\" \"\$@\"\n\tfi\n}\n\nfind_and_invoke_pre_git_hook \"\$@\"\n" > "$git_wrapper_file"
}

add_alias_unless_existing_for_pre_merge_hook() {
	# 1. scan ./bashrc for git alias.
	result=$(grep 'alias git="~/.git-wrapper"' $bash_file)
	if [ "$result" == "" ]; then
		# 2. if not found add alias
		printf "\n%s\n" "alias git=\"~/.git-wrapper\"" >> "$bash_file"
	fi
	if [ ! -f "$git_wrapper_file" ]; then
		# 3. add script to user home dir where bashrc is too: this is the merge hook.
		generate_git_pre_merge_hook_file
	fi
}

delete_old_git_repo() {
	rm -r -f ".git" >/dev/null 2>&1
	rm -f "version" >/dev/null 2>&1
}

# only removes sample files.
remove_old_hooks() {
	rm -f .git/hooks/*.sample >/dev/null 2>&1
}

install_new_hooks() {
	cp versioning_hooks/* .git/hooks/ >/dev/null 2>&1
	chmod 755 .git/hooks/*
}

install_wrapper() {
	add_alias_unless_existing_for_pre_merge_hook
	chmod 755 "$git_wrapper_file"
}

init_git_repo() {
        if [ ! -d ".git" ]; then
                log "Creating new git repo"
                versioning_hooks/pre-git init >/dev/null 2>&1
        fi
        log "Remove sample hooks in git repo"
        remove_old_hooks
        log "Install hooks from versioning_hooks/"
        install_new_hooks
}

setup() {
	git commit -m 'Initial Commit' --increment #>/dev/null 2>&1
	git checkout -b major #>/dev/null 2>&1
	git commit -m 'Initialize Major Branch' --increment #>/dev/null 2>&1
	git checkout -b minor #>/dev/null 2>&1
	git commit -m 'Initialize Minor Branch' #>/dev/null 2>&1
	git checkout -b develop #>/dev/null 2>&1
}

print_usage() {
	echo "versioning_install.sh - Usage:"
	echo "\"./versioning_install.sh 0\":	Install git_wrapper and alias to git_wrapper ONLY."
	echo "					No git repo will be initialized in the current directory"
	echo ""
	echo "\"./versioning_install.sh 1\":	Same like mode 0 but also install scripts to git "
	echo "					repo in the current working directory."
	echo "					If no git repo exists, one will be initialized."
	echo "					No branches will be initialized."
	echo "					This is the way to go for existing git repos where"
	echo "					you want to start using the versioning tool."
	echo ""
	echo "\"./versioning_install.sh 2\":	Same like mode 1 but also initialize branches"
	echo "					to match the versioning_tool's setup."
	echo "					This is the way to go if you want to start with a"
	echo "					fresh git repo using the versioning_tool in the"
	echo "					cleanest way possible from the beginning."
	echo ""
	echo "\"./versioning_install.sh 3\":	Same like mode 1 but also deletes an existing"
	echo "					git repo if found in the current directory."
	echo "					This is used by the tests.sh, so be aware"
	echo "					that you run the tests in a safe environment!"
	echo ""
	echo "\"./versioning_install.sh 4\":    Same like mode 2 but also deletes an existing"
	echo "					git repo if found in the current directory."
	echo "					This is used by the tests.sh, so be aware"
	echo "					that you run the tests in a safe environment!"
	echo ""
}


if [ "$1" == "0" ]; then
	log "Installing wrapper ONLY..."
	install_wrapper
elif [ "$1" == "1" ]; then
	log "Installing wrapper and init git repo..."
	install_wrapper
	init_git_repo	
elif [ "$1" == "2" ]; then
	log "Installing wrapper, init git repo and setup branches..."
	install_wrapper
	init_git_repo
	setup
elif [ "$1" == "3" ]; then
	log "Installing wrapper, delete old git repo, init new git repo..."
	install_wrapper	
	log "Deleting old git repo"
        delete_old_git_repo
	init_git_repo
elif [ "$1" == "4" ]; then
	log "Installing wrapper, delete old git repo, init new, setup branches..."
	install_wrapper
	log "Deleting old git repo"
        delete_old_git_repo
	init_git_repo
	setup
else
	print_usage
fi

chown -R $USER:$USER .
chmod -R 755 *
