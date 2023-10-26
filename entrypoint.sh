#!/bin/bash
export PYTHONPATH=/opt/houdini/build/houdini/python3.9libs
export HOUDINI_SCRIPT_LICENSE="hbatch -R"
export HOUDINI_DISABLE_JEMALLOCTEST=1

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
hserver -Q --render-only -S https://www.sidefx.com/license/sesinetd --clientid $SIDEFX_CLIENT --clientsecret $SIDEFX_SECRET > /dev/null 2>&1
sesictrl login --email $HOUDINI_USERNAME --password $HOUDINI_PASSWORD > /dev/null 2>&1

if [[ ! -z "${FORCE_LICENSE_RELINQUISH}" ]]; then
  echo "attempting to force removal of license(s)"
  get_and_relinquish_users
fi

# test if hou can be imported -- if fails, there is an issue
python -c "import hou" > /dev/null 2>&1
exit_code=$?

# Check if the exit code is non-zero
if [ $exit_code -ne 0 ]; then
  echo "'import hou' failed. This is likely caused by no licenses being available. Try rerunning with 'FORCE_LICENSE_RELINQUISH=1'"
  exit $exit_code
fi

exec "$@"

