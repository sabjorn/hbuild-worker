#!/bin/bash

export PYTHONPATH=/opt/houdini/build/houdini/python3.9libs
export HOUDINI_SCRIPT_LICENSE="hbatch -R"
export HOUDINI_DISABLE_JEMALLOCTEST=1
export HOUDINI_HYTHON_LIC_OPT="--check-licenses=Houdini-Master --skip-licenses=Houdini-Escape,Houdini-Engine"

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
    echo "using 'commercial' license"
    ;;
  "education")
    echo "using 'education' license"
    export HOUDINI_HYTHON_LIC_OPT="$HOUDINI_HYTHON_LIC_OPT --skip-license-modes=commercial,apprentice,indie"
    ;;
  "indie")
    echo "using 'indie' license"
    export HOUDINI_HYTHON_LIC_OPT="$HOUDINI_HYTHON_LIC_OPT --skip-license-modes=commercial,education,apprentice"
    ;;
  "apprentice")
    export HOUDINI_HYTHON_LIC_OPT="$HOUDINI_HYTHON_LIC_OPT --skip-license-modes=commercial,education,indie"
    ;;
  *)
    echo "Invalid HOUDINI_LICENSE_MODE: $HOUDINI_LICENSE_MODE"
    echo "Try 'commercial', 'education', 'indie', or 'apprentice'"
    exit 1
    ;;
esac

check_houdini_license_available() {
  # Execute the CLI command and store its output in a variable
  local json_output
  json_output=$(sesictrl print-license --format json)

  # If the command fails, return 0
  if [ $? -ne 0 ]; then
    echo 0
    return
  fi

  # Use jq to sum the 'available' fields for licenses where "product" starts with "Houdini-Engine"
  local total_available
  total_available=$(echo "$json_output" | jq '[.licenses[] | select(.product | startswith("Houdini-Engine"))] | map(.available) | add // 0')

  # Output the total number of available licenses
  echo "$total_available"
}

get_and_relinquish_users() {
  # Run the CLI command and capture the output
  local output=$(sesictrl print-license --format json)

  # Parse the JSON to get 'users->id' where 'product' starts with 'Houdini-Engine'
  local user_ids=$(echo "$output" | jq -r '.licenses[] | select(.product | startswith("Houdini-Engine")) | .users[].id')

  # Check if any IDs were found
  if [[ -z "$user_ids" ]]; then
    return 1
  fi

  # Relinquish each found user ID
  for id in $user_ids; do
    sesictrl relinquish "$id"
  done
}

echo "starting hserver -- this can take a moment"
eval "hserver -Q --render-only -S https://www.sidefx.com/license/sesinetd --clientid \$SIDEFX_CLIENT --clientsecret \$SIDEFX_SECRET $REDIRECT"
eval "sesictrl login --email \$HOUDINI_USERNAME --password \$HOUDINI_PASSWORD $REDIRECT"

available_licenses=$(check_houdini_license_available)
if [ "$available_licenses" -eq 0 ]; then
  echo "No Houdini Engine licenses available. Attempting to force removal of license(s)."
  get_and_relinquish_users
fi
# test if hou can be imported -- if fails, there is an issue
eval "python -c 'import hou' $REDIRECT"
exit_code=$?

# Check if the exit code is non-zero
if [ $exit_code -ne 0 ]; then
  echo "'import hou' failed. This is likely caused by no licenses being available. Try setting 'HOUDINI_LICENSE_MODE' to a different mode."
  exit $exit_code
fi

exec "$@"
