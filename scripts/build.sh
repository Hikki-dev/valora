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
flutter build web --release --web-renderer auto --no-pub \
  --dart-define=SUPABASE_URL=https://pgjymcazcsjbkzvqwmhd.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBnanltY2F6Y3NqYmt6dnF3bWhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMjQ3ODIsImV4cCI6MjA5MDgwMDc4Mn0.Q-B4cBMDbFk-eQPL1GqQ2bDtzzM3SmM8u7_7I0Y3348 \
  --dart-define=APP_VERSION=1.0.0
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
