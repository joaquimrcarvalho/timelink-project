#!/bin/bash
# Script to handle 'mhk db ....' commands
# Called by /app/manager
#
get_mysql_container() {
  cd "$HOST_MHK_HOME/app" || exit # we need this for docker-compose to read the .env file
  docker-compose -p mhk up -d mysql >/dev/null
  # shellcheck source=/
  mysql_container=$(docker-compose -p mhk ps | grep mysql | xargs -n 1 echo 2>/dev/null | head -n 1) 2>/dev/null
  echo "$mysql_container"
}
# usage: test_mysql_password PASSWORD [ResultVar]
# tests if PASSWORD is ok for user ROOT. Sets ResultVar to 0 if yes or to 1 if no
#
test_mysql_password() {
  local __resultvar="$2"
  mysql_container="$(get_mysql_container)"
  $RUN_DOCKER_IT exec "$mysql_container" sh -c "mysql -uroot -p$1 mysql -e \"status ;\" >/dev/null 2> /backup/.pwd_test"
  # shellcheck disable=SC2002
  __iresult=$(cat "$HOST_MHK_HOME/system/db/mysql/backup/.pwd_test" | grep -c ERROR)
  #echo "__iresult: $__iresult"
  if [ "$__resultvar" ]; then
    # shellcheck disable=SC2086
    eval $__resultvar="'$__iresult'"
  else
    echo "$__iresult"
  fi
}

suggest_mysql_password() {
  if [ -f "$HOST_MHK_USER_HOME/mhk.properties" ]; then
    echo "Value of HOST MySQL root password in pre-2019 MHK installation (from mhk.properties file):"
    # shellcheck disable=SC2002
    cat "$HOST_MHK_USER_HOME/mhk.properties" | grep -e "mhk\.jdbc\.dbpassword.*=." | sed 's/mhk\.jdbc\.dbpassword.*=//' | sort | uniq
    echo ""
  fi
  echo "Current stored MHK MySQL root password: " "$MYSQL_ROOT_PASSWORD"
}

pre_2019_install() {
  if [ -f "$HOST_MHK__USER_HOME/mhk.properties" ]; then
    echo "YES"
    return 0
  else
    echo "NO"
    return 1
  fi
}

echo "Running db command" "$@"
case "$1" in
"mysql" | "mariadb")
  # mysql_container=$(get_mysql_container)
  echo "Executing mysql $2 $3 $4 $5 $6 $7 $8 $9"
  # shellcheck disable=SC2086
  $RUN_DOCKER_IT  exec -it "$(get_mysql_container)" mysql $2 $3 $4 $5 $6 $7 $8 $9
  exit 0
  ;;
esac

case "$2" in
"exec")
  echo "Enter mysql root password when requested."
  # shellcheck disable=SC2086
  $RUN_DOCKER_IT  exec -it "$(get_mysql_container)" $3 $4 $5 $6 $7 $8 $9
  ;;
"ptest")
  echo
  suggest_mysql_password
  echo
  stty -echo
  printf "Password:"
  read -r pwd_to_test
  stty echo
  echo
  echo "Password to test: $pwd_to_test"
  test_mysql_password "$pwd_to_test" result
  if [ "$result" = "0" ]; then
    echo "Password OK"
  else
    echo "Password failed"
  fi
  ;;
"migrate")
  # this is db-host-dump and db-import combined
  echo "This command will migrate databases from the MySQL server on this computer (HOST MySQL)"
  echo "to the MySQL 'inside' the MHK application (MHK MySQL)"
  echo "You must have MySQL running on the HOST computer."
  echo "During the process you will be asked to enter the HOST MySQL root password"
  echo ""

  mysql_container="$(get_mysql_container)"
  file_name="all_databases.$(date +%Y-%m-%d_%H_%M_%s).sql"
  echo
  echo "Step 1: exporting databases in the host computer"
  echo "Executing:"
  #echo "mysqldump -v -uroot -p -hhost.docker.internal --all-databases --add-drop-database > /backup/$file_name"
  suggest_mysql_password
  echo "Enter HOST MySQL root password when requested."
  $RUN_DOCKER_IT  exec --user $(id -u):$(id -g) -it $mysql_container sh -c "mysqldump -v -uroot -p   -hhost.docker.internal --all-databases --add-drop-database > /backup/$file_name"
  echo "Host database dump finished."
  # check for errors
  echo "Export went to file mhk-home/system/db/mysql/backup/$file_name"
  echo
  echo "Step 2: importing database to MHK internal mysql"
  echo "Executing:"
  echo "mysql -uroot -p < /backup/$file_name"
  echo "This command can take a long time with no output."
  echo "To check progress open a new terminal window and do "
  echo "mhk db status --follow' to see number of rows imported"
  echo "Enter MHK MySQL root password when requested."
  echo "MHK MySQL root password=$MYSQL_ROOT_PASSWORD"
  $RUN_DOCKER_IT exec --user $(id -u):$(id -g) -it "$mysql_container" sh -c "mysql -uroot -p < /backup/$file_name"
  #echo "IMPORTANT: the import process might have changed the MHK MySQL root password"
  #echo "and set it to the HOST mysql root password."
  #echo "If that is the case you must use 'mhk db-store-password' to inform MHK of the password change."
  echo
  echo "Next steps:upgrade database and fix permissions."
  echo "Execute the following commands:"
  echo "mhk db upgrade"
  echo "mhk db fix-permissions"
  ;;
"host-dump")
  echo "You must have mysql running on the host computer."
  echo "You also need the root password of your current mysql instalation"
  mysql_container="$(get_mysql_container)"
  if [ "$#" -eq 2 ]; then
    host_mysql="host.docker.internal"

    suggest_mysql_password
  else
    host_mysql="$3"
    echo "Note that host $3 must allow access from this machine named $HOSTNAME"
  fi
  echo "Connecting to MySQL at $host_mysql"
  file_name="${host_mysql}_all_databases.$(date +%Y-%m-%d_%H_%M_%s).sql"
  echo "Export will go to file mhk-home/system/db/mysql/backup/$file_name"
  echo "Enter HOST mysql root password when requested."
  $RUN_DOCKER_IT exec --user $(id -u):$(id -g) -it $mysql_container sh -c "mysqldump -v -uroot -p   -h$host_mysql --all-databases --add-drop-database > /backup/$file_name"
  ;;
"dump" | "backup")
  mysql_container="$(get_mysql_container)"
  file_name="all_databases.$(date +%Y-%m-%d_%H_%M_%s).sql"
  echo "Export will go to file mhk-home/system/db/mysql/backup/$file_name"
  echo "Enter mysql root password when requested."
  $RUN_DOCKER_IT exec --user $(id -u):$(id -g) -it $mysql_container sh -c "exec mysqldump -v -uroot -p --all-databases --add-drop-database $3 $4 $5 $6 $7> /backup/$file_name"
  ;;
"export")
  mysql_container="$(get_mysql_container)"
  if [ "$#" -lt 3 ]; then
    echo
    echo "Usage: mhk db export <DATABASE>"
    echo "List of databases available for export (mhk db list)"
    docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$MYSQL_ROOT_PASSWORD -e \"SELECT table_schema FROM information_schema.tables WHERE  table_name = 'entities';\" 2>/backup/.mysql.errors "
  else
    file_name="$3_$(date +%Y-%m-%d_%H_%M_%s).sql"
    echo "Export will go to file mhk-home/system/db/mysql/backup/$file_name"
    echo "Enter mysql root password when requested."
    $RUN_DOCKER_IT exec --user $(id -u):$(id -g) -it $mysql_container sh -c "exec mysqldump -v -uroot -p --routines --databases $3 --add-drop-database > /backup/$file_name"
  fi
  ;;
"import")
  mysql_container="$(get_mysql_container)"
  if [ "$#" -eq 2 ]; then
    echo
    echo "Usage: mhk db import <FILE>"
    echo "List of files available for import at mhk-home/system/db/mysql/backup/"
    docker exec --user $(id -u):$(id -g) $mysql_container sh -c 'ls /backup/*.sql'
  else
    echo "Step 1 of 3: importing the data"
    echo "==============================="
    echo
    echo "Warning: import will only begin if no users currently using database."
    echo "To logout all mhk users before import do:"
    echo "   mhk stop mhk"
    echo "   mhk db import $3"
    echo
    echo "Executing:"
    echo "mysql -uroot -p < $3"
    echo "This command can take a long time with no output."
    echo "To check progress open a new terminal window and do 'mhk db status --follow' to see number of rows imported"
    echo "You will be requested to insert the MHK MySQL root password more than once during the import."
    suggest_mysql_password
    echo "Enter mysql root password when requested."
    $RUN_DOCKER_IT  exec --user $(id -u):$(id -g) -it $mysql_container sh -c "mysql -uroot -p < $3"
    echo
    echo "Step 2 of 3: upgrading database for current version"
    echo "==================================================="
    echo
    echo "IMPORTANT: if importing from a HOST MySQL full dump, the original root password might have replaced in MHK MySQL."
    echo "Executing:"
    echo "mysql_upgrade -uroot -p"
    echo "Enter MHK MySQL password when requested."
    $RUN_DOCKER_IT exec --user $(id -u):$(id -g) -it $mysql_container sh -c "mysql_upgrade -uroot -p"
    echo "If the upgrade failed with access denied, try again with 'mhk db-upgrade' and use the HOST MySQL password"
    echo
    echo "Step 3 of 3: fixing premissions"
    echo "=========================="
    echo
    . "$HOST_MHK_HOME/app/manager" db fix-permissions
    #echo "If the command failed with access denied, try again with 'mhk db-fix-permissions' and use the HOST  mysl password"
    echo
  fi

  ;;
"create")
  mysql_container="$(get_mysql_container)"
  echo "Nargs:" $# "Args:" "$@"
  if [ "$#" -lt 3 ]; then
    echo "Usage: mhk db create <DBNAME>"
  else
    stty -echo
    printf "Enter MHK MySQL password:"
    read current
    stty echo
    echo
    docker exec $mysql_container sh -c "mysql -uroot -p$current -e \"CREATE DATABASE $3 CHARACTER SET utf8\" "
  fi
  ;;
"copy")
  mysql_container="$(get_mysql_container)"
  if [ "$#" -lt 4 ]; then
    echo "Usage: mhk db copy <EXISTING_DB> <NEW_DB>"
  else
    stty -echo
    printf "Enter MHK MySQL password:"
    read current
    stty echo
    echo
    file_name="$3_$(date +%Y-%m-%d_%H_%M_%s).sql"
    echo "1. Dumping existing database:"
    echo "mysqldump -u root -ppassword -R $3 > /backup/$file_name"
    docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysqldump -u root -p$current -R $3 > /backup/$file_name"
    echo "2. Create new empty database"
    echo "mysqladmin -u root -ppassword create $4"
    docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysqladmin -u root -p$current create $4"
    echo "3. Import data into new database"
    echo "mysql -u root -ppassword $4 < /backup/$file_name "
    echo "This command can take a while, use 'mhk db status --follow'  in another window to monitor progress"
    docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -u root -p$current $4 < /backup/$file_name "
  fi
  ;;

"log")
  mysql_container="$(get_mysql_container)"
  if [ "$#" -lt 3 ]; then
    echo "Usage: mhk db log DATABASE [NumberOfLines]"
  else
    nrecords=${4:-100}
    docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$MYSQL_ROOT_PASSWORD -e \"select * from (select * from syslog order by seq desc limit $nrecords) subquery order by seq;\" $3"
  fi
  ;;

"status")
  mysql_container="$(get_mysql_container)"
  #echo "Enter mysql root password when requested."

  if [ "$#" -eq 3 ]; then
    if [ "$3" = "--follow" ]; then
      while true; do
        docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$MYSQL_ROOT_PASSWORD -e \"SELECT table_schema,SUM(TABLE_ROWS) FROM INFORMATION_SCHEMA.TABLES where table_schema in (SELECT table_schema FROM information_schema.tables WHERE  table_name = 'entities')group by table_schema;\" 2>/backup/.mysql.errors " >.db_status
        clear
        cat .db_status
        echo "Press Control [Ctrl] + C to stop."
        sleep 5
      done
    else
      echo "Usage: mhk db status [--follow]"
    fi
  else
    docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$MYSQL_ROOT_PASSWORD -e \"SELECT table_schema,SUM(TABLE_ROWS) FROM INFORMATION_SCHEMA.TABLES where table_schema in (SELECT table_schema FROM information_schema.tables WHERE  table_name = 'entities')group by table_schema;\" 2>/backup/.mysql.errors " >.db_status
    clear
    cat .db_status
    echo "do 'mhk db status --follow' to have status update every few seconds"
  fi
  ;;

"list")
  mysql_container="$(get_mysql_container)"
  #echo "Enter mysql root password when requested."
  docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$MYSQL_ROOT_PASSWORD -Ns -e \"SELECT table_schema FROM information_schema.tables WHERE  table_name = 'entities';\" 2>/backup/.mysql.errors "
  ;;

"processlist")
  mysql_container="$(get_mysql_container)"
  #echo "Enter mysql root password when requested."
  docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$MYSQL_ROOT_PASSWORD -Ns -e \"show processlist;\" 2>/backup/.mysql.errors "
  ;;

"host-list")
  mysql_container="$(get_mysql_container)"
  if [ "$#" -eq 2 ]; then
    host_mysql="host.docker.internal"
  else
    host_mysql="$3"
  fi
  echo "Connecting to MySQL at $host_mysql"
  echo "Enter HOST MySQL root password when requested."
  $RUN_DOCKER_IT exec --user $(id -u):$(id -g) -it $mysql_container sh -c "mysql -uroot -p -h$host_mysql -e \"SELECT table_schema FROM information_schema.tables WHERE  table_name = 'entities';\" "
  ;;
"password")
  mysql_container="$(get_mysql_container)"
  echo "Change the MHK password to be used to access the MySQL database."
  stty -echo
  printf "Enter current MHK MySQL password:"
  read current
  stty echo
  echo
  echo "Testing password:"
  docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$current mysql -e \"status ;\" 2> /backup/.pwd_test"
  result=$(cat "$HOST_MHK__HOME/system/db/mysql/backup/.pwd_test" | grep -c ERROR)
  if [ $result -eq 0 ]; then
    echo "Password OK"
  else
    echo "Error using password:" $current
    cat "$HOST_MHK__HOME/system/db/mysql/backup/.pwd_test" | grep ERROR
    echo "Previously used:"
    echo $MYSQL_ROOT_PASSWORD
    if [ -f "$HOST_MHK_USER_HOME/mhk.properties" ]; then
      cat "$HOST_MHK_USER_HOME/mhk.properties" | grep -e "mhk\.jdbc\.dbpassword.*=." | sed 's/mhk\.jdbc\.dbpassword.*=//' | sort | uniq
    fi
    exit 1
  fi
  stty -echo
  printf "New password:"
  read pwd1
  printf "\nConfirm:"
  read pwd2
  stty echo
  printf "\n"
  if [ $pwd1 != $pwd2 ]; then
    echo "Passwords do not match, try again."
    exit
  fi
  # we store the password in app/.env removing any previous value
  echo "Executing:"
  #echo mysql -uroot -p mysql -e "ALTER USER IF EXISTS 'root'@'%' IDENTIFIED BY '$pwd1' ;"
  #echo "Enter MHK MySQL password when requested."
  docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$current -e \"ALTER USER IF  EXISTS 'root'@'%' IDENTIFIED BY '$pwd1' ;\""
  docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$current -e \"ALTER USER IF  EXISTS 'root'@'localhost' IDENTIFIED BY '$pwd1' ;\""
  echo
  cp -f "$HOST_MHK_HOME/app/.env" "$HOST_MHK_HOME/app/.env.bak"
  sed '/MYSQL_ROOT_PASSWORD=/d' "$HOST_MHK_HOME/app/.env.bak" >"$HOST_MHK_HOME/app/.env"
  echo "Previous password removed:"
  cat "$HOST_MHK_HOME/app/.env"
  printf "MYSQL_ROOT_PASSWORD=$pwd1\n" >>"$HOST_MHK_HOME/app/.env"
  echo "New password added:"
  cat "$HOST_MHK_HOME/app/.env"
  echo "Make a note of the mysql root password:" $pwd1
  # shellcheck source=/
  . "$HOST_MHK_HOME/app/manager" stop mysql
  # shellcheck source=/
  . "$HOST_MHK_HOME/app/manager" start mysql
  # shellcheck source=/
  . "$HOST_MHK_HOME/app/manager" stop mhk
  # shellcheck source=/
  . "$HOST_MHK_HOME/app/manager" start mhk
  ;;

"fix-permissions")
  echo "Fixing permission on an imported database"
  mysql_container="$(get_mysql_container)"
  echo
  stty -echo
  suggest_mysql_password
  printf "Enter current MHK MySQL password:"
  read pwd1
  stty echo
  # AQUI testar a pass se ok guardar para os passos seguintesm
  echo
  echo "Testing password:"
  docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$pwd1 mysql -e \"status ;\" 2> /backup/.pwd_test"
  result=$(cat "$HOST_MHK_HOME/system/db/mysql/backup/.pwd_test" | grep -c ERROR)
  if [ $result -eq 0 ]; then
    echo "Password OK"
  else
    echo "Error using password:" $pwd1
    cat "$HOST_MHK_HOME/system/db/mysql/backup/.pwd_test" | grep ERROR
    echo "Atfer a full import of an external database it is possible"
    echo "that the HOST MySQL password was copied to the MHK MySQL database."
    suggest_mysql_password
    echo "Try again 'mhk db fix-permissions"
    exit 1
  fi
  echo
  echo "Creating user for internal MHK access (ignore warning)"
  docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$pwd1 mysql -e \" CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'koeln' ;\""
  echo
  echo "Changing password for internal MHK user (ignore warning)"
  docker exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$pwd1 mysql -e \" ALTER USER IF  EXISTS 'root'@'%' IDENTIFIED BY 'koeln' ;\""
  echo
  echo "Changing password for command line user (ignore warning)"
  docker  exec --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -p$pwd1 mysql -e \" ALTER USER IF  EXISTS 'root'@'localhost' IDENTIFIED BY 'koeln' ;\""
  echo
  echo "Granting database access to internal MHK user (ignore warning)"
  docker  exec -it --user $(id -u):$(id -g) $mysql_container sh -c "mysql -uroot -pkoeln mysql -e \" GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;\""
  cp -f "$HOST_MHK_HOME/app/.env" "$HOST_MHK_HOME/app/.env.bak"
  sed '/MYSQL_ROOT_PASSWORD=/d' "$HOST_MHK_HOME/app/.env.bak" >"$HOST_MHK_HOME/app/.env"
  printf "MYSQL_ROOT_PASSWORD=koeln\n" >>"$HOST_MHK_HOME/app/.env"
  echo "================================================"
  echo "IMPORTANT: MHK MySQL password altered to: "
  echo koeln
  echo "================================================"
  echo "MHK MySQL can be changed with 'mhk db password"
  ;;

"upgrade")
  mysql_container="$(get_mysql_container)"
  echo "Executing:"
  echo "mysql_upgrade -uroot -p $3 $4 $5 $6 $7 $8 $9"
  echo "Enter MySQL root password when requested."
  $RUN_DOCKER_IT exec -it --user $(id -u):$(id -g) $mysql_container sh -c "mysql_upgrade -uroot -p $3 $4 $5 $6 $7 $8 $9"
  echo
  echo "You should ensure that access permissions are correct for this MHK version by executing:"
  echo "mhk db fix-permissions"
  ;;

"--help" | "-h")
  cat "${HOST_MHK_HOME}/app/scripts/host/manager-db_help.txt"
  ;;

*)
  echo "Unkown mhk db command: $2"
  cat "${HOST_MHK_HOME}/app/scripts/host/manager-db_help.txt"
  ;;
esac
