#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-run}"
APP_NAME="TodoList"
BUNDLE_ID="local.todolist.mac"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
case "$MODE" in
  run|--debug|--logs|--telemetry|--verify|--package) ;;
  *) echo "usage: $0 [--debug|--logs|--telemetry|--verify|--package]" >&2; exit 2 ;;
esac
if [ "$MODE" = "--package" ]; then
  swift build -c release --arch arm64 --arch x86_64
  BUILD_BINARY="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/$APP_NAME"
  APP_BUNDLE="$ROOT_DIR/dist/release/$APP_NAME.app"
else
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
fi
mkdir -p "$APP_BUNDLE/Contents/MacOS"
cp "$BUILD_BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
RESOURCES="$APP_BUNDLE/Contents/Resources"
ICONSET="$ROOT_DIR/.build/TodoList.iconset"
LOGO="$ROOT_DIR/Assets/Brand/todolist-logo-v1.png"
mkdir -p "$RESOURCES" "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$LOGO" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  double_size=$((size * 2))
  sips -z "$double_size" "$double_size" "$LOGO" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"
cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$APP_NAME</string>
<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleVersion</key><string>2</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>LSUIElement</key><true/>
<key>CFBundleDevelopmentRegion</key><string>zh_CN</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP_BUNDLE"
if [ "$MODE" = "--package" ]; then
  codesign --verify --strict "$APP_BUNDLE"
  ARCHIVE="$ROOT_DIR/dist/TodoList-v1.0.0-macOS-universal.zip"
  ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ARCHIVE"
  (cd "$ROOT_DIR/dist" && shasum -a 256 "$(basename "$ARCHIVE")" > SHA256SUMS.txt)
  echo "$ARCHIVE"
  exit
fi
if [ "$MODE" = "--debug" ]; then
  lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
  exit
fi
/usr/bin/open -n "$APP_BUNDLE"
case "$MODE" in
  --logs) /usr/bin/log stream --info --style compact --predicate 'process == "TodoList"' ;;
  --telemetry) /usr/bin/log stream --info --style compact --predicate 'subsystem == "local.todolist.mac"' ;;
  --verify) sleep 1; pgrep -x "$APP_NAME" >/dev/null; echo "TodoList 已启动" ;;
esac
