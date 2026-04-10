#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAS_VERSION="$(grep -E '^cas\.version=' "${SCRIPT_DIR}/version.properties" | cut -d= -f2 | tr -d '[:space:]')"
REGISTRY="${REGISTRY:-ghcr.io}"
NAMESPACE="$(printf '%s' "${NAMESPACE:-esupportail}" | tr '[:upper:]' '[:lower:]')"
PUSH="${1:-}"

build_image() {
  local name="$1" deps="$2"
  local workdir ref

  workdir="$(mktemp -d)"
  trap "rm -rf '$workdir'" RETURN

  ref="${REGISTRY}/${NAMESPACE}/${name}:${CAS_VERSION}"
  echo "==> Building ${ref}"

  curl ${CAS_STARTER_URL:-https://getcas.apereo.org/starter.zip} \
    -d type=cas-overlay \
    -d dependencies=${deps} \
    -d casVersion=${CAS_VERSION} \
    -o ${workdir}/overlay.zip

  unzip -q "${workdir}/overlay.zip" -d "${workdir}"
  rm -f "${workdir}/overlay.zip"

  docker build --pull -t "${ref}" "${workdir}"

  [[ "${PUSH}" == "--push" ]] && docker push "${ref}"
  echo "==> Done: ${ref}"
}

build_image "apereo-cas-ldap"     "support-ldap"
build_image "apereo-cas-ldap-mfa" "support-ldap,support-simple-mfa,support-trusted-mfa-mongo,groovy"
