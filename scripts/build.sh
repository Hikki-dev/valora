#!/bin/bash

# Exit on error
set -e

# Ensure scripts directory is in path for helper scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Install/Setup Flutter
source "$SCRIPT_DIR/install-flutter.sh"

# Add Flutter to Path (redundant but safe)
export PATH="$PATH:$HOME/flutter/bin"

# 2. Configure Flutter for Web
echo "Configuring Flutter for Web..."
flutter config --enable-web

# 3. Get Dependencies
echo "Running flutter pub get..."
flutter pub get

# 4. Build Web App
echo "Building Flutter Web (Release) with Auto renderer..."
flutter build web --release --web-renderer auto --no-pub
echo "Build command finished with status: $?"

# 5. Verification
if [ ! -d "build/web" ]; then
    echo "Error: build/web directory not found!"
    exit 1
fi

if [ ! -f "build/web/index.html" ]; then
    echo "Error: build/web/index.html not found!"
    exit 1
fi

echo "Detailed contents of build/web:"
ls -la build/web

echo "Build complete! Output is in build/web"
