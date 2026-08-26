#!/usr/bin/env sh
# ci/build.sh — shared verify + idempotency + build + push helper for BYOND images.
#
# Modes (exactly one required):
#   --channel stable|beta   Resolve the full version from secure.byond.com/download/version.txt
#                           (line 1 = stable, line 2 = beta).
#   --version 516.1659      Explicit full version.
#   --major 515             Resolve the newest published minor for a major (backport).
#
# Options:
#   --floating-tags "a,b"   Extra floating tags to push. <full> and <major> are ALWAYS pushed
#                           in addition to these.
#   --on-existing skip|fail|overwrite   Policy when <full> already exists in the registry.
#                                       Default: skip.
#   --on-missing  skip|fail             Policy when the Linux binaries are not published yet.
#                                       Default: fail.
#
# Environment:
#   REGISTRY_IMAGE       e.g. ghcr.io/neurekadev/byond   (required)
#   BUILD_METADATA_FILE  Optional path for Docker Buildx result metadata.
#   FORCE_OVERWRITE      "true" promotes --on-existing to overwrite (default: false).
set -eu

VERSION_URL="https://secure.byond.com/download/version.txt"
BUILD_URL="https://www.byond.com/download/build"

log() { printf '%s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

http_status() { curl -o /dev/null -s -I -L --max-time 30 -w '%{http_code}' "$1"; }

# $1 major, $2 minor -> 0 if the Linux release zip is published (HTTP 200).
binaries_exist() {
  [ "$(http_status "${BUILD_URL}/$1/$1.$2_byond_linux.zip")" = "200" ]
}

# $1 = stable|beta -> echoes the full version (empty if that channel is not published yet;
# the caller applies the --on-missing policy so, e.g., "no current beta" is a graceful skip).
resolve_channel_version() {
  _line=1
  [ "$1" = "beta" ] && _line=2
  _txt=$(curl -fsSL --max-time 30 "$VERSION_URL") || die "Could not fetch $VERSION_URL"
  printf '%s\n' "$_txt" | sed -n "${_line}p" | tr -d '[:space:]'
}

# --- Backport minor resolution --------------------------------------------
# Resolve the newest published minor for a given major from BYOND's build-directory
# autoindex. A single request only: BYOND is behind Cloudflare and bursts of requests
# trip rate-limit error 1015, so there is deliberately no downward-probe loop. Swap this
# one function to change the strategy. To build an exact older minor, use --version instead.
# $1 = major -> echoes the minor.
resolve_backport_minor() {
  _major="$1"
  _listing=$(curl -fsSL --max-time 30 "${BUILD_URL}/${_major}/") \
    || die "Could not fetch the build listing for major ${_major}. Run CI with target=version and value=<major>.<minor>."
  _minor=$(printf '%s\n' "$_listing" \
    | grep -oE "${_major}\.[0-9]+_byond_linux\.zip" \
    | grep -oE '\.[0-9]+_' | tr -d '._' \
    | sort -n | tail -n1)
  [ -n "$_minor" ] \
    || die "No Linux builds found for major ${_major} in the listing. Run CI with target=version and value=<major>.<minor>."
  printf '%s' "$_minor"
}
# --------------------------------------------------------------------------

# $1 = full image ref -> 0 if the tag already exists in the registry.
tag_exists() { docker manifest inspect "$1" >/dev/null 2>&1; }

# $1 full, $2 major, $3 minor, $4 extra floating tags (csv).
build_and_push() {
  _full="$1"; _major="$2"; _minor="$3"; _extra="$4"
  _img="${REGISTRY_IMAGE:?REGISTRY_IMAGE is required}"

  _tag_names="${_full} ${_major}"
  if [ -n "$_extra" ]; then
    _o=$IFS; IFS=','
    for _t in $_extra; do
      [ -n "$_t" ] && _tag_names="${_tag_names} ${_t}"
    done
    IFS=$_o
  fi

  log "Building and pushing ${_img} (version=${_full}, major=${_major}, minor=${_minor}); tags:${_tag_names}"
  set -- docker buildx build \
    --pull \
    --push \
    --build-arg "APP_VERSION=${_full}" \
    --build-arg "BYOND_MAJOR=${_major}" \
    --build-arg "BYOND_MINOR=${_minor}"
  if [ -n "${BUILD_METADATA_FILE:-}" ]; then
    set -- "$@" --metadata-file "$BUILD_METADATA_FILE"
  fi
  for _t in $_tag_names; do
    set -- "$@" -t "${_img}:${_t}"
  done
  set -- "$@" .
  "$@"
}

MODE=""; MODE_ARG=""; FLOATING_TAGS=""; ON_EXISTING="skip"; ON_MISSING="fail"
while [ $# -gt 0 ]; do
  case "$1" in
    --channel) MODE=channel; MODE_ARG="$2"; shift 2 ;;
    --version) MODE=version; MODE_ARG="$2"; shift 2 ;;
    --major)   MODE=major;   MODE_ARG="$2"; shift 2 ;;
    --floating-tags) FLOATING_TAGS="$2"; shift 2 ;;
    --on-existing)   ON_EXISTING="$2";   shift 2 ;;
    --on-missing)    ON_MISSING="$2";    shift 2 ;;
    *) die "Unknown argument: $1" ;;
  esac
done
[ -n "$MODE" ] || die "One of --channel / --version / --major is required."

case "$MODE" in
  channel)
    FULL=$(resolve_channel_version "$MODE_ARG")
    if [ -z "$FULL" ]; then
      case "$ON_MISSING" in
        skip) log "No ${MODE_ARG} version is currently published; on-missing=skip -> nothing to do."; exit 0 ;;
        *)    die "No ${MODE_ARG} version found in version.txt." ;;
      esac
    fi
    ;;
  version) FULL="$MODE_ARG" ;;
  major)
    MINOR=$(resolve_backport_minor "$MODE_ARG") || exit 1
    FULL="${MODE_ARG}.${MINOR}"
    ;;
esac

MAJOR=$(printf '%s' "$FULL" | cut -d. -f1)
MINOR=$(printf '%s' "$FULL" | cut -d. -f2)
[ -n "$MAJOR" ] && [ -n "$MINOR" ] && [ "$MAJOR" != "$FULL" ] || die "Malformed version: '${FULL}'"
IMAGE="${REGISTRY_IMAGE:?REGISTRY_IMAGE is required}"
log "Resolved BYOND version ${FULL} (major=${MAJOR}, minor=${MINOR})."

# 1) Verify the Linux binaries are published.
if ! binaries_exist "$MAJOR" "$MINOR"; then
  case "$ON_MISSING" in
    skip) log "No Linux binaries for ${FULL} yet; on-missing=skip -> nothing to do."; exit 0 ;;
    *)    die "No Linux binaries for ${FULL} (HTTP != 200)." ;;
  esac
fi
log "Linux binaries confirmed for ${FULL}."

# 2) Idempotency: skip/fail/overwrite if the <full> tag already exists.
if tag_exists "${IMAGE}:${FULL}"; then
  if [ "${FORCE_OVERWRITE:-false}" = "true" ]; then
    log "Tag ${FULL} exists; FORCE_OVERWRITE=true -> rebuilding."
  else
    case "$ON_EXISTING" in
      skip)      log "Tag ${FULL} exists; on-existing=skip -> nothing to do."; exit 0 ;;
      fail)      die "Tag ${FULL} already exists; on-existing=fail." ;;
      overwrite) log "Tag ${FULL} exists; on-existing=overwrite -> rebuilding." ;;
      *)         die "Invalid --on-existing: ${ON_EXISTING}" ;;
    esac
  fi
else
  log "Tag ${FULL} not found; proceeding to build."
fi

# 3) Build and push.
build_and_push "$FULL" "$MAJOR" "$MINOR" "$FLOATING_TAGS"
log "Done."
