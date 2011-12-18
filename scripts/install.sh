#!/bin/sh

coffee -bc bin
coffee -c lib

shebang="#!/usr/bin/env node"
for js in $(ls bin/*.js)
do
    echo -e "$shebang\n" | cat - $js > /tmp/occet && mv /tmp/occet $js
done
