#!/bin/bash

# Dependency Installation Helper for exist-db Management Script
# Detects Linux distribution and installs required dependencies

set -e

echo "=================================="
echo "exist-db Manager - Dependency Check"
echo "=================================="
echo ""

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "Cannot detect Linux distribution"
    exit 1
fi

echo "Detected OS: $OS $VER"
echo ""

# Check if screen is installed
if ! command -v screen &> /dev/null; then
    echo "⚠ screen is not installed (required for running exist-db instances)"
    NEED_SCREEN=true
else
    echo "✓ screen is already installed"
    NEED_SCREEN=false
fi
echo ""

# Check if yq is already installed
if command -v yq &> /dev/null; then
    echo "✓ yq is already installed: $(yq --version)"
    NEED_YAML=false
else
    NEED_YAML=true
fi

# Check if Python with PyYAML is available
if command -v python3 &> /dev/null; then
    if python3 -c "import yaml" 2>/dev/null; then
        echo "✓ Python 3 with PyYAML is already installed"
        NEED_YAML=false
    fi
fi

# Exit early if everything is installed
if [ "$NEED_SCREEN" = false ] && [ "$NEED_YAML" = false ]; then
    echo ""
    echo "✓ All dependencies are already installed!"
    exit 0
fi

echo "Installing dependencies..."
echo ""

# Install based on distribution
case $OS in
    ubuntu|debian)
        echo "Installing for Debian/Ubuntu..."
        sudo apt-get update

        if [ "$NEED_SCREEN" = true ]; then
            echo "Installing screen..."
            sudo apt-get install -y screen
        fi

        if [ "$NEED_YAML" = true ]; then
            if command -v snap &> /dev/null; then
                echo "Using snap to install yq..."
                sudo snap install yq
            else
                echo "Installing Python and PyYAML..."
                sudo apt-get install -y python3 python3-pip
                pip3 install pyyaml
            fi
        fi
        ;;

    rhel|centos|fedora)
        echo "Installing for RHEL/CentOS/Fedora..."
        if command -v dnf &> /dev/null; then
            if [ "$NEED_SCREEN" = true ]; then
                echo "Installing screen..."
                sudo dnf install -y screen
            fi

            if [ "$NEED_YAML" = true ]; then
                echo "Attempting to install yq..."
                sudo dnf install -y yq 2>/dev/null || {
                    echo "yq not available in repos, installing Python and PyYAML..."
                    sudo dnf install -y python3 python3-pip
                    pip3 install pyyaml
                }
            fi
        else
            if [ "$NEED_SCREEN" = true ]; then
                echo "Installing screen..."
                sudo yum install -y screen
            fi

            if [ "$NEED_YAML" = true ]; then
                echo "Installing Python and PyYAML..."
                sudo yum install -y python3 python3-pip
                pip3 install pyyaml
            fi
        fi
        ;;

    arch|manjaro)
        echo "Installing for Arch Linux..."
        if [ "$NEED_SCREEN" = true ]; then
            echo "Installing screen..."
            sudo pacman -Sy --noconfirm screen
        fi

        if [ "$NEED_YAML" = true ]; then
            echo "Installing yq..."
            sudo pacman -Sy --noconfirm yq
        fi
        ;;

    *)
        echo "Unsupported distribution: $OS"
        echo "Please install manually:"
        echo "  Option 1: Install yq from https://github.com/mikefarah/yq/releases"
        echo "  Option 2: Install Python 3 and run: pip3 install pyyaml"
        exit 1
        ;;
esac

echo ""
echo "=================================="
echo "Installation complete!"
echo "=================================="
echo ""

# Verify installation
ALL_OK=true

if command -v screen &> /dev/null; then
    echo "✓ screen installed successfully"
else
    echo "✗ screen installation failed"
    ALL_OK=false
fi

if command -v yq &> /dev/null; then
    echo "✓ yq installed successfully: $(yq --version)"
elif python3 -c "import yaml" 2>/dev/null; then
    echo "✓ Python 3 with PyYAML installed successfully"
else
    echo "✗ YAML parser installation failed"
    ALL_OK=false
fi

if [ "$ALL_OK" = false ]; then
    exit 1
fi
