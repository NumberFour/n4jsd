#!/bin/bash

# -e  == exit immediately
# -x  == enable debug. (+x for disable)
set -e +x


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
	echo "result was"
	echo "$RESULT"
fi

cat package.json
echo "_________________________________"
echo "---------------------------------"
