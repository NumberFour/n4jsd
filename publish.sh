#!/bin/bash

# -e  == exit immediately
# -x  == enable debug. (+x for disable)
set -e +x



function setNpmConfig {
	NPM_RC=$1
	echo "set NPM_CONFIG_GLOBALCONFIG to $NPM_RC"
	export NPM_CONFIG_GLOBALCONFIG=$NPM_RC
}

NPM_TEST_REGISTRY="http://webclients1-nexus.service.cd-dev.consul/repository/npm-internal"


echo "== Start publishing"
DIR="$( cd "$(dirname "$0")" ; pwd -P )"
echo "dir of scipt is $DIR"


# The first parameter is the url to npm registry (http://localhost:4873), if not exists then exit
if [[ -z "$1" ]]; then
	export NPM_REGISTRY="$NPM_TEST_REGISTRY"
	echo "Using default registry: $NPM_TEST_REGISTRY"
	#exit -1
else
	export NPM_REGISTRY=$1
fi



if [[ -f /.dockerenv ]]; then
	OUTSIDE_DOCKER=false
else
	OUTSIDE_DOCKER=true
fi
echo "executing outside docker: $OUTSIDE_DOCKER"


if [[ "$OUTSIDE_DOCKER" = true ]]; then
	echo "check for old verdaccio"
	set +e # ignore problems
	OLD_VERDACCIO_PID="$(lsof -ti :4873 -c node -a)"
	if [[ $? -eq 0 ]]; then
		echo "kill old verdaccio with pid: $OLD_VERDACCIO_PID"
		kill $OLD_VERDACCIO_PID
	fi
	set -e

	echo "clean artifacts of old verdaccio"
	rm -rf ./storage
fi



echo "Run npm install using registry nexus3-aws"
setNpmConfig "${DIR}/.npmrc"
npm install --registry=http://nexus3-aws.corp.numberfour.eu/repository/npm-public/
echo "export PATH"
export PATH=`pwd`/node_modules/.bin:${PATH}




echo "starting new verdaccio"
verdaccio --config config.yaml &
VERDACCIO_PID=$!
echo "sleep 1s"
sleep 1s



echo "publish to local verdaccio"
N4JSC_NPMRC="${DIR}/n4jsc_npmrc/.npmrc"
setNpmConfig "${N4JSC_NPMRC}" # user information is inside .npmrc
# never fails since verdaccio is clean and fresh
lerna exec 'npm publish --registry=http://localhost:4873'




echo "get all project locations"
PRJ_LOCS="$(lerna exec pwd)"
PRJ_COUNT=0
for PRJ_LOC in $PRJ_LOCS;
do
	PRJ_COUNT=$[$PRJ_COUNT +1];
done
echo "found $PRJ_COUNT projects"




echo "validate all n4jsd projects separately"
COUNT=1
ERRORS=false
echo "using .npmrc file from $N4JSC_NPMRC"
set +e # skip problems
for PRJ_LOC in $PRJ_LOCS;
do
	echo "validate $COUNT of $PRJ_COUNT: $PRJ_LOC"
	#OUTPUT="$(n4jsc --npmrcRootLocation $N4JSC_NPMRC -imd -bt projects $PRJ_LOC 2>&1)"

	if [[ $OUTPUT = *"ERROR:"* ]]; then
		echo "There were errors in the output:"
		echo "$OUTPUT"
		ERRORS=true
	fi

	COUNT=$[$COUNT +1];
done
setNpmConfig "${DIR}/.npmrc" # reset global variable

echo "killing verdaccio"
set +e # ignore problems
kill $VERDACCIO_PID




if [[ "$ERRORS" = true ]]; then
	echo "There were errors during validating all n4jsd projects. See output above."
	echo "exit."
	exit -1;
fi





echo "no errors during validation"
echo "publish to $NPM_REGISTRY"
OUTPUT="$(lerna exec "set +e; npm publish --access=public --registry=$NPM_REGISTRY; set -e;")"

if [[ $OUTPUT = *"+ @n4jsd/"* ]]; then
	echo "published successfully:"
	echo "$OUTPUT"
else
	if [[ $OUTPUT = *"EPUBLISHCONFLICT"* ]]; then
		# never mind
		echo "one or more npm packages remain unchanged"
	fi

	if [[ $OUTPUT = *"ENEEDAUTH"* ]]; then
		echo "failed due to authentication error"
		exit -1
	fi
fi

echo "== Publishing done."
exit 0


