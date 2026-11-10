#!/bin/bash
# Installs or updates Nibbling from https://github.com/Dbhardwaj99/nibbling
#
# It downloads the latest release, checks its SHA-256, puts Nibbling.app in
# /Applications (or ~/Applications if that isn't writable) and opens it.
# It uses only tools built into macOS and never asks for your password.

set -euo pipefail

DOWNLOAD="https://github.com/Dbhardwaj99/nibbling/releases/latest/download"
APP="Nibbling.app"
EXECUTABLE="$APP/Contents/MacOS/Nibbling"
BUNDLE_ID="io.github.dbhardwaj99.Autocompleter"

fail() {
  echo "Error: $1" >&2
  exit 1
}

download() {
  local code
  code="$(curl -sSL -w '%{http_code}' -o "$tmp/$1" "$DOWNLOAD/$1")" \
    || fail "The download failed. Check your connection and try again."
  if [ "$code" = "404" ]; then
    fail "There's no Nibbling release to download yet."
  elif [ "$code" != "200" ]; then
    fail "The download failed (HTTP $code). Try again later."
  fi
}

main() {
  if [ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" != "1" ]; then
    fail "Nibbling needs a Mac with Apple silicon (M1 or later)."
  fi
  local major
  major="$(sw_vers -productVersion | cut -d. -f1)"
  if [ "$major" -lt 14 ]; then
    fail "Nibbling needs macOS 14 Sonoma or later."
  fi

  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  echo "Downloading Nibbling..."
  download Nibbling.zip
  download Nibbling.zip.sha256

  local expected actual
  expected="$(cut -d' ' -f1 < "$tmp/Nibbling.zip.sha256")"
  actual="$(shasum -a 256 "$tmp/Nibbling.zip" | cut -d' ' -f1)"
  if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
    fail "The download doesn't match its checksum. Nothing was installed."
  fi

  ditto -x -k "$tmp/Nibbling.zip" "$tmp/unpacked"
  [ -d "$tmp/unpacked/$APP" ] || fail "The download doesn't contain $APP."

  local dest="/Applications"
  if [ ! -w "$dest" ]; then
    dest="$HOME/Applications"
    mkdir -p "$dest"
  fi

  if pgrep -qf "$EXECUTABLE"; then
    echo "Quitting Nibbling..."
    pkill -f "$EXECUTABLE" || true
    # Wait until the old copy has exited and macOS has let go of it too: opening the new copy
    # while macOS still lists the old one fails with error -600.
    local waited=0
    while { pgrep -qf "$EXECUTABLE" || [ -n "$(lsappinfo find "bundleid=$BUNDLE_ID")" ]; } \
        && [ "$waited" -lt 40 ]; do
      sleep 0.5
      waited=$((waited + 1))
    done
  fi

  if [ -e "$dest/$APP" ]; then
    mv "$dest/$APP" "$tmp/previous.app" \
      || fail "Couldn't replace $dest/$APP. Move it to the Trash, then run this again."
  fi
  if ! mv "$tmp/unpacked/$APP" "$dest/$APP"; then
    if [ -e "$tmp/previous.app" ]; then
      mv "$tmp/previous.app" "$dest/$APP" || true
    fi
    fail "Couldn't move Nibbling into $dest."
  fi

  echo "Installed Nibbling in $dest. Opening it..."
  # If macOS is still letting go of the old copy, opening fails for a moment, so try a few times.
  local tries=1
  until open "$dest/$APP" 2>/dev/null; do
    if [ "$tries" -ge 10 ]; then
      fail "Nibbling is installed, but it didn't open. Open it from $dest."
    fi
    sleep 0.5
    tries=$((tries + 1))
  done
}

# Everything runs from here, so a download cut off halfway runs nothing.
main "$@"
