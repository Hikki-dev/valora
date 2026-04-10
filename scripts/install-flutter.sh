#!/bin/bash

# Configuration
FLUTTER_VERSION="stable"
FLUTTER_SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz"
FLUTTER_SDK_DIR="$HOME/flutter"

echo "=== Flutter Installation Script ==="

if [ -d "$FLUTTER_SDK_DIR" ]; then
    echo "Flutter SDK already exists at $FLUTTER_SDK_DIR"
else
    echo "Downloading Flutter SDK ($FLUTTER_VERSION)..."
    # We use a specific version for better reliability, but you can change this to latest stable url
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
