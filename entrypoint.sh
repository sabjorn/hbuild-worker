#!/bin/bash

export PYTHONPATH=/opt/houdini/build/houdini/python3.9libs
export HOUDINI_SCRIPT_LICENSE="hbatch -R"
export HOUDINI_DISABLE_JEMALLOCTEST=1

if [ "$VERBOSE" = "true" ]; then
  echo "VERBOSE mode set"
  REDIRECT=""
else
  REDIRECT="> /dev/null 2>&1"
fi

if [ -z "$HOUDINI_LICENSE_MODE" ]; then
  echo "HOUDINI_LICENSE_MODE is not set. Defaulting to 'commercial'."
  HOUDINI_LICENSE_MODE="commercial"
else
  HOUDINI_LICENSE_MODE="${HOUDINI_LICENSE_MODE,,}"  # Convert to lowercase
fi

case "$HOUDINI_LICENSE_MODE" in
  "commercial")
    export HOUDINI_HYTHON_LIC_OPT="--check-licenses=Houdini-Master --skip-licenses=Houdini-Escape,Houdini-Engine"
    ;;
  "education")
    export HOUDINI_HYTHON_LIC_OPT="--skip-license-modes=commercial,apprentice,indie"
    ;;
  "indie")
    export HOUDINI_HYTHON_LIC_OPT="--skip-license-modes=commercial,education,apprentice"
    ;;
  "apprentice")
    export HOUDINI_HYTHON_LIC_OPT="--skip-license-modes=commercial,education,indie"
    ;;
  *)
    echo "Invalid HOUDINI_LICENSE_MODE: $HOUDINI_LICENSE_MODE"
    echo "Try 'commercial', 'education', 'indie', or 'apprentice'"
    exit 1
    ;;
esac

echo "starting hserver -- this can take a moment"
eval "hserver -Q --render-only -S https://www.sidefx.com/license/sesinetd --clientid \$SIDEFX_CLIENT --clientsecret \$SIDEFX_SECRET $REDIRECT"
eval "sesictrl login --email \$HOUDINI_USERNAME --password \$HOUDINI_PASSWORD $REDIRECT"

# test if hou can be imported -- if fails, there is an issue
eval "python -c 'import hou' $REDIRECT"
exit_code=$?

# Check if the exit code is non-zero
if [ $exit_code -ne 0 ]; then
  echo "'import hou' failed. This is likely caused by no licenses being available. Try setting 'HOUDINI_LICENSE_MODE' to a different mode."
  exit $exit_code
fi

exec "$@"
