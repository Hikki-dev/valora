#!/bin/bash

# Valora Automated Version Bumper
# Increments the +n part of 'version: x.y.z+n' in pubspec.yaml

PUBSPEC_FILE="pubspec.yaml"

# 1. Extract current version string precisely
# Uses grep to find line, then sed to strip 'version: ' and any surrounding space
CURRENT_VERSION=$(grep "^version: " $PUBSPEC_FILE | sed 's/version: //;s/ //g')

if [ -z "$CURRENT_VERSION" ]; then
    echo "Error: Could not find version in $PUBSPEC_FILE"
    exit 1
fi

echo "Current Valora Version: $CURRENT_VERSION"

# 2. Parse version and build number
# e.g., 1.1.0+2 -> 1.1.0 and 2
VERSION_PART=$(echo $CURRENT_VERSION | cut -d '+' -f 1)
BUILD_PART=$(echo $CURRENT_VERSION | cut -d '+' -f 2)

# Fallback if no + found
if [ "$VERSION_PART" == "$CURRENT_VERSION" ]; then
    BUILD_PART=0
fi

# 3. Increment
NEW_BUILD=$((BUILD_PART + 1))
NEW_VERSION="$VERSION_PART+$NEW_BUILD"

echo "Target Valora Version: $NEW_VERSION"

# 4. Apply update
if [[ "$OSTYPE" == "darwin"* ]]; then
  # MacOS (Local Development)
  sed -i '' "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" $PUBSPEC_FILE
else
  # Linux (GitHub Actions)
  sed -i "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" $PUBSPEC_FILE
fi

# 5. Export to GitHub Environment for subsequent steps
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "version=$NEW_VERSION" >> $GITHUB_OUTPUT
    echo "tag=v$NEW_VERSION" >> $GITHUB_OUTPUT
fi

echo "Version bump successful."
