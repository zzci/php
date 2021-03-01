#!/bin/bash
# set -ex

if [ -f "/init.sh" ]; then
    sh /init.sh
fi

exec "$@"
