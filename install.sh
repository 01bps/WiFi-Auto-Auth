#!/bin/bash

# WiFi Auto Auth Installation Script
# This script installs and configures WiFi Auto Auth service

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root (for system-wide installation)
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${YELLOW}Warning: Running as root. This will install system-wide.${NC}"
        return 0
    else
        echo -e "${BLUE}Running as regular user. Installing to user directory.${NC}"
        return 1
    fi
}

echo "========================================"
echo "WiFi Auto Auth Installation Script"
echo "========================================"
echo

# Get the current script directory
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Installation directory: $INSTALL_DIR"
echo

# Check if Python 3.x is installed
echo "Checking for Python 3.x installation..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}ERROR: Python 3 is not installed${NC}"
    echo "Please install Python 3.x using your package manager:"
    echo "  Ubuntu/Debian: sudo apt update && sudo apt install python3 python3-pip"
    echo "  CentOS/RHEL: sudo yum install python3 python3-pip"
    echo "  Fedora: sudo dnf install python3 python3-pip"
    echo "  Arch Linux: sudo pacman -S python python-pip"
    echo "  macOS: brew install python3"
    exit 1
fi

# Get Python version
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)

if [[ $PYTHON_MAJOR -lt 3 ]]; then
    echo -e "${RED}ERROR: Python 3.x or higher is required. Found Python $PYTHON_VERSION${NC}"
    exit 1
fi

echo -e "${GREEN}Python $PYTHON_VERSION detected successfully${NC}"
echo

# Check if pip3 is available
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}ERROR: pip3 is not installed${NC}"
    echo "Please install pip3 using your package manager"
    exit 1
fi

# Install required Python packages from requirements.txt
echo "Installing required Python packages from requirements.txt..."
if [[ -f "$INSTALL_DIR/requirements.txt" ]]; then
    if pip3 install -r "$INSTALL_DIR/requirements.txt"; then
        echo -e "${GREEN}Python packages installed successfully${NC}"
    else
        echo -e "${RED}ERROR: Failed to install packages from requirements.txt${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Warning: requirements.txt not found, skipping package installation${NC}"
fi
echo

# Create necessary directories
echo "Creating necessary directories..."
for dir in config logs data; do
    if [[ ! -d "$INSTALL_DIR/$dir" ]]; then
        mkdir -p "$INSTALL_DIR/$dir"
        echo -e "${GREEN}Created $dir directory${NC}"
    else
        echo -e "${YELLOW}$dir directory already exists${NC}"
    fi
done
echo

# Interactive configuration setup
echo "========================================"
echo "Configuration Setup"
echo "========================================"
echo

read -p "Enter WiFi SSID (network name): " WIFI_SSID
read -p "Enter WiFi username/ID: " WIFI_USERNAME
read -s -p "Enter WiFi password: " WIFI_PASSWORD
echo
read -p "Enter authentication portal URL: " PORTAL_URL
echo

echo "Creating configuration file..."
# Create config.json file
cat > "$INSTALL_DIR/config/config.json" << EOF
{
    "wifi": {
        "ssid": "$WIFI_SSID",
        "username": "$WIFI_USERNAME",
        "password": "$WIFI_PASSWORD"
    },
    "portal": {
        "url": "$PORTAL_URL",
        "timeout": 30
    },
    "logging": {
        "enabled": true,
        "log_file": "logs/wifi_auto_auth.log",
        "level": "INFO"
    }
}
EOF

echo -e "${GREEN}Configuration file created at: $INSTALL_DIR/config/config.json${NC}"
echo

# Set up cron job (Linux equivalent of scheduled task)
echo "========================================"
echo "Cron Job Setup"
echo "========================================"
echo

read -p "Do you want to set up automatic execution on network changes? (Y/N): " SETUP_CRON
if [[ "${SETUP_CRON,,}" == "y" ]]; then
    echo
    echo "Setting up cron job..."

    # Create a wrapper script for cron
    cat > "$INSTALL_DIR/wifi_auto_auth_cron.sh" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
python3 "$INSTALL_DIR/wifi_auto_auth.py" >> "$INSTALL_DIR/logs/cron.log" 2>&1
EOF

    chmod +x "$INSTALL_DIR/wifi_auto_auth_cron.sh"

    # Add cron job to run every 5 minutes (user can modify as needed)
    CRON_JOB="*/5 * * * * $INSTALL_DIR/wifi_auto_auth_cron.sh"

    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$INSTALL_DIR/wifi_auto_auth_cron.sh"; then
        echo -e "${YELLOW}Cron job already exists${NC}"
    else
        # Add the cron job
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[OK] Cron job created successfully (runs every 5 minutes)${NC}"
        else
            echo -e "${RED}[WARNING] Failed to create cron job${NC}"
        fi
    fi

    # For NetworkManager systems, also set up a dispatcher script
    if command -v nmcli &> /dev/null && check_root; then
        echo "Setting up NetworkManager dispatcher..."
        cat > "/etc/NetworkManager/dispatcher.d/99-wifi-auto-auth" << 'EOF'
#!/bin/bash
if [[ "$2" == "up" ]] && [[ "$1" == *"wl"* ]]; then
    sleep 5
    $INSTALL_DIR/wifi_auto_auth_cron.sh
fi
EOF
        chmod +x "/etc/NetworkManager/dispatcher.d/99-wifi-auto-auth"
        echo -e "${GREEN}[OK] NetworkManager dispatcher script created${NC}"
    fi

    echo
    echo "Cron job and network monitoring have been configured."
else
    echo "Skipping cron job setup."
    echo "You can manually run: python3 wifi_auto_auth.py"
fi
echo

# Set proper file permissions
echo "========================================"
echo "Setting File Permissions"
echo "========================================"
echo

# Set restrictive permissions on config directory
if chmod 700 "$INSTALL_DIR/config" 2>/dev/null; then
    echo -e "${GREEN}[OK] Config directory permissions set (accessible only by current user)${NC}"
else
    echo -e "${YELLOW}[WARNING] Could not set restrictive permissions on config directory${NC}"
fi

# Set permissions on logs directory
if chmod 755 "$INSTALL_DIR/logs" 2>/dev/null; then
    echo -e "${GREEN}[OK] Logs directory permissions set${NC}"
else
    echo -e "${YELLOW}[WARNING] Could not set permissions on logs directory${NC}"
fi

# Make main script executable
if [[ -f "$INSTALL_DIR/wifi_auto_auth.py" ]]; then
    chmod +x "$INSTALL_DIR/wifi_auto_auth.py"
    echo -e "${GREEN}[OK] Main script made executable${NC}"
fi

echo

# Final summary
echo "========================================"
echo -e "${GREEN}Installation Complete!${NC}"
echo "========================================"
echo
echo "Summary:"
echo "- Python $PYTHON_VERSION verified"
echo "- Required packages installed"
echo "- Directories created: config, logs, data"
echo "- Configuration file created"
echo "- File permissions configured"
if [[ "${SETUP_CRON,,}" == "y" ]]; then
    echo "- Cron job configured"
fi
echo
echo "Installation directory: $INSTALL_DIR"
echo "Configuration file: $INSTALL_DIR/config/config.json"
echo "Log file: $INSTALL_DIR/logs/wifi_auto_auth.log"
echo
echo "Next steps:"
echo "1. Review configuration in config/config.json"
echo "2. Test the script: python3 wifi_auto_auth.py"
if [[ "${SETUP_CRON,,}" != "y" ]]; then
    echo "3. Run install.sh again to set up cron job"
fi
echo
echo "To uninstall, run: ./uninstall.sh"
echo
