#!/usr/bin/env bash
# ./imports/scripts/extract-version.sh
# Extracts the latest SemVer tag (vX.Y.Z) from Git tags. If none exists, defaults to v1.0.0.

set -e

LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")
echo "$LATEST_TAG"