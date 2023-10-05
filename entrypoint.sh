#!/bin/bash

export PYTHONPATH=/opt/houdini/build/houdini/python3.9libs
export HOUDINI_SCRIPT_LICENSE="hbatch"
export HOUDINI_DISABLE_JEMALLOCTEST=1

function start_hserver {
  hserver > /dev/null 2>&1
  hserver -C -S https://www.sidefx.com/license/sesinetd --clientid $SIDEFX_CLIENT --clientsecret $SIDEFX_SECRET > /dev/null 2>&1
  sesictrl login --email $HOUDINI_USERNAME --password $HOUDINI_PASSWORD > /dev/null 2>&1
}

echo "starting hserver -- this can take a moment"
start_hserver

counter=0
max_attempts=10
while true; do
  python -c "import hou"
  if [ $? -eq 0 ]; then
    break
  fi
  
  hserver -q > /dev/null 2>&1
  start_hserver
  ((counter++))
  if [[ $counter -gt $max_attempts ]]; then
    echo "Maximum number of attempts reached. Exiting..."
    exit 1
  fi
done

exec "$@"

