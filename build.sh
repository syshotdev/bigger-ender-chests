#!/bin/bash
# Two can play at that game, "Wildone"...
# I cast, "AI translate to linux"!

# --- Usage/Help ---
# Build the mod for one or all Minecraft versions.
# Usage: ./build.sh [-v <version>] [-c]
#   -v: Minecraft version (e.g., 1.21.8)
#   -c: Clean before build

MINECRAFT_VERSION=""
CLEAN=false

# Parse arguments
while getopts "v:c" opt; do
  case $opt in
    v) MINECRAFT_VERSION=$OPTARG ;;
    c) CLEAN=true ;;
    *) echo "Usage: $0 [-v minecraft_version] [-c]"; exit 1 ;;
  esac
done

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if versions.json exists
if [ ! -f "versions.json" ]; then
    echo -e "${RED}Error: versions.json not found!${NC}"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. This script requires jq to parse versions.json.${NC}"
    exit 1
fi

# Function to get Gradle version from versions.json
get_gradle_version() {
    local mc_ver=$1
    local g_ver
    g_ver=$(jq -r ".\"$mc_ver\".gradle_version" versions.json)
    echo "$g_ver"
}

# Function to update Gradle wrapper distribution URL
update_gradle_wrapper() {
    local g_ver=$1
    local wrapper_file="gradle/wrapper/gradle-wrapper.properties"

    if [ ! -f "$wrapper_file" ]; then
        echo -e "${RED}Error: gradle-wrapper.properties not found!${NC}"
        return 1
    fi

    local gradle_url="https://services.gradle.org/distributions/gradle-${g_ver}-bin.zip"
    
    # Use sed to replace the distributionUrl line
    # Using comma as a delimiter for sed to avoid escaping slashes in URL
    sed -i "s,distributionUrl=.*,distributionUrl=$gradle_url," "$wrapper_file"
    
    echo -e "${CYAN}Updated Gradle distribution URL to: https://services.gradle.org/distributions/gradle-${g_ver}-bin.zip${NC}"
    return 0
}

# Function to build for a specific Minecraft version
build_for_version() {
    local mc_ver=$1

    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}Building for Minecraft $mc_ver${NC}"
    echo -e "${CYAN}========================================${NC}\n"

    local gradle_ver
    gradle_ver=$(get_gradle_version "$mc_ver")

    if [ "$gradle_ver" == "null" ] || [ -z "$gradle_ver" ]; then
        echo -e "${RED}Error: Could not find gradle_version for Minecraft $mc_ver${NC}"
        return 1
    fi

    # Update Gradle wrapper
    if ! update_gradle_wrapper "$gradle_ver"; then
        return 1
    fi

    # Ensure gradlew is executable
    chmod +x ./gradlew

    # Clean if requested
    if [ "$CLEAN" = true ]; then
        echo -e "${YELLOW}Cleaning build directory...${NC}"
        if ! ./gradlew clean; then
            echo -e "${RED}Error: Clean failed!${NC}"
            return 1
        fi
    fi

    # Build
    echo -e "${YELLOW}Building mod for Minecraft $mc_ver...${NC}"
    if ./gradlew build --no-daemon -Pminecraft_version="$mc_ver"; then
        echo -e "\n${GREEN}✅ Build successful for Minecraft $mc_ver!${NC}"
        echo -e "${GREEN}Artifacts are in: build/libs/${NC}"
        return 0
    else
        echo -e "\n${RED}❌ Build failed for Minecraft $mc_ver!${NC}"
        return 1
    fi
}

# Main execution
echo -e "${CYAN}\n========================================${NC}"
echo -e "${CYAN}Mod Build Script${NC}"
echo -e "${CYAN}========================================\n${NC}"

VERSIONS_TO_BUILD=()

if [ -n "$MINECRAFT_VERSION" ]; then
    # Validate version against allowed set if needed, or just add it
    VERSIONS_TO_BUILD=("$MINECRAFT_VERSION")
    echo -e "${CYAN}Building for Minecraft version: $MINECRAFT_VERSION${NC}"
else
    # Build for all versions found in keys of versions.json
    all_versions=$(jq -r 'keys[]' versions.json)
    readarray -t VERSIONS_TO_BUILD <<< "$all_versions"
    echo -e "${CYAN}Building for all versions: ${VERSIONS_TO_BUILD[*]}${NC}"
fi

SUCCESS_COUNT=0
FAIL_COUNT=0

for ver in "${VERSIONS_TO_BUILD[@]}"; do
    # Skip empty strings
    [ -z "$ver" ] && continue
    
    if build_for_version "$ver"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
done

# Summary
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}Build Summary${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}Successful: $SUCCESS_COUNT${NC}"

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}Failed: $FAIL_COUNT${NC}"
else
    echo -e "${RED}Failed: $FAIL_COUNT${NC}"
fi
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
