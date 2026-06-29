#!/bin/sh
set -e

error() {
  echo "error: $*" >&2
  exit 1
}

run_default() {
  case "${BYOND_MODE:-host}" in
    host)
      [ -n "${BYOND_DMB:-}" ] || error "BYOND_DMB is required when BYOND_MODE=host"

      BYOND_PORT="${BYOND_PORT:-1337}"
      BYOND_TRUSTED="${BYOND_TRUSTED:-false}"

      case "$BYOND_TRUSTED" in
        true)
          exec DreamDaemon "$BYOND_DMB" -ports "$BYOND_PORT" -trusted
          ;;
        false)
          exec DreamDaemon "$BYOND_DMB" -ports "$BYOND_PORT"
          ;;
        *)
          error "BYOND_TRUSTED must be true or false"
          ;;
      esac
      ;;
    compile)
      [ -n "${BYOND_DME:-}" ] || error "BYOND_DME is required when BYOND_MODE=compile"
      exec DreamMaker "$BYOND_DME"
      ;;
    *)
      error "BYOND_MODE must be host or compile"
      ;;
  esac
}

run_requested() {
  if [ "$#" -gt 0 ]; then
    exec "$@"
  fi

  run_default
}

if [ "${1:-}" = "--byond-run" ]; then
  shift
  run_requested "$@"
fi

if { [ -n "${PUID:-}" ] && [ -z "${PGID:-}" ]; } || { [ -z "${PUID:-}" ] && [ -n "${PGID:-}" ]; }; then
  error "PUID and PGID must be set together"
fi

if { [ "${PUID:-}" = "0" ] && [ "${PGID:-}" != "0" ]; } || { [ "${PGID:-}" = "0" ] && [ "${PUID:-}" != "0" ]; }; then
  error "PUID and PGID must both be 0 to run as root"
fi

if [ -n "${PUID:-}" ] && [ "$PUID" != "0" ] && [ "$PGID" != "0" ]; then
  userdel app 2>/dev/null || true
  groupdel app 2>/dev/null || true

  EXISTING_USER="$(getent passwd "$PUID" | cut -d: -f1)"
  if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "app" ]; then
    userdel "$EXISTING_USER" 2>/dev/null || true
  fi

  EXISTING_GROUP="$(getent group "$PGID" | cut -d: -f1)"
  if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "app" ]; then
    groupdel "$EXISTING_GROUP" 2>/dev/null || true
  fi

  groupadd -g "$PGID" app
  useradd -u "$PUID" -g app -M app
  chown -R app:app /app

  if [ "$#" -gt 0 ]; then
    exec gosu app "$@"
  fi

  exec gosu app "$0" --byond-run
fi

chown -R 0:0 /app
run_requested "$@"
