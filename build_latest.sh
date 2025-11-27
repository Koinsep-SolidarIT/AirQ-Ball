#!/bin/bash

# AirQ-Ball Build Script for macOS
# Automatically extracts version from source code

# Configuration
SKETCH_PATH="AirQ-Ball.ino"
BUILD_PATH="build"
BOARD="esp8266:esp8266:nodemcuv2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}AirQ-Ball Build Script for macOS${NC}"
echo ""

# Check if arduino-cli is installed
if ! command -v arduino-cli &> /dev/null; then
    echo -e "${RED}Error: arduino-cli is not installed.${NC}"
    echo "Please install it using:"
    echo "  brew install arduino-cli"
    echo "Or download from: https://github.com/arduino/arduino-cli"
    exit 1
fi

# Extract version from source code - improved detection
echo "Extracting version from source code..."
VERSION=$(grep -E '^#define VERSION "[0-9]+\.[0-9]+\.[0-9]+"' "$SKETCH_PATH" | head -1 | sed -E 's/^#define VERSION "([0-9]+\.[0-9]+\.[0-9]+)"/\1/')

# If not found, try alternative pattern
if [ -z "$VERSION" ]; then
    VERSION=$(grep -A 5 '^#ifndef VERSION' "$SKETCH_PATH" | grep -E '^#define VERSION' | head -1 | sed -E 's/^#define VERSION "([0-9]+\.[0-9]+\.[0-9]+)"/\1/')
fi

# Debug: Show what was found
echo "Debug - Found version string: '$VERSION'"

# If still not found, search for any VERSION definition
if [ -z "$VERSION" ]; then
    VERSION=$(grep -E 'VERSION "[0-9]+\.[0-9]+\.[0-9]+"' "$SKETCH_PATH" | head -1 | sed -E 's/.*VERSION "([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
fi

# If still not found, use manual extraction
if [ -z "$VERSION" ]; then
    echo -e "${YELLOW}Using manual extraction method...${NC}"
    # Read the file and look for VERSION pattern in context
    while IFS= read -r line; do
        if [[ $line == *"VERSION"* ]]; then
            if [[ $line =~ VERSION\ \"([0-9]+\.[0-9]+\.[0-9]+)\" ]]; then
                VERSION="${BASH_REMATCH[1]}"
                break
            fi
        fi
    done < "$SKETCH_PATH"
fi

# Final fallback
if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Could not extract version from source${NC}"
    echo "Please check your VERSION definition in $SKETCH_PATH"
    exit 1
fi

# Extract BUILD_DATE
BUILD_DATE=$(grep -E '^#define BUILD_DATE' "$SKETCH_PATH" | head -1 | sed -E 's/^#define BUILD_DATE[[:space:]]+//' | sed -E 's/^"//' | sed -E 's/"$//')

# If BUILD_DATE is not found or is __DATE__, use current date
if [ -z "$BUILD_DATE" ] || [ "$BUILD_DATE" = "__DATE__" ]; then
    BUILD_DATE=$(date +'%b %d %Y')
fi

echo "Detected version: $VERSION"
echo "Build date: $BUILD_DATE"

# Set paths based on detected version
LATEST_PATH="$BUILD_PATH/latest"
VERSION_PATH="$BUILD_PATH/AirQ-Ball_v$VERSION"

# Create build directories
echo "Creating build directories..."
mkdir -p "$LATEST_PATH"
mkdir -p "$VERSION_PATH"

# Get current date and time for timestamp
BUILD_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S')
echo "Build timestamp: $BUILD_DATETIME"

# Clean any previous builds in latest directory only
echo "Cleaning previous latest build..."
rm -f "$LATEST_PATH"/*.bin
rm -f "$LATEST_PATH"/version.txt

# Build using arduino-cli directly
echo -e "${YELLOW}Starting build process...${NC}"

# Use verbose output to see what's happening
arduino-cli compile --verbose --fqbn $BOARD --output-dir $LATEST_PATH $SKETCH_PATH

# Check if build was successful
if [ $? -eq 0 ]; then
    # Find the binary file in latest directory
    if ls "$LATEST_PATH/"*.bin 1> /dev/null 2>&1; then
        for binfile in "$LATEST_PATH/"*.bin; do
            if [ -f "$binfile" ]; then
                # Get the original filename
                ORIGINAL_FILENAME=$(basename "$binfile")
                
                echo -e "${GREEN}Build successful!${NC}"
                
                # Create version file for latest
                echo "$VERSION" > "$LATEST_PATH/version.txt"
                echo "Build date: $BUILD_DATE" >> "$LATEST_PATH/version.txt"
                echo "Build timestamp: $BUILD_DATETIME" >> "$LATEST_PATH/version.txt"
                echo "Git commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" >> "$LATEST_PATH/version.txt"
                
                # Rename to latest.bin in latest directory
                mv "$binfile" "$LATEST_PATH/latest.bin"
                
                # Copy to versioned directory with descriptive name
                cp "$LATEST_PATH/latest.bin" "$VERSION_PATH/AirQ-Ball_v${VERSION}_${BUILD_DATETIME}.bin"
                cp "$LATEST_PATH/version.txt" "$VERSION_PATH/version.txt"
                
                # Create a build info file in versioned directory
                echo "AirQ-Ball Firmware Build Information" > "$VERSION_PATH/build_info.txt"
                echo "=====================================" >> "$VERSION_PATH/build_info.txt"
                echo "Version: $VERSION" >> "$VERSION_PATH/build_info.txt"
                echo "Build date: $BUILD_DATE" >> "$VERSION_PATH/build_info.txt"
                echo "Build timestamp: $BUILD_DATETIME" >> "$VERSION_PATH/build_info.txt"
                echo "Git commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" >> "$VERSION_PATH/build_info.txt"
                echo "Original filename: $ORIGINAL_FILENAME" >> "$VERSION_PATH/build_info.txt"
                echo "Target board: $BOARD" >> "$VERSION_PATH/build_info.txt"
                echo "Source file: $SKETCH_PATH" >> "$VERSION_PATH/build_info.txt"
                
                echo ""
                echo -e "${GREEN}Build artifacts created:${NC}"
                echo ""
                echo -e "${BLUE}Latest build (for OTA updates):${NC}"
                echo "  └── latest/"
                echo "      ├── latest.bin"
                echo "      └── version.txt"
                echo ""
                echo -e "${BLUE}Versioned build (for archiving):${NC}"
                echo "  └── AirQ-Ball_v$VERSION/"
                echo "      ├── AirQ-Ball_v${VERSION}_${BUILD_DATETIME}.bin"
                echo "      ├── version.txt"
                echo "      └── build_info.txt"
                echo ""
                echo -e "${GREEN}File sizes:${NC}"
                echo "  latest.bin: $(ls -lh "$LATEST_PATH/latest.bin" | awk '{print $5}')"
                echo "  versioned:  $(ls -lh "$VERSION_PATH/AirQ-Ball_v${VERSION}_${BUILD_DATETIME}.bin" | awk '{print $5}')"
                echo ""
                echo -e "${YELLOW}To deploy to GitHub:${NC}"
                echo "  git add build/"
                echo "  git commit -m \"Build version $VERSION\""
                echo "  git push"
                break
            fi
        done
    else
        echo -e "${RED}Error: No binary file was generated${NC}"
        echo "Checking build directory contents:"
        ls -la "$LATEST_PATH/"
        exit 1
    fi
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Build completed successfully!${NC}"