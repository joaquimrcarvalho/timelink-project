#!/bin/bash
# Script to handle the sources directory and associated git repositories
# Called by /app/manager
#
COMPOSE_PROJECT_NAME=mhk
export COMPOSE_PROJECT_NAME

get_kleio_container() {
  cd "$HOST_MHK_HOME/app" || exit # we need this for docker compose to read the .env file
  docker compose -p mhk up -d kleio >/dev/null
  # shellcheck source=/
  kleio_container=$(docker compose -p mhk ps | grep kleio | xargs -n 1 echo 2>/dev/null | head -n 1) 2>/dev/null
  echo "$kleio_container"
}
kleio_container="$(get_kleio_container)"

check_user_name_and_email() {
  has_email=$(docker exec --user $(id -u):$(id -g) $kleio_container sh -c "cd /kleio-home/sources/$1 && (git config -l | grep -c email)")
  has_username=$(docker exec --user $(id -u):$(id -g) $kleio_container sh -c "cd /kleio-home/sources/$1 && (git config -l | grep -c user\.name)")
  echo ${has_username}${has_email}
}

echo "Running command" "$@" in $kleio_container

case "$2" in
"list")
  docker exec $kleio_container sh -c "ls -a /kleio-home/sources/ |cat"
  exit 0
  ;;

"clone")
  URL=$3
  TOKEN=$4
  TURL=https://mhk-timelink:${TOKEN}@${URL:8}
  if [ "$6" = "--recurse-submodules" ]; then
    TURL="--recurse-submodules $TURL"
  fi
  echo "Running: cd /kleio-home/sources && git clone $TURL $5"
  $RUN_DOCKER_IT exec --user $(id -u):$(id -g) -it $kleio_container sh -c "cd /kleio-home/sources && git clone $TURL $5"
  exit 0
  ;;

"--help" | "-h")
  cat "${HOST_MHK_HOME}/app/scripts/host/manager-sources_help.txt"
  exit 0
  ;;

esac



user_check=$(check_user_name_and_email "$2")
if [ "${user_check:0:1}" = "0" ]; then
  echo "Git requires user name for commits and related operations"
  printf "Enter an user name (FirstName LastName) "
  read -r user_name
  docker exec --user $(id -u):$(id -g) $kleio_container sh -c "cd /kleio-home/sources/$2 && git config user.name \"${user_name}\""
  echo "User $user_name will be associated with commits in directory $2"
  echo "To change user name do: mhk sources $2 user-info \"FIRST LAST\" email@site.com"
  echo
fi

if [ "${user_check:1:1}" = "0" ] && [ "$3" != "user-info" ]; then
  echo "Git requires user email for commits and related operations"
  printf "Enter an email: "
  read -r user_email
  docker exec --user $(id -u):$(id -g) $kleio_container sh -c "cd /kleio-home/sources/$2 && git config user.email \"${user_email}\""
  echo "User $user_name will be associated with commits in directory $2"
  echo "To change user name do: mhk sources $2 user-info \"FIRST LAST\" email@site.com"
  echo
fi

case "$3" in
"git")
  echo "Runing /mhk-home/sources/$2% git  $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} "
  $RUN_DOCKER_IT exec --user $(id -u):$(id -g) -it $kleio_container sh -c "cd /kleio-home/sources/$2 && git  $4 $5 $6 $7 $8 $9 ${10} ${11} ${12}"
  exit 0
  ;;

"status")
  echo
  docker exec --user $(id -u):$(id -g) $kleio_container sh -c "cd /kleio-home/sources/$2 && git status ."
  exit 0
  ;;

"log")
  echo
  if [ -z "$4" ]; then
     FOUR='--pretty=format:"%ad | %s [%an] %d" --date=short -n 10'
  else
    FOUR="$4"
  fi
  echo "git log $FOUR $5 $6 $7 $8 $9 ."
  docker exec --user $(id -u):$(id -g) $kleio_container sh -c "cd /kleio-home/sources/$2 && git log $FOUR $5 $6 $7 $8 $9 ."
  exit 0
  ;;

"commit")
  echo $(check_user_name_and_email "$2")
  exit 0
  ;;

"stash")
  echo $(check_user_name_and_email "$2")
  exit 0
  ;;

"user-info")
  if [ "$4" = "--show" ]; then
    $RUN_DOCKER_IT exec --user $(id -u):$(id -g) -it $kleio_container sh -c "cd /kleio-home/sources/$2 && git config -l | grep user"
    exit 0
  fi
  docker exec --user $(id -u):$(id -g) $kleio_container sh -c "cd /kleio-home/sources/$2 && git config user.name \"$4\" && git config user.email \"$5\""
  echo "User name and email set to $4 $5"
  exit 0
  ;;

*)
  echo "Passing command $3 to git"
  echo
  docker exec --user $(id -u):$(id -g) $kleio_container sh -c "cd /kleio-home/sources/$2 && git $3 $4 $5 $6 $7 $8 $9"
  exit 0
  ;;

esac
