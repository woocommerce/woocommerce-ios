#!/bin/bash
# Source from CI wrappers to select Java 21 and install the verified Maestro pin.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Source this script so JAVA_HOME and PATH remain active: source ${BASH_SOURCE[0]}" >&2
  exit 2
fi

TOOLCHAIN_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN_PROPERTIES="$TOOLCHAIN_SCRIPT_DIR/../toolchain.properties"
PINNED_MAESTRO="$(awk -F= '$1 == "maestro" { print $2 }' "$TOOLCHAIN_PROPERTIES")"
PINNED_MAESTRO_SHA256="$(awk -F= '$1 == "maestro_sha256" { print $2 }' "$TOOLCHAIN_PROPERTIES")"
PINNED_JAVA="$(awk -F= '$1 == "java" { print $2 }' "$TOOLCHAIN_PROPERTIES")"

current_java_major() {
  java -version 2>&1 | sed -nE 's/.*version "([0-9]+).*/\1/p' | head -n 1
}

if [[ "$(current_java_major)" != "$PINNED_JAVA" ]]; then
  if [[ "$(uname)" == "Darwin" && -x /usr/libexec/java_home ]]; then
    PINNED_JAVA_HOME="$(/usr/libexec/java_home -v "$PINNED_JAVA" 2>/dev/null || true)"
    if [[ -n "$PINNED_JAVA_HOME" ]]; then
      export JAVA_HOME="$PINNED_JAVA_HOME"
      export PATH="$JAVA_HOME/bin:$PATH"
    fi
  fi
fi
if [[ "$(current_java_major)" != "$PINNED_JAVA" ]]; then
  echo "CI requires Java $PINNED_JAVA, but no matching JDK is configured on this agent." >&2
  return 2
fi

CURRENT_MAESTRO="$(maestro --version 2>/dev/null | tail -n 1 || true)"
if [[ "$CURRENT_MAESTRO" != "$PINNED_MAESTRO" ]]; then
  MAESTRO_TOOLCHAIN_DIR="${MAESTRO_TOOLCHAIN_ROOT:-${BUILDKITE_BUILD_CHECKOUT_PATH:-$PWD}/build/maestro-toolchain}"
  MAESTRO_INSTALL_DIR="$MAESTRO_TOOLCHAIN_DIR/maestro-$PINNED_MAESTRO-$PINNED_MAESTRO_SHA256"
  MAESTRO_PINNED_BIN="$MAESTRO_INSTALL_DIR/bin/maestro"
  if [[ ! -x "$MAESTRO_PINNED_BIN" ]]; then
    echo "Installing verified Maestro $PINNED_MAESTRO into the CI job workspace."
    mkdir -p "$MAESTRO_TOOLCHAIN_DIR"
    MAESTRO_ARCHIVE="$(mktemp "$MAESTRO_TOOLCHAIN_DIR/maestro.zip.XXXXXX")"
    MAESTRO_STAGE="$(mktemp -d "$MAESTRO_TOOLCHAIN_DIR/install.XXXXXX")"
    MAESTRO_RELEASE_URL="https://github.com/mobile-dev-inc/Maestro/releases/download/cli-$PINNED_MAESTRO/maestro.zip"
    if ! curl -fsSL "$MAESTRO_RELEASE_URL" -o "$MAESTRO_ARCHIVE"; then
      rm -f "$MAESTRO_ARCHIVE"
      rm -rf "$MAESTRO_STAGE"
      return 2
    fi
    if command -v sha256sum >/dev/null 2>&1; then
      MAESTRO_ARCHIVE_SHA256="$(sha256sum "$MAESTRO_ARCHIVE" | awk '{print $1}')"
    elif command -v shasum >/dev/null 2>&1; then
      MAESTRO_ARCHIVE_SHA256="$(shasum -a 256 "$MAESTRO_ARCHIVE" | awk '{print $1}')"
    else
      echo "Cannot verify Maestro: sha256sum or shasum is required." >&2
      rm -f "$MAESTRO_ARCHIVE"
      rm -rf "$MAESTRO_STAGE"
      return 2
    fi
    if [[ "$MAESTRO_ARCHIVE_SHA256" != "$PINNED_MAESTRO_SHA256" ]]; then
      echo "Maestro archive checksum mismatch: expected $PINNED_MAESTRO_SHA256, actual $MAESTRO_ARCHIVE_SHA256" >&2
      rm -f "$MAESTRO_ARCHIVE"
      rm -rf "$MAESTRO_STAGE"
      return 2
    fi
    if ! unzip -q "$MAESTRO_ARCHIVE" -d "$MAESTRO_STAGE"; then
      rm -f "$MAESTRO_ARCHIVE"
      rm -rf "$MAESTRO_STAGE"
      return 2
    fi
    rm -f "$MAESTRO_ARCHIVE"
    if [[ ! -x "$MAESTRO_STAGE/maestro/bin/maestro" ]]; then
      echo "Verified Maestro archive does not contain maestro/bin/maestro." >&2
      rm -rf "$MAESTRO_STAGE"
      return 2
    fi
    if [[ -e "$MAESTRO_INSTALL_DIR" ]]; then
      echo "Existing pinned Maestro directory is incomplete: $MAESTRO_INSTALL_DIR" >&2
      rm -rf "$MAESTRO_STAGE"
      return 2
    fi
    if ! mv "$MAESTRO_STAGE/maestro" "$MAESTRO_INSTALL_DIR"; then
      rm -rf "$MAESTRO_STAGE"
      return 2
    fi
    rm -rf "$MAESTRO_STAGE"
  fi
  export PATH="$MAESTRO_INSTALL_DIR/bin:$PATH"
  CURRENT_MAESTRO="$(maestro --version 2>/dev/null | tail -n 1 || true)"
  if [[ "$CURRENT_MAESTRO" != "$PINNED_MAESTRO" ]]; then
    echo "Verified Maestro archive reported unexpected version: $CURRENT_MAESTRO" >&2
    return 2
  fi
fi

python3 "$TOOLCHAIN_SCRIPT_DIR/check-toolchain.py"
