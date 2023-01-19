#!/usr/bin/env bash
# to be run in the container with /mhk-home mapped to the host mhk-home directory
echo "Processing user command with args" "$@"
export DOCKER_INSTALLER=yes
export MHK_MANAGER_VERSION=`cat /mhk-home/app/manager_version`
cd /mhk-home/app/java/
$winpty java -classpath ".:./lib/*" pt.uc.cisuc.jrc.mhk.MHK2019 "$@"
