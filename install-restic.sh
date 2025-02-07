#!/bin/bash
# Hecho por Ariel S. Weher
# ariel [at] weher [dot] net

set -euo pipefail

# Check if we are root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please run with sudo."
    exit 1
fi

# Check system architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        RESTIC_ARCH="amd64"
        ;;
    i386|i686)
        RESTIC_ARCH="386"
        ;;
    armv6l|armv7l)
        RESTIC_ARCH="arm"
        ;;
    aarch64)
        RESTIC_ARCH="arm64"
        ;;
    *)
        echo "Not supported architecture: $ARCH"
        exit 1
        ;;
esac

# Check required command dependencies
for cmd in curl bunzip2 file; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "Error: $cmd is not installed."
        echo "Install with: sudo apt install $([[ $cmd == "bunzip2" ]] && echo "bzip2" || echo "$cmd")"
        exit 1
    fi
done

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Obtener última versión
echo "Getting latest version information..."
GITHUB_API_RESPONSE=$(curl -sS https://api.github.com/repos/restic/restic/releases/latest)
if [ -z "$GITHUB_API_RESPONSE" ]; then
    echo "Error: Unable to get GitHub API response"
    exit 1
fi

RESTIC_TAG_LATEST=$(echo "$GITHUB_API_RESPONSE" | grep -Po '"tag_name": "\Kv.*?(?=")')
if [ -z "$RESTIC_TAG_LATEST" ]; then
    echo "Error: Unable to get latest version from GitHub"
    echo "GitHub API response:"
    echo "$GITHUB_API_RESPONSE"
    exit 1
fi

# Extract the version number without the initial 'v' for the filename
VERSION_NUMBER=${RESTIC_TAG_LATEST#v}

# Build URL using the correct format
URL="https://github.com/restic/restic/releases/download/${RESTIC_TAG_LATEST}/restic_${VERSION_NUMBER}_linux_${RESTIC_ARCH}.bz2"
TEMP_FILE="$TEMP_DIR/restic.bz2"

echo "Downloading Restic ${RESTIC_TAG_LATEST} for ${RESTIC_ARCH} architecture..."
echo "URL: $URL"

# Download with HTTP status code check and progress bar
HTTP_RESPONSE=$(curl -L --write-out "%{http_code}" --progress-bar --output "$TEMP_FILE" "$URL")
if [ "$HTTP_RESPONSE" != "200" ]; then
    echo "Error: Download failed with HTTP status code $HTTP_RESPONSE"
    echo "Please check the URL: $URL"
    exit 1
fi

# Check if the file exists and is not empty
if [ ! -s "$TEMP_FILE" ]; then
    echo "Error: Downloaded file is empty"
    exit 1
fi

# Check file type
FILE_TYPE=$(file -b "$TEMP_FILE")
echo "Downloaded file type: $FILE_TYPE"

if ! file "$TEMP_FILE" | grep -q "bzip2"; then
    echo "Error: Downloaded file is not a valid bzip2 file"
    echo "Contents of temporary directory:"
    ls -l "$TEMP_DIR"
    exit 1
fi

# Decompress with verification
echo "Decompressing..."
if ! bunzip2 -c "$TEMP_FILE" > "$TEMP_DIR/restic"; then
    echo "Error: Decompression failed"
    exit 1
fi

# Check if the decompressed file is an executable
if ! file "$TEMP_DIR/restic" | grep -q "executable"; then
    echo "Error: Decompressed file is not a valid executable"
    echo "File type: $(file "$TEMP_DIR/restic")"
    exit 1
fi

# Install
if ! mv "$TEMP_DIR/restic" /usr/local/bin/restic; then
    echo "Error: Could not move file to /usr/local/bin/"
    exit 1
fi

chmod 0755 /usr/local/bin/restic

# Verify installation
if command -v restic >/dev/null 2>&1; then
    echo -e "\nInstallation completed successfully!"
    restic version
else
    echo "Error: Installation failed"
    exit 1
fi