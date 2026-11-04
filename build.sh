#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAS_VERSION="$(grep -E '^cas\.version=' "${SCRIPT_DIR}/version.properties" | cut -d= -f2 | tr -d '[:space:]')"
REGISTRY="${REGISTRY:-ghcr.io}"
NAMESPACE="$(printf '%s' "${NAMESPACE:-esupportail}" | tr '[:upper:]' '[:lower:]')"
PUSH="${1:-}"

if [[ $# -gt 1 || ( -n "$PUSH" && "$PUSH" != "--push" ) ]]; then
  echo "Usage: $0 [--push]" >&2
  exit 1
fi
[[ -n "$CAS_VERSION" ]] || { echo "Missing cas.version" >&2; exit 1; }

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
mkdir "${WORKDIR}/base"

echo "==> Downloading CAS ${CAS_VERSION} overlay"
# Download once for both images. curl retries HTTP 429 and transient server errors,
# honoring Retry-After when provided; HTTP errors must never become build inputs.
curl --fail --show-error --silent --location \
  --retry 5 --retry-delay 15 --retry-max-time 300 \
  --connect-timeout 30 --max-time 120 \
  "${CAS_STARTER_URL:-https://getcas.apereo.org/starter.zip}" \
  --data-urlencode type=cas-overlay \
  --data-urlencode "casVersion=${CAS_VERSION}" \
  --output "${WORKDIR}/overlay.zip"
unzip -q "${WORKDIR}/overlay.zip" -d "${WORKDIR}/base"
for file in build.gradle gradle.properties Dockerfile; do
  [[ -f "${WORKDIR}/base/${file}" ]] || {
    echo "Starter overlay is missing ${file}" >&2
    exit 1
  }
done
if ! grep -Eq "^cas\\.version[[:space:]]*=[[:space:]]*${CAS_VERSION//./\\.}[[:space:]]*$" "${WORKDIR}/base/gradle.properties"; then
  echo "Starter returned an overlay for a different CAS version" >&2
  exit 1
fi

verify_image() {
  local ref="$1" module
  shift
  echo "==> Checking modules in ${ref}"
  # Inspect the final image, without starting CAS. Support both exploded libraries
  # and libraries packaged inside a WAR. The starter image includes a JDK (jar).
  docker run --rm --network none --entrypoint sh "$ref" -ec '
    find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o \
      -type f -name "*.jar" -print
    find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o \
      -type f -name "*.war" -print | while IFS= read -r war; do
        jar tf "$war"
      done
  ' > "${WORKDIR}/contents.txt"
  sed 's|.*/||' "${WORKDIR}/contents.txt" > "${WORKDIR}/jars.txt"
  for module in "$@"; do
    if ! grep -Fxq "${module}-${CAS_VERSION}.jar" "${WORKDIR}/jars.txt"; then
      echo "Missing ${module}-${CAS_VERSION}.jar in ${ref}; publication aborted" >&2
      return 1
    fi
  done
}

build_image() {
  local name="$1" module workdir ref
  shift
  workdir="${WORKDIR}/${name}"
  mkdir "$workdir"
  cp -a "${WORKDIR}/base/." "$workdir/"
  ref="${REGISTRY}/${NAMESPACE}/${name}:${CAS_VERSION}"
  echo "==> Building ${ref}"

  # A separate dependencies block is valid Gradle; keep starter build logic intact.
  # Use artifact names directly instead of relying on the starter module catalog.
  {
    printf '\n// Modules required by esup-apereo-cas-docker (versions from the CAS BOM).\ndependencies {\n'
    for module in "$@"; do
      printf '    implementation "org.apereo.cas:%s"\n' "$module"
    done
    printf '}\n'
  } >> "${workdir}/build.gradle"

  docker build --no-cache --pull -t "$ref" "$workdir"
  verify_image "$ref" "$@"
  echo "==> Done: ${ref}"
}

build_image "apereo-cas-ldap" "cas-server-support-ldap"
build_image "apereo-cas-ldap-mfa" \
  "cas-server-support-ldap" \
  "cas-server-support-simple-mfa" \
  "cas-server-support-trusted-mfa-mongo" \
  "cas-server-core-scripting"

# Publish only after both images have passed verification.
if [[ "$PUSH" == "--push" ]]; then
  docker push "${REGISTRY}/${NAMESPACE}/apereo-cas-ldap:${CAS_VERSION}"
  docker push "${REGISTRY}/${NAMESPACE}/apereo-cas-ldap-mfa:${CAS_VERSION}"
fi
