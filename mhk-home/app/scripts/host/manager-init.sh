#!/bin/bash
# manager-init.sh
# this is to be run on the host, from mhk-home
# Initializes the mhk application by storing the paths to the user home and mhk-home
# in the file ~/.mhk where they can be retrieved by the mhk (host) manager script as needed
#
# Must be run from inside mhk-home directory that was populated by the mhk-install script
# run in the mhk-manager container with
#   docker run  -v $PWD:/mhk-home -it mhk-manager mhk-install
#
# This script checks:
# HOST_MHK_HOME/.mhk-home : It is created by the mhk-install script in the mhk-manager image. Contains a date.
#                           It is used by this script to check if we are at mhk-home in order
#                           to finish instalation.
#
# This sccript writes:
#
# HOST_MHK_HOME/.mhk-home-manager-init : with a date to signal that init was done
#
# THIS MUST BE IN SYNC WITH app/manager.sh
test_os() {
  _mac=$(docker version | grep -c darwin)
  _arm=$(docker version | grep -c "arm64")
  _windows=$(docker version | grep -c windows)
  _linux=$(docker version | grep -c linux)

  if [ "$_mac" != "0" ]; then
    echo "mac"
    return
  fi
  if [ "$_windows" != "0" ]; then
    if [ ! -f /c/Windows/System32/BitLockerWizard.exe ]; then
      echo "windows-home"
    else
      echo "windows"
    fi
    return
  fi
  if [ "$_linux" != "0" ]; then
    echo "linux"
    return
  fi
  echo "unknown"
  return
}



echo "Initializing mhk-home ..."
# We check if we are inside a mhk-home type directory if not we abort
# The mhk-installer  script puts a .mhk-home in the mhk-home
if [ -f .mhk-home-manager-init ]; then
  echo "Init already called in this directory:  $(cat .mhk-home-manager-init)"
  echo "Updating"
fi
HOST_MHK_HOME="$(pwd)"
export HOST_MHK_HOME
if [ -f .mhk-home ]; then
  HOST_MHK_HOME="$(pwd)"
  export HOST_MHK_HOME
else
  echo "To finish instalation manager must be run from inside mhk-home."
  echo "We are inside $PWD, please cd to mhk-home and type mhk init"
  echo
  echo "To create a new mhk-home and initialize mhk do:"
  echo "   mkdir -p mhk-home"
  echo "   cd mhk-home"
  echo "   docker run  -v \$PWD:/mhk-home -it mhk-manager mhk-install"
  echo "   sh app/manager init"
  exit 1
fi
HOST_MHK_USER_HOME="$HOME" # $HOME is a bultin variable in bash
export HOST_MHK_USER_HOME
export os=$(test_os)
if [ "$os" = "windows-home" ]; then
  MYSQL_OPTS="--innodb-use-native-aio=0"
else
  MYSQL_OPTS=" "
fi
# Copy vars to user home dir where we will get them in the next runs
printf "HOST_MHK_USER_HOME=\"%s\"\nHOST_MHK_HOME=\"%s\"\nmhk_home_dir=\"%s\"\nMYSQL_OPTS=\"%s\"\n" \
  "$HOST_MHK_USER_HOME" "$HOST_MHK_HOME" "$HOST_MHK_HOME" "$MYSQL_OPTS" >"$HOST_MHK_USER_HOME/.mhk"

# Add alias to mhk manager to .bash_profile, deleting any previous one
# Create a .bash_profile if it does not exist...
touch ~/.bash_profile
# 1. copy existing profile deleting any alias to mhk
sed '/alias mhk=/d' ~/.bash_profile >~/.bash_profile_mhk
# also delete alias for mhk.bak from backup bash profile
if [ "$os" = "mac" ]; then
  sed -i=bak '/alias mhk\.bak=/d' ~/.bash_profile_mhk
else
  sed --in-place=bak '/alias mhk\.bak=/d' ~/.bash_profile_mhk
fi
# 2. backup existing profile
cp -f ~/.bash_profile ~/.bash_profile-mhk.bak
# 3. add new alias to manager and a backup version in case of bad update
# the backup is created by the manager update command
cp -f ~/.bash_profile_mhk ~/.bash_profile
printf "alias mhk=\"sh '%s/app/manager'\"\n" "$HOST_MHK_HOME" >>~/.bash_profile
printf "alias mhk.bak=\"sh '%s/app/manager.bak'\"\n" "$HOST_MHK_HOME" >>~/.bash_profile
# allow for zsh (MacOS 10.15+)

if [ "$SHELL" = "/bin/zsh" ]; then
  touch ~/.zshenv
  touch ~/.zshenv_mhk
  if [ "$os" = "mac" ]; then
    sed -i=bak '/source ~\/\.bash=/d' ~/.zshenv_mhk
  else
    sed --in-place=bak '/source ~\/\.bash=/d' ~/.zshenv_mhk
  fi
  cp -f ~/.zshenv ~/.zshenv.mhk.bak
  cp -f ~/.zshenv_mhk ~/.zshenv
  echo "source ~/.bash_profile" >> ~/.zshenv
fi
# new style aliasing
# add "alias mhk=\"sh '%s/app/manager'\"\n"  to .bashrc if not already there
# add "alias mhk.bak=\"sh '%s/app/manager.bak'\"\n"  to .bashrc if not already there
# check if alias is already there
touch ~/.bashrc
touch ~/.zshrc
if [ "$os" = "mac" ]; then
  _alias=$(grep -c "alias mhk=" ~/.bashrc)
else
  _alias=$(grep --count "alias mhk=" ~/.bashrc)
fi
if [ "$_alias" = "0" ]; then
  printf "alias mhk=\"sh '%s/app/manager'\"\n" "$HOST_MHK_HOME" >>~/.bashrc
  printf "alias mhk.bak=\"sh '%s/app/manager.bak'\"\n" "$HOST_MHK_HOME" >>~/.bashrc
fi
# allow for zsh

if [ "$os" = "mac" ]; then
  _alias=$(grep -c "alias mhk=" ~/.zshrc)
else
  _alias=$(grep --count "alias mhk=" ~/.zshrc)
fi
if [ "$_alias" = "0" ]; then
  printf "alias mhk=\"sh '%s/app/manager'\"\n" "$HOST_MHK_HOME" >>~/.zshrc
  printf "alias mhk.bak=\"sh '%s/app/manager.bak'\"\n" "$HOST_MHK_HOME" >>~/.zshrc
fi


# 4. register that manager did its first time run
date >"$HOST_MHK_HOME/.mhk-home-manager-init"
echo "mhk-home init finished."
