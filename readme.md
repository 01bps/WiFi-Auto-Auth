# **WiFi Auto Auth** 🔐

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.6+-brightgreen.svg)](https://python.org)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](#installation)

**Tired of entering the same Wi-Fi credentials every time you join the network?** 
This script automatically logs into Wi-Fi networks using pre-saved credentials and now comes with **SQLite integration** to store login attempts and all payload parameters. It keeps track of all login activities, captures dynamic session parameters, and provides a user-friendly log display for debugging.

**Ideal for schools, workplaces, or any location with recurring Wi-Fi logins**, this script eliminates manual re-authentication and ensures effortless connectivity. It's fully customizable, works across different networks, and can be automated on startup for a seamless experience.

## ✨ **Features**

- 🚀 **One-Command Installation** - Automated setup scripts for all platforms
- 🔄 **Automatic Re-authentication** - Monitors network status and logs in when needed
- 💾 **SQLite Database Integration** - Stores login attempts and session data
- 🔒 **Secure Credential Storage** - Encrypted password storage with secure file permissions
- 📊 **Comprehensive Logging** - Detailed logs with automatic cleanup
- 🌐 **Cross-Platform Support** - Works on Windows, Linux, and macOS
- ⚡ **Network Change Detection** - Automatically triggers on network state changes
- 🎯 **Dynamic Parameter Handling** - Supports networks with changing session tokens
- 📱 **Multiple Network Support** - Configure for different WiFi networks
- 🛡️ **Security Focused** - Passwords masked in logs, restrictive file permissions

## 🚀 **Quick Installation**

### **Option 1: Automated Installation (Recommended)**

#### Windows
```cmd
# Download the repository and run:
install.bat
```

#### Linux/macOS
```bash
# Download the repository and run:
chmod +x install.sh
./install.sh
```

The installation scripts will:
- ✅ Check Python 3.x installation
- ✅ Install required dependencies
- ✅ Create necessary directories with proper permissions
- ✅ Set up interactive configuration
- ✅ Configure automatic execution (scheduled tasks/cron jobs)
- ✅ Set up network change monitoring

### **Option 2: Manual Installation**

For detailed step-by-step manual setup instructions, please refer to **[setup.md](setup.md)**

## 🔧 **Configuration**

After installation, the script creates a configuration file at:
- **Windows**: `config\config.json`
- **Linux/macOS**: `config/config.json`

### **Example Configuration**
```json
{
    "wifi": {
        "ssid": "YourNetworkName",
        "username": "your_username",
        "password": "your_password"
    },
    "portal": {
        "url": "http://192.168.100.1:8090/login.xml",
        "timeout": 30
    },
    "logging": {
        "enabled": true,
        "log_file": "logs/wifi_auto_auth.log",
        "level": "INFO"
    }
}
```

## 🏃‍♂️ **Usage**

### **Manual Execution**
```bash
# Test the script manually
python wifi_auto_auth.py
# or
python3 wifi_auto_auth.py
```

### **Automatic Execution**
The installation script configures automatic execution:

- **Windows**: Uses Task Scheduler for startup and network change events
- **Linux**: Uses cron jobs and NetworkManager dispatcher scripts
- **macOS**: Uses Launch Agents for system startup

### **Logs and Monitoring**
- View logs in the `logs/` directory
- SQLite database stores detailed connection history
- All sensitive information is masked in logs for security

## 🗂️ **Project Structure**

```
WiFi-Auto-Auth/
├── 📜 wifi_auto_auth.py      # Main script
├── 📦 requirements.txt       # Python dependencies
├── 🪟 install.bat           # Windows installation script
├── 🐧 install.sh            # Linux/macOS installation script
├── 🪟 uninstall.bat         # Windows uninstallation script
├── 🐧 uninstall.sh          # Linux/macOS uninstallation script
├── 📁 config/               # Configuration directory
│   └── config.json          # Main configuration file
├── 📁 logs/                 # Log files directory
│   └── wifi_auto_auth.log   # Application logs
├── 📁 data/                 # SQLite database directory
│   └── wifi_log.db          # Connection history database
├── 📖 README.md             # This file
├── 🔧 setup.md              # Detailed setup instructions
└── 📄 LICENSE               # MIT License
```

## 🔒 **Security Notes**

- ✅ **Secure Storage**: Credentials are stored with restrictive file permissions
- ✅ **Encrypted Logs**: Passwords are masked in all log outputs
- ✅ **Local Only**: No data transmitted except during legitimate login requests
- ✅ **Automatic Cleanup**: Old logs are automatically cleaned up after system reboot
- ✅ **Permission Control**: Configuration directory accessible only by current user
- ✅ **HTTPS Support**: Compatible with both HTTP and HTTPS authentication portals

## 🛠️ **System Requirements**

- **Python**: 3.6 or higher
- **Operating System**: Windows 10+, Linux (most distributions), macOS 10.12+
- **Network**: WiFi adapter with driver support
- **Permissions**: Administrator/sudo access for installation (optional for user-mode)

## 📋 **Dependencies**

The script automatically installs these Python packages:
```
requests>=2.25.0
sqlite3 (built-in)
json (built-in)
logging (built-in)
```

## ⚠️ **Troubleshooting**

### **Common Issues**

1. **Python not found**
   - Ensure Python 3.6+ is installed and in PATH
   - Try using `python3` instead of `python`

2. **Permission denied**
   - Run installation script as administrator/sudo
   - Check file permissions in config directory

3. **Login fails**
   - Verify network credentials in config.json
   - Check if portal URL is correct
   - Review logs for detailed error messages

4. **Automatic execution not working**
   - Verify scheduled task/cron job creation
   - Check script paths in automation setup
   - Ensure proper file permissions

### **Getting Help**

- 📖 Check [setup.md](setup.md) for detailed instructions
- 📋 Review log files in `logs/` directory
- 🐛 [Open an issue](https://github.com/01bps/WiFi-Auto-Auth/issues) on GitHub
- 💬 Check existing [discussions](https://github.com/01bps/WiFi-Auto-Auth/discussions)

## 🔄 **Uninstallation**

To completely remove WiFi Auto Auth:

### Windows
```cmd
uninstall.bat
```

### Linux/macOS
```bash
./uninstall.sh
```

The uninstallation script will:
- Remove all scheduled tasks/cron jobs
- Clean up configuration files (optional)
- Remove log files (optional)
- Uninstall Python dependencies (optional)
- Provide detailed summary of actions taken

## 🤝 **Contributing**

Contributions are welcome! Please feel free to:

1. 🍴 Fork the repository
2. 🌟 Create a feature branch (`git checkout -b feature/amazing-feature`)
3. 💬 Commit your changes (`git commit -m 'Add amazing feature'`)
4. 📤 Push to the branch (`git push origin feature/amazing-feature`)
5. 🔥 Open a Pull Request


## 📜 **License**

This project is licensed under the [MIT License](LICENSE), which allows for free use, modification, and distribution.

## 🙏 **Acknowledgments**

- Thanks to all contributors who help improve this project
- Inspired by the need for seamless connectivity in institutional networks
- Built with ❤️ for the open-source community

---

**🔧 Need help?** [Open an issue](https://github.com/01bps/WiFi-Auto-Auth/issues) on GitHub!

**⭐ Found this useful?** Give it a star to show your support!
