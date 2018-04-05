# GIT-SEMANTIC-VERSIONING
A complex tool for easy use of semantic versioning with git. Best for a new git repository: Install the tool with the installscripts, which will also make the new repository for you. Then you can simply start developing and when you finish a feature, merge it to the minor branch. You will recognize the minor-version-number going up. Merge feature-bundles with backwards-compatibility to the major branch. Merge complex changes with backwards-incompatibility to the master branch.

## WARNING ##
This tool should not be used for production work, rather use it on your personal computer for private use, especially to get used to the tool and its behaviour!

## The install script does following! ##
- Make a new git repository in the current folder!
- Copy the files of versioning_hooks/ into .git/hooks/... and delete the sample hooks in the git repository.
- Add an alias to "git" to the ~/.bashrc file, if not already exists.

## The tests.sh script does following! ##
- Delete the git repository in the current folder if there is any!!!
- Perform the install-script actions for each test.
- Run more than 50 tests to check whether the tool would work on this machine.

You can and should try to download and run the tests.sh in a safe folder before using the tool for any project!
The tests will take a while (~20 minutes) as there is a lot going on in the background to check whether the tool is correctly working (git merges, commits, adds, stashes, etc.)

Not tested are pull-merges, and behaviour if multiple users are working on the same repository remotely. Thus, behaviour so far undefined.

Working is:

Commit changes, will increment commit-count. Except if you are on either the master, major or minor branch, the minor branch will be incremented for hotfixes and the corresponding individual branches will be incremented for new version releases.
Merge changes: Will check which branch has the greater version, then, will increment depending on the greater version. You can also merge hotfixes which will only increment the minor version number.

## How to use: ##
1. On a computer with a git bash, especially with a .bashrc file. (For example Windows or Ubuntu, etc.)
2. Extract downloaded files into a new empty folder.
3. Run ./versioning_install.sh
4. Run ./tests.sh and wait 20 minutes if they all passed.
5. Run ./versioning_install "FRESH_INSTALL!"
6. You now have your "empty" git repository with initialized master, major and minor branches, checked out in a new develop branch ready to start developing! The initial version is 0.0.0.3, the format is: MASTER.MAJOR.MINOR.COMMIT-COUNT.
7. Add your changes with git add file.
8. Commit your changes on your develop branch or any other feature-branch. You will now see that the commit-count went up.
9. Checkout your minor branch when you think you have finished a single feature which builds, is executable and tested, and run git merge your-feature-branch -m 'Merge message'. You will see that the minor version increased.
10. Carry on developing and repeat steps 7 to 10.
11. When you think you have a major release, checkout the major branch and merge the minor branch into the major branch.
12. Same goes for master from major if the release is really huge.

There are several options available in the versioning_tool_config file, which you can study and adapt to your needs.
The most interesting options are probably the default behaviour on commits and merges on the 3 main branches:
Do you want to increment the minor version only, say, it is a hotfix?
Or do you want to increment the corresponding version, as it is indeed a new release?
There is also a safety-option integrated: If you want to commit or merge to the master or major branches, you will be asked to append an additional argument "--increment" or "--hotfix", when the "commit_and_merge_only_if_increment_or_hotfix_argument_given" is set to 1.
This helps you to do the right thing without having to undo the next commit, if you did not remember to distinct between the hotfix-incrementation and the release-incrementation.
If you find this annoying you can set commit_and_merge_only_if_increment_or_hotfix_argument_given to 0.

Note that, merges with conflicts other than the version file cannot be tested automatically, these kind of merges are not tested yet. UNDEFINED BEHAVIOUR!

I would be grateful for any contribution, help, hints, suggestions or any other demands :)
Feel free to make a pull request and contribute to this project if you have got ideas.

BTW: To better understand the tool, studying the tests can help a lot!
