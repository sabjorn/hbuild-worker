#!/bin/bash
export PYTHONPATH=/opt/houdini/build/houdini/python3.9libs
export HOUDINI_SCRIPT_LICENSE="hbatch -R"
export HOUDINI_DISABLE_JEMALLOCTEST=1

echo "starting hserver -- this can take a moment"
hserver -Q --render-only -S https://www.sidefx.com/license/sesinetd --clientid $SIDEFX_CLIENT --clientsecret $SIDEFX_SECRET > /dev/null 2>&1
sesictrl login --email $HOUDINI_USERNAME --password $HOUDINI_PASSWORD > /dev/null 2>&1

# test if hou can be imported -- if fails, there is an issue
python -c "import hou" > /dev/null 2>&1
exit_code=$?

# Check if the exit code is non-zero
if [ $exit_code -ne 0 ]; then
  echo "server failed to properly initialize. restart the container and try again"
  exit $exit_code
fi

exec "$@"

