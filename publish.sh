#!/bin/bash

# -e  == exit immediately
# -x  == enable debug. (+x for disable)
set -e +x

export NPM_CONFIG_GLOBALCONFIG=/Users/marcus.mews/GitHub/n4jsd/

cd npm/cheerio/1.0.0/

npm publish --registry=http://webclients1-nexus.service.cd-dev.consul/repository/npm-internal/ 
