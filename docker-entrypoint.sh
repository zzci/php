#!/bin/bash
a2enmod rewrite

if [ -f "/init.sh" ]; then
    sh /init.sh
fi

exec "$@"
