# 🔧 **WiFi Auto Auth - Detailed Setup Guide**

This guide provides comprehensive setup instructions for WiFi Auto Auth. For a quick automated installation, use the installation scripts (`install.bat` for Windows or `install.sh` for Linux/macOS).

---

## 🎯 **Installation Methods**

### **Method 1: Automated Installation (Recommended)**

The easiest way to install WiFi Auto Auth is using the provided installation scripts.

#### **Windows**
1. Download or clone the repository
2. Open Command Prompt as Administrator
3. Navigate to the project directory
4. Run the installation script:
   ```cmd
   install.bat
   ```

#### **Linux/macOS**
1. Download or clone the repository
2. Open terminal in the project directory
3. Make the script executable and run:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

**The automated installation will:**
- ✅ Check Python 3.x installation
- ✅ Install pip if not available (`python -m ensurepip --upgrade`)
- ✅ Install required dependencies from `requirements.txt`
- ✅ Create necessary directories (`config/`, `logs/`, `data/`)
- ✅ Set up interactive configuration
- ✅ Configure automatic execution on startup/network changes
- ✅ Set proper file permissions for security

---

## **Method 2: Manual Installation**

### **1. Prerequisites**

Ensure you have the following installed:

#### **Python 3.6 or Higher**
- **Windows**: Download from [python.org](https://www.python.org/downloads/)
- **Ubuntu/Debian**: `sudo apt update && sudo apt install python3 python3-pip`
- **CentOS/RHEL**: `sudo yum install python3 python3-pip`
- **Fedora**: `sudo dnf install python3 python3-pip`
- **Arch Linux**: `sudo pacman -S python python-pip`
- **macOS**: `brew install python3` (requires Homebrew)

#### **Verify Installation**
```bash
python --version  # or python3 --version
pip --version     # or pip3 --version
```

### **2. Install Dependencies**

Navigate to the project directory and install required Python packages:

```bash
# Using pip
pip install -r requirements.txt

# Or using pip3 (if you have both Python 2 and 3)
pip3 install -r requirements.txt

# Manual installation if requirements.txt is missing
pip install requests>=2.25.0
```

#### **If pip is not installed:**
```bash
# Install pip using ensurepip
python -m ensurepip --upgrade

# Or download and install get-pip.py
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py
```

### **3. Create Directory Structure**

Create the necessary directories for the application:

```bash
# Windows
mkdir config logs data

# Linux/macOS
mkdir -p config logs data
```

### **4. Find Your Network's Authentication Details**

#### **Step 4.1: Connect to WiFi Manually**
Connect to your WiFi network using the normal method (this usually redirects you to a login page).

#### **Step 4.2: Inspect the Login Process**
1. Open your browser's Developer Tools (F12 or Right-click → Inspect)
2. Go to the **Network** tab
3. Clear any existing network requests
4. Enter your credentials and submit the login form
5. Look for the POST request (usually to a URL like `http://192.168.x.x:8090/login.xml`)

#### **Step 4.3: Extract Required Information**
From the network request, identify:
- **Login URL**: The endpoint where credentials are submitted
- **Request Method**: Usually POST
- **Form Data**: Parameters like username, password, mode, etc.
- **Headers**: Any special headers required

**Example of what to look for:**
```
POST http://192.168.100.1:8090/login.xml
Form Data:
  mode: 191
  username: your_username
  password: your_password
  a: 1634567890  # This might be dynamic
  producttype: 0
```

### **5. Configure the Application**

Create a configuration file at `config/config.json`:

```json
{
    "wifi": {
        "ssid": "YourNetworkName",
        "username": "your_username",
        "password": "your_password"
    },
    "portal": {
        "url": "http://192.168.100.1:8090/login.xml",
        "timeout": 30,
        "method": "POST",
        "headers": {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        }
    },
    "payload_params": {
        "mode": "191",
        "username": "your_username",
        "password": "your_password",
        "a": "dynamic",
        "producttype": "0"
    },
    "logging": {
        "enabled": true,
        "log_file": "logs/wifi_auto_auth.log",
        "level": "INFO",
        "max_file_size": "10MB",
        "backup_count": 5
    },
    "database": {
        "name": "data/wifi_log.db",
        "cleanup_days": 30
    },
    "network": {
        "check_interval": 30,
        "max_retries": 3,
        "retry_delay": 5
    }
}
```

**Important Notes:**
- **Dynamic Parameters**: If a parameter (like `a`) changes with each request, set it to `"dynamic"`
- **SSID**: Must match your WiFi network name exactly
- **Credentials**: Use your actual network username and password
- **URL**: Must be the exact login endpoint discovered in step 4

### **6. Set File Permissions (Linux/macOS)**

Secure your configuration files:

```bash
# Make config directory accessible only to current user
chmod 700 config/

# Set appropriate permissions for log directory
chmod 755 logs/

# Make the main script executable
chmod +x wifi_auto_auth.py
```

### **7. Test the Configuration**

Run the script manually to test your configuration:

```bash
python wifi_auto_auth.py
# or
python3 wifi_auto_auth.py
```

**Expected output:**
```
[INFO] Starting WiFi Auto Auth...
[INFO] Connected to SSID: YourNetworkName
[INFO] Attempting login to portal...
[INFO] Login successful!
[INFO] Internet connectivity verified
```

---

## **8. Set Up Automatic Execution**

### **🪟 Windows - Task Scheduler**

#### **Method 1: Using GUI**
1. Press `Win + R`, type `taskschd.msc`, press Enter
2. Click **"Create Basic Task..."** in the right panel
3. **Name**: "WiFi Auto Auth"
4. **Trigger**: "When the computer starts"
5. **Action**: "Start a program"
6. **Program**: `python` (or full path to python.exe)
7. **Arguments**: `"C:\full\path\to\wifi_auto_auth.py"`
8. **Start in**: `C:\full\path\to\project\directory`
9. Check **"Run with highest privileges"**

#### **Method 2: Using Command Line**
```cmd
schtasks /create /tn "WiFiAutoAuth" /tr "python "C:\path\to\wifi_auto_auth.py"" /sc onlogon /rl highest
```

#### **Network Event Trigger (Advanced)**
```cmd
schtasks /create /tn "WiFiAutoAuthNetwork" /tr "python "C:\path\to\wifi_auto_auth.py"" /sc onevent /ec System /mo "*[System/Provider/@Name='Microsoft-Windows-NetworkProfile']" /rl highest
```

### **🐧 Linux - Cron Jobs**

#### **Basic Cron Setup**
```bash
# Edit crontab
crontab -e

# Add this line to run on startup
@reboot /usr/bin/python3 /full/path/to/wifi_auto_auth.py

# Or run every 5 minutes
*/5 * * * * /usr/bin/python3 /full/path/to/wifi_auto_auth.py
```

#### **NetworkManager Integration**
Create a dispatcher script for automatic network change detection:

```bash
# Create the dispatcher script
sudo nano /etc/NetworkManager/dispatcher.d/99-wifi-auto-auth

# Add this content:
#!/bin/bash
if [[ "$2" == "up" ]] && [[ "$1" == *"wl"* ]]; then
    sleep 5
    /usr/bin/python3 /full/path/to/wifi_auto_auth.py
fi

# Make it executable
sudo chmod +x /etc/NetworkManager/dispatcher.d/99-wifi-auto-auth
```

#### **Systemd Service (Alternative)**
Create a systemd service for more control:

```bash
# Create service file
sudo nano /etc/systemd/system/wifi-auto-auth.service

# Add content:
[Unit]
Description=WiFi Auto Auth Service
After=network.target

[Service]
Type=simple
User=your_username
WorkingDirectory=/path/to/wifi-auto-auth
ExecStart=/usr/bin/python3 /path/to/wifi-auto-auth/wifi_auto_auth.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable wifi-auto-auth.service
sudo systemctl start wifi-auto-auth.service
```

### **🍎 macOS - Launch Agents**

#### **Create Launch Agent**
```bash
# Create the plist file
nano ~/Library/LaunchAgents/com.wifiauth.plist

# Add this content:
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.wifiauth</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/full/path/to/wifi_auto_auth.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/full/path/to/project/directory</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/full/path/to/logs/error.log</string>
    <key>StandardOutPath</key>
    <string>/full/path/to/logs/output.log</string>
</dict>
</plist>

# Load the launch agent
launchctl load ~/Library/LaunchAgents/com.wifiauth.plist

# Start the service
launchctl start com.wifiauth
```

---

## **🔧 Advanced Configuration**

### **Multiple Network Support**
```json
{
    "networks": [
        {
            "ssid": "Network1",
            "username": "user1",
            "password": "pass1",
            "portal": {
                "url": "http://192.168.1.1:8090/login.xml",
                "payload": {
                    "mode": "191",
                    "producttype": "0"
                }
            }
        },
        {
            "ssid": "Network2",
            "username": "user2",
            "password": "pass2",
            "portal": {
                "url": "http://10.0.0.1/login",
                "payload": {
                    "action": "login"
                }
            }
        }
    ]
}
```

### **Proxy Support**
```json
{
    "proxy": {
        "enabled": true,
        "http": "http://proxy.example.com:8080",
        "https": "http://proxy.example.com:8080",
        "username": "proxy_user",
        "password": "proxy_pass"
    }
}
```

### **Custom Headers and User Agents**
```json
{
    "portal": {
        "headers": {
            "User-Agent": "CustomWiFiClient/1.0",
            "Referer": "http://192.168.1.1:8090/",
            "X-Custom-Header": "value"
        }
    }
}
```

---

## **📊 Monitoring and Logs**

### **Log Locations**
- **Application Logs**: `logs/wifi_auto_auth.log`
- **Error Logs**: `logs/error.log`
- **Database**: `data/wifi_log.db`

### **Log Analysis**
```bash
# View recent logs
tail -f logs/wifi_auto_auth.log

# Search for errors
grep -i "error" logs/wifi_auto_auth.log

# Check database entries
sqlite3 data/wifi_log.db "SELECT * FROM login_attempts ORDER BY timestamp DESC LIMIT 10;"
```

### **Log Rotation**
The application automatically rotates logs based on size and keeps a configurable number of backup files.

---

## **🚨 Troubleshooting**

### **Common Issues and Solutions**

#### **1. Python Not Found**
```bash
# Check Python installation
which python3
python3 --version

# Add to PATH (Linux/macOS)
export PATH="/usr/bin/python3:$PATH"

# Windows: Add Python to System PATH via Environment Variables
```

#### **2. Permission Denied**
```bash
# Linux/macOS
chmod +x wifi_auto_auth.py
chmod 700 config/

# Windows: Run Command Prompt as Administrator
```

#### **3. Login Fails**
- Verify network credentials
- Check portal URL and parameters
- Review network inspection results
- Test manual login in browser

#### **4. Network Not Detected**
- Verify SSID spelling in configuration
- Check WiFi adapter drivers
- Test network connectivity

#### **5. Automatic Execution Not Working**
- Verify task/cron job creation
- Check script paths and permissions
- Review system logs for errors

### **Debug Mode**
Enable debug logging by setting log level to "DEBUG" in config:

```json
{
    "logging": {
        "level": "DEBUG"
    }
}
```

### **Manual Testing**
```bash
# Test with verbose output
python wifi_auto_auth.py --verbose

# Test configuration only
python wifi_auto_auth.py --test-config

# Test network connectivity
python wifi_auto_auth.py --test-network
```

---

## **🔄 Updates and Maintenance**

### **Updating the Application**
```bash
# Pull latest changes
git pull origin main

# Update dependencies
pip install -r requirements.txt --upgrade

# Restart automated services if needed
```

### **Database Maintenance**
```bash
# Clean old logs (if not automated)
python wifi_auto_auth.py --cleanup

# Backup database
cp data/wifi_log.db data/wifi_log_backup.db
```

---

## **🗑️ Uninstallation**

### **Automated Uninstallation**
```bash
# Windows
uninstall.bat

# Linux/macOS
./uninstall.sh
```

### **Manual Uninstallation**

#### **Remove Automation**
```bash
# Windows: Delete scheduled tasks
schtasks /delete /tn "WiFiAutoAuth" /f

# Linux: Remove cron jobs
crontab -e  # Remove the relevant lines

# macOS: Remove launch agent
launchctl unload ~/Library/LaunchAgents/com.wifiauth.plist
rm ~/Library/LaunchAgents/com.wifiauth.plist
```

#### **Remove Files**
```bash
# Remove project directory
rm -rf /path/to/wifi-auto-auth

# Remove Python packages (optional)
pip uninstall requests
```

---

**🎉 Congratulations!** Your WiFi Auto Auth is now set up and ready to provide seamless network connectivity!

For additional help, please check the [main README](README.md) or [open an issue](https://github.com/01bps/WiFi-Auto-Auth/issues) on GitHub.
