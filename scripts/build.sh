#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="DayStart"
BUILD_DIR="$ROOT/.build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
INSTALL_DIR="${1:-$HOME/Applications}"

echo "==> Building $APP_NAME..."
swift build -c release --product DayStart

BIN="$(swift build -c release --show-bin-path)/DayStart"
if [[ ! -x "$BIN" ]]; then
  echo "Binary not found: $BIN" >&2
  exit 1
fi

echo "==> Packaging app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp "$BIN" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

# Ad-hoc sign so macOS will launch the local build more reliably.
codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$APP_DIR" "$INSTALL_DIR/$APP_NAME.app"

echo "==> Installed: $INSTALL_DIR/$APP_NAME.app"
echo "Run: open \"$INSTALL_DIR/$APP_NAME.app\""
