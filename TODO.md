# TODO List #

## Features ##
* Easy to implement: Support git-tags with user option to automatically add a tag on each release or not. Then, the default behaviour would be to not add the version to the commit message.
* Very difficult to implement: Support keeping track of older releases for hotfixes and parallel development. (The tool would need to support bundles of release-branches, e.g. a main bundle with the branches master,major,minor and another with master2,major2,minor2 etc.) We could add bundles for that, e.g. a long-time-support bundle and other bundles. -> Backporting

## General Behaviour Adaptions ##
* Intermediate to implement: Make better resolvtion of special user input like git merge --abort (e.g. special git commands which would not be compatible with the versioning tool) in the pre-git hook. Idea: Parse all known args, if there are unknown additional args provide options:
  --force Use git command with versioning-tool even if there are additional arguments to commit or merge.
  --no-hook Use git command directly without the versioning-hooks. Note: Other hooks in the .git/hooks would still be invoked.
* Easy to implement: Check if merge with hotfix increments only the version on the current branch and not the greater version. Maybe an additional argument is needed?

## Tests ##


## Bug Fixes ##
