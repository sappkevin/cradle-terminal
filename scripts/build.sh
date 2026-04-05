#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "=== Generating Xcode project ==="
xcodegen generate

echo "=== Resolving Swift packages ==="
xcodebuild -resolvePackageDependencies \
    -project Cradle.xcodeproj \
    -scheme Cradle

echo "=== Building ==="
xcodebuild build \
    -project Cradle.xcodeproj \
    -scheme Cradle \
    -configuration Release \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="-"

APP_PATH="build/Build/Products/Release/Cradle.app"

if [ -d "$APP_PATH" ]; then
    echo "=== Build succeeded ==="
    echo "App location: $APP_PATH"
    echo ""
    echo "To create a .dmg, run:"
    echo "  create-dmg --volname 'Cradle' --app-drop-link 450 190 'Cradle.dmg' '$APP_PATH'"
    echo ""
    echo "To run directly:"
    echo "  open '$APP_PATH'"
else
    echo "=== Build failed — check output above ==="
    exit 1
fi
