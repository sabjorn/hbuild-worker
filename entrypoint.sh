#!/bin/bash

export PYTHONPATH=/opt/houdini/build/houdini/python3.11libs
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
    echo "using 'commercial' license"
    export HOUDINI_HYTHON_LIC_OPT="--check-licenses=Houdini-Master --skip-licenses=Houdini-Escape,Houdini-Engine --skip-license-modes=education,apprentice,indie"
    export HOUDINI_LICENSE_PRODUCT="Houdini-Master"
    ;;
  "indie")
    echo "using 'indie' license"
    export HOUDINI_HYTHON_LIC_OPT="--check-licenses=Houdini-Master --skip-licenses=Houdini-Escape,Houdini-Engine --skip-license-modes=education,apprentice,commercial"
    export HOUDINI_LICENSE_PRODUCT="Houdini-Engine-Indie"
    ;;
  *)
    echo "Invalid HOUDINI_LICENSE_MODE: $HOUDINI_LICENSE_MODE"
    echo "Try 'commercial' or 'indie'"
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
  
  # Use jq to sum the 'available' fields for the configured license type
  local total_available
  total_available=$(echo "$json_output" | jq "[.licenses[] | select(.product == \"$HOUDINI_LICENSE_PRODUCT\")] | map(.available) | add // 0")
  
  # Output the total number of available licenses
  echo "$total_available"
}

get_and_relinquish_users() {
  # Run the CLI command and capture the output
  local output=$(sesictrl print-license --format json)
  
  # Parse the JSON to get 'users->id' for the configured product
  local user_ids=$(echo "$output" | jq -r ".licenses[] | select(.product == \"$HOUDINI_LICENSE_PRODUCT\") | .users[].id")
  
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
  echo "No $HOUDINI_LICENSE_PRODUCT licenses available. Attempting to force removal of license(s)."
  get_and_relinquish_users
fi

# test if hou can be imported -- if fails, there is an issue
eval "python -c 'import hou; print(hou.licenseCategory())' $REDIRECT"
exit_code=$?

# Check if the exit code is non-zero
if [ $exit_code -ne 0 ]; then
  echo "'import hou' failed. This is likely caused by no licenses being available. Try setting 'HOUDINI_LICENSE_MODE' to a different mode."
  exit $exit_code
fi

exec "$@"
