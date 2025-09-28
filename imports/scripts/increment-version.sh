#!/usr/bin/env bash
# ./imports/scripts/increment-version.sh
# Increments the patch version of a SemVer string (e.g., v1.0.0 -> v1.0.1).

set -e

VERSION=$1
if [[ ! $VERSION =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "Invalid SemVer: $VERSION" >&2
    exit 1
fi

MAJOR=${BASH_REMATCH[1]}
MINOR=${BASH_REMATCH[2]}
PATCH=${BASH_REMATCH[3]}
NEW_PATCH=$((PATCH + 1))
echo "v${MAJOR}.${MINOR}.${NEW_PATCH}"