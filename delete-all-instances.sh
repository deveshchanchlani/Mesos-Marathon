#!/bin/sh

doctl compute droplet list --no-header| tr -s ' ' | cut -d ' '  -f 1 | xargs doctl compute droplet delete -f