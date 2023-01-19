# Updates the images. Called from main manager script, and is supposed to exit
  cd "${HOST_MHK_HOME}"
    if [ "$current_os" = "windows" ] || [ "$current_os" = "windows-home" ]; then
    CURRENT_DIR=$(cygpath -w -m "$PWD")
  else
    CURRENT_DIR=${PWD}
  fi
  if [ "$2" = "--local" ] || [ "$3" = "--local" ]; then
    ## does not work as user
    #docker run --user $(id -u):$(id -g) --name manager --rm -v /"${PWD}":/mhk-home joaquimrcarvalho/mhk-manager:$TAG mhk-install
    docker run --name manager --rm -v /"${PWD}":/mhk-home joaquimrcarvalho/mhk-manager:$TAG mhk-install
    echo "MHK local update finished using latest tag"
  else
    if [ -z ${TAG} ];
    then
      echo "Pulling image tagged 'Latest'. Set TAG variable for other.";
      export TAG="latest"
      else
        echo "Using images tagged '$TAG'";
      fi
    docker pull joaquimrcarvalho/mhk-manager:$TAG
    # can't manage how to run this as user, must be root
    # docker run --user $(id -u):$(id -g) --name manager --rm  -v /"${PWD}":/mhk-home joaquimrcarvalho/mhk-manager:$TAG mhk-install
    docker run --name manager --rm  -v /"${PWD}":/mhk-home joaquimrcarvalho/mhk-manager:$TAG mhk-install
    echo "Updating components. This may take a while."
    cd "${HOST_MHK_HOME}/app"
    docker-compose -p mhk pull --include-deps mhk
    echo "MHK update from repository finished"
  fi
  echo "Start services with:"
  echo "  mhk start"
  echo
  exit 0
