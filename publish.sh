#!/bin/bash

# -e  == exit immediately
# -x  == enable debug. (+x for disable)
set -e +x

#export NPM_CONFIG_GLOBALCONFIG=/Users/marcus.mews/GitHub/n4jsd/
echo "== Start publishing"

echo "   Run yarn install"
yarn install

echo "   export PATH"
export PATH=`pwd`/node_modules/.bin:${PATH}

# Set N4_N4JSC_JAR to the the freshly built n4jsc.jar in tools/hlc/target
#export N4_N4JSC_JAR="${CUR_DIR}/tools/org.eclipse.n4js.hlc/target/n4jsc.jar"

echo "   starting verdaccio"
verdaccio &
VERDACCIO_PID=$!
echo "   sleep 1s"
sleep 1s

PACKAGE_JSON="package.json"
PACKAGE_JSON_LENGTH=${#PACKAGE_JSON}


pushd npm
	echo "   run in every"
	for PCKJSON in $(find . -name $PACKAGE_JSON);
	do
		LENGTH=${#PCKJSON}
		LOCATION=${PCKJSON:0:LENGTH-PACKAGE_JSON_LENGTH}
		pushd $LOCATION
			#echo "publish $LOCATION";
			set +e # ignore problems
			#npm publish --access=public --registry=http://localhost:4873
			subl .project
			set -e
		popd
	done
popd

#lerna exec npm publish --access=public --registry=http://localhost:4873


echo "   killing verdaccio"
set +e # ignore problems
kill $VERDACCIO_PID


echo "== Publishing done."
