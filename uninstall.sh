#!/bin/bash

# WiFi Auto Auth Uninstallation Script
# This script removes WiFi Auto Auth service and cleans up

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================"
echo "WiFi Auto Auth Uninstallation Script"
echo "========================================"
echo

# Get the current script directory
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Installation directory: $INSTALL_DIR"
echo

# Confirm uninstallation
read -p "Are you sure you want to uninstall WiFi Auto Auth? This will remove all cron jobs and configurations. (Y/N): " CONFIRM
if [[ "${CONFIRM,,}" != "y" ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo
echo "Starting uninstallation..."
echo

# Remove cron jobs
echo "========================================"
echo "Removing Cron Jobs"
echo "========================================"
echo

# Check if cron job exists and remove it
if crontab -l 2>/dev/null | grep -q "$INSTALL_DIR/wifi_auto_auth_cron.sh"; then
    # Remove the specific cron job
    crontab -l 2>/dev/null | grep -v "$INSTALL_DIR/wifi_auto_auth_cron.sh" | crontab -
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}[OK] Removed cron job${NC}"
    else
        echo -e "${RED}[WARNING] Failed to remove cron job${NC}"
    fi
else
    echo -e "${YELLOW}[SKIP] Cron job not found${NC}"
fi

# Remove NetworkManager dispatcher script (if exists and running as root)
if [[ -f "/etc/NetworkManager/dispatcher.d/99-wifi-auto-auth" ]]; then
    if [[ $EUID -eq 0 ]]; then
        rm -f "/etc/NetworkManager/dispatcher.d/99-wifi-auto-auth"
        echo -e "${GREEN}[OK] Removed NetworkManager dispatcher script${NC}"
    else
        echo -e "${YELLOW}[WARNING] Need root privileges to remove NetworkManager dispatcher script${NC}"
        echo "Run: sudo rm -f /etc/NetworkManager/dispatcher.d/99-wifi-auto-auth"
    fi
else
    echo -e "${YELLOW}[SKIP] NetworkManager dispatcher script not found${NC}"
fi

# Remove cron wrapper script
if [[ -f "$INSTALL_DIR/wifi_auto_auth_cron.sh" ]]; then
    rm -f "$INSTALL_DIR/wifi_auto_auth_cron.sh"
    echo -e "${GREEN}[OK] Removed cron wrapper script${NC}"
else
    echo -e "${YELLOW}[SKIP] Cron wrapper script not found${NC}"
fi

echo

# Ask about removing configuration and data
echo "========================================"
echo "Data Removal Options"
echo "========================================"
echo

read -p "Do you want to remove configuration files (contains WiFi credentials)? (Y/N): " REMOVE_CONFIG
read -p "Do you want to remove log files? (Y/N): " REMOVE_LOGS
read -p "Do you want to remove data directory? (Y/N): " REMOVE_DATA
echo

if [[ "${REMOVE_CONFIG,,}" == "y" ]]; then
    if [[ -d "$INSTALL_DIR/config" ]]; then
        rm -rf "$INSTALL_DIR/config"
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[OK] Removed config directory${NC}"
        else
            echo -e "${RED}[WARNING] Failed to remove config directory${NC}"
        fi
    else
        echo -e "${YELLOW}[SKIP] Config directory not found${NC}"
    fi
else
    echo -e "${BLUE}[SKIP] Keeping configuration files${NC}"
fi

if [[ "${REMOVE_LOGS,,}" == "y" ]]; then
    if [[ -d "$INSTALL_DIR/logs" ]]; then
        rm -rf "$INSTALL_DIR/logs"
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[OK] Removed logs directory${NC}"
        else
            echo -e "${RED}[WARNING] Failed to remove logs directory${NC}"
        fi
    else
        echo -e "${YELLOW}[SKIP] Logs directory not found${NC}"
    fi
else
    echo -e "${BLUE}[SKIP] Keeping log files${NC}"
fi

if [[ "${REMOVE_DATA,,}" == "y" ]]; then
    if [[ -d "$INSTALL_DIR/data" ]]; then
        rm -rf "$INSTALL_DIR/data"
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[OK] Removed data directory${NC}"
        else
            echo -e "${RED}[WARNING] Failed to remove data directory${NC}"
        fi
    else
        echo -e "${YELLOW}[SKIP] Data directory not found${NC}"
    fi
else
    echo -e "${BLUE}[SKIP] Keeping data directory${NC}"
fi

echo

# Ask about uninstalling Python packages
echo "========================================"
echo "Python Packages"
echo "========================================"
echo

read -p "Do you want to uninstall Python packages installed by WiFi Auto Auth? (Y/N): " REMOVE_PACKAGES
if [[ "${REMOVE_PACKAGES,,}" == "y" ]]; then
    if [[ -f "$INSTALL_DIR/requirements.txt" ]]; then
        echo "Uninstalling Python packages..."
        if pip3 uninstall -r "$INSTALL_DIR/requirements.txt" -y > /dev/null 2>&1; then
            echo -e "${GREEN}[OK] Python packages uninstalled${NC}"
        else
            echo -e "${YELLOW}[WARNING] Some packages may not have been uninstalled${NC}"
        fi
    else
        echo -e "${YELLOW}[WARNING] requirements.txt not found, skipping package uninstallation${NC}"
    fi
else
    echo -e "${BLUE}[SKIP] Keeping Python packages (may be used by other programs)${NC}"
fi

echo

# Final summary
echo "========================================"
echo -e "${GREEN}Uninstallation Complete!${NC}"
echo "========================================"
echo
echo "Summary of actions taken:"
echo "- Cron jobs and automated tasks removed"

if [[ "${REMOVE_CONFIG,,}" == "y" ]]; then
    echo "- Configuration files removed"
else
    echo "- Configuration files kept"
fi

if [[ "${REMOVE_LOGS,,}" == "y" ]]; then
    echo "- Log files removed"
else
    echo "- Log files kept"
fi

if [[ "${REMOVE_DATA,,}" == "y" ]]; then
    echo "- Data directory removed"
else
    echo "- Data directory kept"
fi

if [[ "${REMOVE_PACKAGES,,}" == "y" ]]; then
    echo "- Python packages uninstalled"
else
    echo "- Python packages kept"
fi

echo
echo "The main program files remain in: $INSTALL_DIR"
echo "You can manually delete this directory if desired:"
echo "  rm -rf "$INSTALL_DIR""
echo
echo -e "${BLUE}Thank you for using WiFi Auto Auth!${NC}"
echo
