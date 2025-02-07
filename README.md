
# Restic Installer Script

A robust bash script to automatically download and install the latest version of Restic backup tool on Linux systems.

## Features

- Automatic architecture detection (x86_64, i386, ARM, ARM64)
- Downloads the latest stable release from GitHub
- Handles dependencies checking
- Performs installation verification
- Root permission handling
- Clean temporary files management

## Prerequisites

The script requires:

- `curl`  
- `bzip2`
- Root privileges

## What the Script Does

- Checks for root privileges
- Detects system architecture
- Verifies required dependencies
- Downloads the latest Restic release from GitHub
- Extracts and installs Restic to /usr/local/bin
- Verifies the installation

## Supported Architectures

- x86_64 (amd64)
- i386/i686
- armv6l/armv7l
- aarch64 (arm64)

## Error Handling

The script includes comprehensive error handling for:

- Missing dependencies
- Download failures
- Extraction issues
- Installation problems
- Unsupported architectures

## Credits

Created by Ariel S. Weher (ariel [at] weher [dot] net)

## License

MIT License - see the [LICENSE](LICENSE) file for details.
