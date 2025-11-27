#!/bin/bash

# AirQ-Ball Build Script for macOS
# Version: 1.2.6

# Configuration
SKETCH_PATH="AirQ-Ball.ino"
BUILD_PATH="build/latest"
BOARD="esp8266:esp8266:nodemcuv2"
VERSION="1.2.6"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}AirQ-Ball Build Script for macOS${NC}"
echo "Building version: $VERSION"
echo ""

# Check if arduino-cli is installed
if ! command -v arduino-cli &> /dev/null; then
    echo -e "${RED}Error: arduino-cli is not installed.${NC}"
    echo "Please install it using:"
    echo "  brew install arduino-cli"
    echo "Or download from: https://github.com/arduino/arduino-cli"
    exit 1
fi

# Create build directory
echo "Creating build directory..."
mkdir -p $BUILD_PATH

# Get current date
BUILD_DATE=$(date +'%b %d %Y')
echo "Build date: $BUILD_DATE"

# Build using arduino-cli directly (no temporary file modification)
echo -e "${YELLOW}Starting build process...${NC}"

# Build using arduino-cli
arduino-cli compile --fqbn $BOARD --output-dir $BUILD_PATH $SKETCH_PATH

# Check if build was successful
if [ $? -eq 0 ]; then
    # Rename the output file to latest.bin
    if ls "$BUILD_PATH/"*.bin 1> /dev/null 2>&1; then
        for binfile in "$BUILD_PATH/"*.bin; do
            mv "$binfile" "$BUILD_PATH/latest.bin"
            break
        done
        
        echo -e "${GREEN}Build successful!${NC}"
        
        # Create version file
        echo "$VERSION" > "$BUILD_PATH/version.txt"
        echo "Build date: $BUILD_DATE" >> "$BUILD_PATH/version.txt"
        echo "Git commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" >> "$BUILD_PATH/version.txt"
        
        echo ""
        echo -e "${GREEN}Build artifacts:${NC}"
        echo "  Firmware: $BUILD_PATH/latest.bin"
        echo "  Version:  $BUILD_PATH/version.txt"
        echo ""
        echo -e "${YELLOW}To deploy to GitHub:${NC}"
        echo "  git add build/latest/"
        echo "  git commit -m \"Build version $VERSION\""
        echo "  git push"
    else
        echo -e "${RED}Error: No binary file was generated${NC}"
        exit 1
    fi
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Build completed successfully!${NC}"