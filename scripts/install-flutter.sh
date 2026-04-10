#!/bin/bash

# Configuration
FLUTTER_VERSION="stable"
FLUTTER_SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz"
FLUTTER_SDK_DIR="$HOME/flutter"

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Flutter Installation Script ==="

# Fix Git ownership issues often encountered in CI (Vercel/GitHub Actions)
echo "Configuring Git safe directory..."
git config --global --add safe.directory "$FLUTTER_SDK_DIR" || true

if [ -d "$FLUTTER_SDK_DIR" ]; then
    echo "Flutter SDK already exists at $FLUTTER_SDK_DIR"
else
    echo "Downloading Flutter SDK ($FLUTTER_VERSION)..."
    curl -o flutter.tar.xz $FLUTTER_SDK_URL
    mkdir -p "$FLUTTER_SDK_DIR"
    tar -xf flutter.tar.xz -C "$HOME"
    rm flutter.tar.xz
fi

# Add to Path
export PATH="$PATH:$FLUTTER_SDK_DIR/bin"

# Verify installation
echo "Checking flutter version..."
flutter --version

echo "=== Flutter Installation Complete ==="
