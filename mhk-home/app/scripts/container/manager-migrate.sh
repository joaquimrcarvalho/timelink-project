#!/usr/bin/env bash
# to be run in the container with /home/mhk mapped to the host user home (not the host mhk-home).
echo "Checking for previous instalations"
echo "-----------------------------------"
echo "Current dir: " `pwd`
echo "HOST User HOME   :  $HOST_MHK_USER_HOME"
echo "HOST MHK HOME    :  $HOST_MHK_HOME"
export MHK_MANAGER_VERSION=`cat /mhk-home/app/manager_version`
echo "MANAGER VERSION  :  $MHK_MANAGER_VERSION"
echo
FILE=/home/mhk/mhk.properties
if [ -f "$FILE" ]; then
    echo "Old style MHK instalation detected with properties at: $FILE"
    cd /mhk-home/app/
    echo "Proceeding to migration:" `cat manager_version`
    cd java
    export MHK_HOME_DIR=/mhk-home
    export DOCKER_INSTALLER=yes
    echo "DOCKER_INSTALLER :" $DOCKER_INSTALLER
    echo "MHK_HOME_DIR     :" $MHK_HOME_DIR
    echo
    echo "Handing over to java utility"
    echo ------------------------------
    echo
    java -classpath ".:./lib/*" pt.uc.cisuc.jrc.mhk.MHK2019 "$@"
else
    echo "Could not reach $FILE."
    echo "Check that mhk.properties file exists in user home directory"
    echo "And that user home directory is mapped to '/home/mhk' in mhk-manager container"
fi
