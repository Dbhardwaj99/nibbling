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
    local waited=0
    while pgrep -qf "$EXECUTABLE" && [ "$waited" -lt 20 ]; do
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
  open "$dest/$APP"
}

# Everything runs from here, so a download cut off halfway runs nothing.
main "$@"
