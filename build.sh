#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="${VERSION_FILE:-${SCRIPT_DIR}/version.properties}"
CAS_STARTER_URL="${CAS_STARTER_URL:-https://getcas.apereo.org/starter.zip}"
REGISTRY="${REGISTRY:-ghcr.io}"
IMAGE_NAMESPACE="${IMAGE_NAMESPACE:-esupportail}"
IMAGE_TAG="${IMAGE_TAG:-}"
BUILD_ROOT="${BUILD_ROOT:-}"

PUSH=false
DRY_RUN=false
KEEP_WORKDIR=false
PRINT_VERSION_ONLY=false

IMAGE_SPECS=(
  "apereo-cas-ldap|support-ldap"
  "apereo-cas-ldap-mfa|support-ldap,support-simple-mfa,groovy"
)

cleanup_dirs=()
LAST_BUILD_DIR=""

usage() {
  cat <<'EOF'
Usage: ./build.sh [options]

Builds the two CAS images described in the repository README:
  - ghcr.io/<namespace>/apereo-cas-ldap:<tag>
  - ghcr.io/<namespace>/apereo-cas-ldap-mfa:<tag>

Options:
  --push                    Push built images after a successful build.
  --registry REGISTRY       Container registry to use (default: ghcr.io).
  --image-namespace NS      Registry namespace/owner (default: esupportail).
  --image-tag TAG           Image tag to publish (default: CAS version).
  --build-root DIR          Reuse a specific working directory for extracted overlays.
  --keep-workdir            Keep generated overlay directories after the build.
  --dry-run                 Print the commands without executing them.
  --print-version           Print the CAS version resolved from version.properties.
  -h, --help                Show this help message.

Environment variables:
  VERSION_FILE, CAS_STARTER_URL, REGISTRY, IMAGE_NAMESPACE, IMAGE_TAG, BUILD_ROOT

Examples:
  ./build.sh
  ./build.sh --push
  ./build.sh --push --image-namespace esupportail --image-tag 7.3.6
EOF
}

log() {
  printf '[build] %s\n' "$*"
}

die() {
  printf '[build] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

trim() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  printf '%s' "$value"
}

read_cas_version() {
  [[ -f "$VERSION_FILE" ]] || die "Version file not found: $VERSION_FILE"

  local first_line
  first_line="$({ grep -E -v '^[[:space:]]*($|#)' "$VERSION_FILE" || true; } | head -n 1)"
  first_line="$(trim "$first_line")"

  [[ -n "$first_line" ]] || die "No CAS version found in $VERSION_FILE"

  if [[ "$first_line" == cas.version=* ]]; then
	first_line="${first_line#cas.version=}"
  fi

  first_line="$(trim "$first_line")"
  first_line="${first_line#v}"

  [[ -n "$first_line" ]] || die "Resolved CAS version is empty"
  printf '%s\n' "$first_line"
}

run() {
  if "$DRY_RUN"; then
	printf '+'
	printf ' %q' "$@"
	printf '\n'
	return 0
  fi

  "$@"
}

create_build_dir() {
  local image_name="$1"
  local dir

  if [[ -n "$BUILD_ROOT" ]]; then
	dir="${BUILD_ROOT%/}/${image_name}"
	rm -rf "$dir"
	mkdir -p "$dir"
  else
	dir="$(mktemp -d "${TMPDIR:-/tmp}/${image_name}-XXXXXX")"
  fi

  cleanup_dirs+=("$dir")
  LAST_BUILD_DIR="$dir"
}

cleanup() {
  local dir

  if "$KEEP_WORKDIR"; then
	return 0
  fi

  for dir in "${cleanup_dirs[@]:-}"; do
	[[ -n "$dir" && -d "$dir" ]] && rm -rf "$dir"
  done
}

build_image() {
  local image_name="$1"
  local dependencies="$2"
  local build_dir overlay_zip image_ref

  create_build_dir "$image_name"
  build_dir="$LAST_BUILD_DIR"
  overlay_zip="${build_dir}/overlay.zip"
  image_ref="${REGISTRY%/}/${IMAGE_NAMESPACE}/${image_name}:${IMAGE_TAG}"

  log "Building ${image_ref}"
  log "Using temporary workspace: ${build_dir}"

  run curl -fsSL --get -o "$overlay_zip" "$CAS_STARTER_URL" \
	--data-urlencode "type=cas-overlay" \
	--data-urlencode "dependencies=${dependencies}" \
	--data-urlencode "casVersion=${CAS_VERSION}"
  run unzip -q "$overlay_zip" -d "$build_dir"
  run rm -f "$overlay_zip"
  run rm -rf "$build_dir/.git" "$build_dir/.github"
  run docker build --pull -t "$image_ref" "$build_dir"

  if "$PUSH"; then
	run docker push "$image_ref"
  fi

  log "Done: ${image_ref}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
	--push)
	  PUSH=true
	  ;;
	--registry)
	  shift
	  [[ $# -gt 0 ]] || die "Missing value for --registry"
	  REGISTRY="$1"
	  ;;
	--image-namespace)
	  shift
	  [[ $# -gt 0 ]] || die "Missing value for --image-namespace"
	  IMAGE_NAMESPACE="$1"
	  ;;
	--image-tag)
	  shift
	  [[ $# -gt 0 ]] || die "Missing value for --image-tag"
	  IMAGE_TAG="$1"
	  ;;
	--build-root)
	  shift
	  [[ $# -gt 0 ]] || die "Missing value for --build-root"
	  BUILD_ROOT="$1"
	  ;;
	--keep-workdir)
	  KEEP_WORKDIR=true
	  ;;
	--dry-run)
	  DRY_RUN=true
	  ;;
	--print-version)
	  PRINT_VERSION_ONLY=true
	  ;;
	-h|--help)
	  usage
	  exit 0
	  ;;
	*)
	  die "Unknown option: $1"
	  ;;
  esac
  shift
done

CAS_VERSION="$(read_cas_version)"

if "$PRINT_VERSION_ONLY"; then
  printf '%s\n' "$CAS_VERSION"
  exit 0
fi

IMAGE_TAG="${IMAGE_TAG:-$CAS_VERSION}"
IMAGE_TAG="${IMAGE_TAG#v}"
IMAGE_NAMESPACE="$(printf '%s' "$IMAGE_NAMESPACE" | tr '[:upper:]' '[:lower:]')"

[[ -n "$REGISTRY" ]] || die "Registry must not be empty"
[[ -n "$IMAGE_NAMESPACE" ]] || die "Image namespace must not be empty"
[[ -n "$IMAGE_TAG" ]] || die "Image tag must not be empty"

require_command curl
require_command unzip
require_command docker

trap cleanup EXIT

for image_spec in "${IMAGE_SPECS[@]}"; do
  IFS='|' read -r image_name dependencies <<< "$image_spec"
  build_image "$image_name" "$dependencies"
done

log "All image builds completed successfully"
