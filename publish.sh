#!/bin/bash

# -e  == exit immediately
# -x  == enable debug. (+x for disable)
set -e +x



function setNpmConfig {
	NPM_RC=$1
	if [[ -f $NPM_RC ]]; then
		echo "set NPM_CONFIG_GLOBALCONFIG to $NPM_RC"
		export NPM_CONFIG_GLOBALCONFIG=$NPM_RC
	else
		echo "cannot set NPM_CONFIG_GLOBALCONFIG: $NPM_RC does not exist."
		exit -1
	fi
}


function publishNPM {
	if [[ $# -eq 0 ]]; then
		echo "Registry not set."
		exit -1
	fi

	REGISTRY=$1
	VERSION="$( npm view --registry="$REGISTRY" . version )"
	NAME="$( npm view --registry="$REGISTRY" . name )"
	RESULT=" $(npm view --registry="$REGISTRY" "${NAME}@${VERSION}" )"
	if [[ -z "${RESULT// }" ]]; then
		echo "publishing ${NAME}@${VERSION} to registry $REGISTRY"
		npm publish --access=public --registry="$REGISTRY"
	else
		echo "skipping already published package ${NAME}@${VERSION}"
	fi
}
export -f publishNPM


NPM_TEST_REGISTRY="http://n4ide1-nexus.service.cd-dev.consul/repository/npm-internal/"
DIR="$( cd "$(dirname "$0")" ; pwd -P )"
NPMRC_VERDACCIO="${DIR}/npmrc_verdaccio/.npmrc"
NPMRC_PUBLISH="${DIR}/npmrc_publish/.npmrc"
export PUBLISH_SINGLE_NPM="${DIR}/publishSingleNPM.sh"





echo "== Start publish script"
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
		echo "  kill old verdaccio with pid: $OLD_VERDACCIO_PID"
		kill $OLD_VERDACCIO_PID
	fi
	set -e

	echo "  clean artifacts of old verdaccio"
	rm -rf ./storage
fi



echo "Run npm install using registry nexus3-aws"
setNpmConfig "${NPMRC_PUBLISH}"
npm install --registry=http://nexus3-aws.corp.numberfour.eu/repository/npm-public/
echo "export PATH"
export PATH=`pwd`/node_modules/.bin:${PATH}




echo "starting new verdaccio"
verdaccio --config config.yaml &
VERDACCIO_PID=$!
echo "sleep 1s"
sleep 1s



echo "publish to local verdaccio"
setNpmConfig "${NPMRC_VERDACCIO}" # user information is inside .npmrc
lerna exec 'source ${PUBLISH_SINGLE_NPM} http://localhost:4873'




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
echo "using .npmrc file from $NPMRC_VERDACCIO"
set +e # skip problems
for PRJ_LOC in $PRJ_LOCS;
do
	echo "validate $COUNT of $PRJ_COUNT: $PRJ_LOC"
	OUTPUT="$(n4jsc --npmrcRootLocation $NPMRC_VERDACCIO -imd -bt projects $PRJ_LOC 2>&1)"

	if [[ $OUTPUT = *"ERROR:"* ]]; then
		echo "There were errors in the output:"
		echo "$OUTPUT"
		ERRORS=true
	fi

	COUNT=$[$COUNT +1];
done
setNpmConfig "${NPMRC_PUBLISH}" # reset global variable

echo "killing verdaccio"
set +e # ignore problems
kill $VERDACCIO_PID




if [[ "$ERRORS" = true ]]; then
	echo "== failed due to validation errors of n4jsd projects"
	exit -1;
fi





echo "no errors during validation"
echo "publish to $NPM_REGISTRY"
OUTPUT="$(lerna exec "$PUBLISH_SINGLE_NPM $NPM_REGISTRY" 2>&1)"
echo "$OUTPUT"

if [[ $OUTPUT = *"+ @n4jsd/"* ]]; then
	echo "published successfully:"
	echo "$OUTPUT"
else
	if [[ $OUTPUT = *"EPUBLISHCONFLICT"* ]]; then
		# never mind
		echo "one or more npm packages remain unchanged"
	else
		if [[ $OUTPUT = *"npm ERR! code"* ]]; then
			echo "== failed. see output above"
			exit -1
		fi
	fi
fi

echo "== End publish script."
exit 0


