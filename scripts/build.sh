#!/bin/bash

# Ensure scripts directory is in path for helper scripts if needed
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
echo "Building Flutter Web (Release)..."
# We add --pwa-strategy offline-first if needed, or other flags
flutter build web --release

echo "Build complete! Output is in build/web"
