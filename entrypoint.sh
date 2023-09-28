#!/bin/bash
set -e

echo "starting hserver"
hserver 
hserver -C -S https://www.sidefx.com/license/sesinetd --clientid $SIDEFX_CLIENT --clientsecret $SIDEFX_SECRET

echo "logging in"
echo ${SIDEFX_CLIENT} ${SIDEFX_SECRET} > /secret
echo "HOUDINI_API_KEY_FILE=/secret" >> /root/houdini19.5/houdini.env
sesictrl login --email $HOUDINI_USERNAME --password $HOUDINI_PASSWORD 

exec "$@"
