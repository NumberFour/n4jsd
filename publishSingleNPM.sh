#!/bin/bash

# -e  == exit immediately
# -x  == enable debug. (+x for disable)
set -e +x


if [[ $# -eq 0 ]]; then
	echo "Registry not set."
	exit -1
fi

REGISTRY=$1
NAME=$(node -p -e "require('./package.json').name")
VERSION=$(node -p -e "require('./package.json').version")

echo "NAME@Version = ${NAME}@${VERSION}"

RESULT=" $(npm view --registry="$REGISTRY" "${NAME}@${VERSION}" || echo "" )"

if [[ -z "${RESULT// }" ]]; then
	echo "publishing ${NAME}@${VERSION} to registry $REGISTRY"
	npm publish --access=public --registry="$REGISTRY"
else
	echo "skipping already published package ${NAME}@${VERSION}"
fi

