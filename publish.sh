#!/bin/bash

# -e  == exit immediately
# -x  == enable debug. (+x for disable)
set -e +x

#export NPM_CONFIG_GLOBALCONFIG=/Users/marcus.mews/GitHub/n4jsd/
echo "== Start publishing"
DIR=`dirname $0`

# The first parameter is the url to npm registry (http://localhost:4873), if not exists then exit
if [ -z "$1" ]; then
	export NPM_REGISTRY="http://webclients1-nexus.service.cd-dev.consul/repository/npm-internal"
	echo "The url to npm registry must be specified."
	echo "Using default registry: $NPM_REGISTRY"
	#exit -1
else
	export NPM_REGISTRY=$1
fi


echo "Run yarn install"
export NPM_CONFIG_GLOBALCONFIG="${DIR}"
npm install --registry=http://nexus3-aws.corp.numberfour.eu/repository/npm-public/
echo "export PATH"
export PATH=`pwd`/node_modules/.bin:${PATH}




echo "check for old verdaccio"
set +e # ignore problems
OLD_VERDACCIO_PID="$(lsof -ti :4873)"
if [ $? -eq 0 ]; then
	echo "kill old verdaccio"
	kill $OLD_VERDACCIO_PID
fi
set -e



echo "clean artifacts of old verdaccio"
rm -rf ./storage



echo "starting new verdaccio"
verdaccio --config config.yaml &
VERDACCIO_PID=$!
echo "   sleep 1s"
sleep 1s



echo "publish to local verdaccio"
# works always since verdaccio is clean and fresh
lerna exec "npm publish --registry=http://localhost:4873;"




echo "get all projects"
PRJ_LOCS="$(lerna exec pwd)"
PRJ_COUNT=0
for PRJ_LOC in $PRJ_LOCS;
do
	PRJ_COUNT=$[$PRJ_COUNT +1];
done
echo "found $PRJ_COUNT projects"




echo "validate all n4jsd projects separately"
COUNT=1
ERRORS=""
N4JSC_NPMRC=${DIR}/n4jsc_npmrc
export NPM_CONFIG_GLOBALCONFIG="${N4JSC_NPMRC}" # this may be obsolete due to argument '--npmrcRootLocation'
echo "using .npmrc file from $N4JSC_NPMRC"
set +e # skip problems
for PRJ_LOC in $PRJ_LOCS;
do
	echo "validate $COUNT of $PRJ_COUNT: $PRJ_LOC"
	OUTPUT="$(n4jsc --npmrcRootLocation $N4JSC_NPMRC -imd -bt projects $PRJ_LOC 2>&1)"

	if [[ $OUTPUT = *"ERROR:"* ]]; then
		echo "There were errors in the output:"
		echo "$OUTPUT"
		ERRORS="$OUTPUT"
	fi

	COUNT=$[$COUNT +1];
done
export NPM_CONFIG_GLOBALCONFIG="${DIR}" # reset global variable


echo "killing verdaccio"
set +e # ignore problems
kill $VERDACCIO_PID




if [ ${#ERRORS} -ne 0 ]; then
	echo "There were errors during validating all n4jsd projects. See output above."
	echo "exit."
	exit -1;
fi






echo "publish to $NPM_REGISTRY"
lerna exec "set +e; npm publish --access=public --registry=$NPM_REGISTRY; set -e;"



echo "== Publishing done."


