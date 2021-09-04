#!/bin/bash
################################################################################
#
#  Copyright (C) 2021 Aclima, Inc.
#  This file is part of iot2web - https://github.com/Aclima/iot2web
#
################################################################################

#
# Packaging script for patching dependencies in the post-installation step
#
# Requirements:
#
#   - patch
#

# Enable strict mode
set -o errexit
set -o pipefail
set -o nounset

#
# Directory definitions
#

# Tooling directory
TOOL_DIR="tools"

# Depends directory
DEPENDS_DIR="${TOOL_DIR}/depends"

#
# Helper function
#
# Usage:
#
#   patch_package <package name> <patch name>
#
function patch_package() {
  package=$1
  patch=$2

  package_path="node_modules/${package}"
  patch_path="${DEPENDS_DIR}/${package}/${patch}"

  # Can't discern between missing patch and already-applied patch
  if [ ! -f "${patch_path}" ]; then
    echo "Missing ${patch}!"
    exit 1
  fi

  echo "### ${package_path}"

  patch \
    -p1 \
    --forward \
    --directory="${package_path}" \
    --reject-file="/dev/null" \
    --no-backup-if-mismatch \
    <"${patch_path}" \
    || :

  echo
}

#
# Helper function
#
# Usage:
#
#   patch_package_recursive <package name> <patch name>
#
# To prevent conflicts of nested dependencies, the nested package versions can
# be controlled using the "resolutions" field in package.json.
#
function patch_package_recursive() {
  package=$1
  patch=$2

  patch_path="${DEPENDS_DIR}/${package}/${patch}"

  # Can't discern between missing patch and already-applied patch
  if [ ! -f "${patch_path}" ]; then
    echo "Missing ${patch}!"
    exit 1
  fi

  for package_path in $(find "node_modules" -name "${package}" -type d); do
    # Skip rollup polyfills
    if echo "${package_path}" | grep --quiet rollup-plugin-node-polyfills; then
      continue
    fi

    # Skip type declarations
    if echo "${package_path}" | grep --quiet "@types/${package}"; then
      continue
    fi

    echo "### ${package_path}"

    patch \
      -p1 \
      --forward \
      --directory="${package_path}" \
      --reject-file="/dev/null" \
      --no-backup-if-mismatch \
      <"${patch_path}" \
      || :

    echo
  done
}

#
# Patch pacakges
#
patch_package_recursive "fwd-stream" "0001-Fix-import-of-readable-stream-objects.patch"
patch_package_recursive "google-p12-pem" "0001-Use-browserify-fs-package.patch"
patch_package_recursive "jws" "0001-Use-readable-stream-package.patch"
patch_package_recursive "level-blobs" "0001-Fix-import-of-readable-stream-objects.patch"
patch_package_recursive "proto3-json-serializer" "0001-Fix-circular-dependency.patch"
patch_package_recursive "readable-stream" "0001-Fix-circular-dependency.patch"
patch_package "rollup-plugin-node-polyfills" "0001-Fix-circular-dependencies.patch"

# TODO: Move to rollup plugin
set +o nounset
if [ "${TESTING}" != "1" ]; then
  echo "Rewriting package URLs"
  find node_modules/[^.]* -type f ! -name '*.json' -exec sed -i 's|"protobufjs"|"https://unpkg.com/protobufjs@6.11.2/dist/protobuf.min.js"|g' {} +
  find node_modules/[^.]* -type f ! -name '*.json' -exec sed -i "s|'protobufjs'|'https://unpkg.com/protobufjs@6.11.2/dist/protobuf.min.js'|g" {} +
  find node_modules/[^.]* -type f ! -name '*.json' -exec sed -i 's|"protobufjs/minimal"|"https://unpkg.com/protobufjs@6.11.2/dist/minimal/protobuf.min.js"|g' {} +
  find node_modules/[^.]* -type f ! -name '*.json' -exec sed -i "s|'protobufjs/minimal'|'https://unpkg.com/protobufjs@6.11.2/dist/minimal/protobuf.min.js'|g" {} +
  find node_modules/[^.]* -type f ! -name '*.json' -exec sed -i 's|"sshpk"|"https://bundle.run/sshpk@1.16.1"|g' {} +
  find node_modules/[^.]* -type f ! -name '*.json' -exec sed -i "s|'sshpk'|'https://bundle.run/sshpk@1.16.1'|g" {} +
fi
set -o nounset
