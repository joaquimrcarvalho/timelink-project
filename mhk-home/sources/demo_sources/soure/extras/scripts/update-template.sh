#!/bin/bash
#
# This updates a repository forked from this one with new stuff added here
# after the fork.
#
# Use case: after this template repository is forked for a new community,
# and then cloned to a workstation, the commands pull and push refer to the
# forked repository, not this original one. If this template is updated after
# the fork it is necessary to add it as a remote of the community fork and
# pull.
#
# Use on a repository cloned from a fork of the timelink-sources-template repo.


# Add the original repository and a remote.
git remote add template https://github.com/joaquimrcarvalho/timelink-sources-template.git
# Pull new stuff into master branch
git pull template master --allow-unrelated-histories
# remove the remote to prevent pushing by accident.
git remote rm template
