#!/bin/sh

coffee -bc bin
coffee -c lib

SHEBANG="#!/usr/bin/env node"
for JS in $(ls bin/*.js)
do
    printf "%s\n\n" "$SHEBANG" | cat - $JS > /tmp/occet && mv /tmp/occet $JS
done
