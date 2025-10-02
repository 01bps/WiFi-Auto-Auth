# WiFi Auto-Auth Setup Guide with Notification System
___

## 🔔 New Features: Desktop Notifications
The script now includes a cross-platform notification system that alerts you about:
- ✅ Successful login attempts
- ❌ Failed login attempts
- 🔌 Network connectivity issues
- 🔄 Already logged in status
- ⏱️ Connection timeouts

## 1. Install Dependencies  

Run the following command to install the requirements:  

```bash
pip install -r requirements.txt
```

### Platform-specific notification setup:

#### **Linux:**
- Install `libnotify` if not present:
  ```bash
  sudo apt-get install libnotify-bin  # Debian/Ubuntu
  sudo dnf install libnotify  # Fedora
  sudo pacman -S libnotify  # Arch
  ```

#### **Windows:**
- Notifications work out of the box with Windows 10/11
- For better support, install: `pip install win10toast`

#### **macOS:**
- Notifications use native macOS notification center
- No additional setup required

## 2. Configure Your Network Settings

The script now uses a JSON configuration file located at:
- **Linux/Mac:** `~/.wifi_auto_auth_config.json`
- **Windows:** `C:\Users\YourUsername\.wifi_auto_auth_config.json`

### 2.1 First Run
On first run, the script will create a default configuration file. Edit this file with your network details.

### 2.2 Find Your Network's Login URL and Payload
```
1. Connect to your WiFi network manually
2. Open the login page in a browser (typically http://192.168.x.x:8090/httpclient.html)
3. Open Developer Tools (F12) → Network Tab
4. Log in manually and find the POST request (usually to /login.xml)
5. Copy the request URL and form data parameters
```

### 2.3 Edit the Configuration File

Example configuration:
```json
{
    "login_url": "http://192.168.100.1:8090/login.xml",
    "username": "your_actual_username",
    "password": "your_actual_password",
    "payload_params": {
        "mode": "191",
        "username": "your_actual_username",
        "password": "your_actual_password",
        "a": "dynamic",
        "producttype": "0"
    },
    "notifications": {
        "enabled": true,
        "sound": true,
        "on_success": true,
        "on_failure": true,
        "on_network_error": true,
        "on_already_logged_in": true
    },
    "db_name": "wifi_log.db",
    "retry_attempts": 3,
    "retry_delay": 5
}
```

### Configuration Options:

| Option | Description | Values |
|--------|-------------|--------|
| `login_url` | Your WiFi portal login URL | String |
| `username` | Your WiFi username | String |
| `password` | Your WiFi password | String |
| `payload_params.a` | Session parameter | "dynamic" or static value |
| `notifications.enabled` | Enable/disable all notifications | true/false |
| `notifications.sound` | Play sound with notifications | true/false |
| `notifications.on_success` | Notify on successful login | true/false |
| `notifications.on_failure` | Notify on failed login | true/false |
| `notifications.on_network_error` | Notify on network issues | true/false |
| `notifications.on_already_logged_in` | Notify if already connected | true/false |
| `retry_attempts` | Number of retry attempts | Integer (1-10) |
| `retry_delay` | Delay between retries (seconds) | Integer |

## 3. Test the Script

Run the script manually to test:
```bash
python wifi_auto_login.py
```

You should see:
1. Console output showing the login attempt
2. A desktop notification with the result
3. Recent login history

## 4. Test Notifications

To test if notifications are working on your system:
```bash
python -c "from plyer import notification; notification.notify(title='Test', message='Notifications working!')"
```

## 5. Automate WiFi Login on System Boot

### 🔹 Windows (Task Scheduler)
1. Open **Task Scheduler** → **Create Basic Task**
2. Name: "WiFi Auto Login"
3. Trigger: **At Startup**
4. Action: **Start a Program**
5. Program: `python.exe` or `pythonw.exe` (for no console window)
6. Arguments: `"C:\path\to\wifi_auto_login.py"`
7. Start in: `"C:\path\to\"` (directory containing the script)
8. Check "Run with highest privileges"

### 🔹 Linux (Systemd Service - Recommended)
1. Create a service file:
   ```bash
   sudo nano /etc/systemd/system/wifi-auto-login.service
   ```

2. Add content:
   ```ini
   [Unit]
   Description=WiFi Auto Login Service
   After=network-online.target
   Wants=network-online.target
   
   [Service]
   Type=oneshot
   User=your_username
   ExecStartPre=/bin/sleep 10
   ExecStart=/usr/bin/python3 /path/to/wifi_auto_login.py
   RemainAfterExit=yes
   
   [Install]
   WantedBy=multi-user.target
   ```

3. Enable the service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable wifi-auto-login.service
   sudo systemctl start wifi-auto-login.service
   ```

### 🔹 Linux (Crontab - Alternative)
```bash
crontab -e
# Add this line:
@reboot sleep 30 && /usr/bin/python3 /path/to/wifi_auto_login.py
```

### 🔹 macOS (Launch Agent)
1. Create plist file:
   ```bash
   nano ~/Library/LaunchAgents/com.wifi.autologin.plist
   ```

2. Add content:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
   "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.wifi.autologin</string>
       <key>ProgramArguments</key>
       <array>
           <string>/usr/bin/python3</string>
           <string>/path/to/wifi_auto_login.py</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>StartInterval</key>
       <integer>300</integer>
       <key>StandardOutPath</key>
       <string>/tmp/wifi-auto-login.log</string>
       <key>StandardErrorPath</key>
       <string>/tmp/wifi-auto-login-error.log</string>
   </dict>
   </plist>
   ```

3. Load the agent:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.wifi.autologin.plist
   ```

## 6. View Logs and Statistics

The script maintains a SQLite database with all login attempts. To view logs:

```python
# View last 10 login attempts
python -c "from wifi_auto_login import view_logs; view_logs(10)"
```

## 7. Troubleshooting

### Notifications not working?

1. **Linux:** Ensure `notify-send` is installed
2. **Windows:** Try running as administrator
3. **macOS:** Check System Preferences → Notifications → Python
4. **All platforms:** Test with the test command in step 4

### Script not running at startup?

1. Check system logs:
   - **Linux:** `journalctl -u wifi-auto-login.service`
   - **Windows:** Event Viewer → Windows Logs → System
   - **macOS:** `Console.app` → system.log

2. Add a delay before execution (network might not be ready)

### Can't find login URL?

1. Try common patterns:
   - `http://192.168.1.1:8090/login.xml`
   - `http://192.168.0.1:8090/httpclient.html`
   - `http://10.0.0.1/login`

2. Check browser's network tab while logging in manually

## 8. Security Notes

- Configuration file contains credentials - keep it secure!
- Set appropriate file permissions:
  ```bash
  chmod 600 ~/.wifi_auto_auth_config.json  # Linux/Mac
  ```
- Passwords are masked in logs
- Consider using environment variables for sensitive data
- The SQLite database is stored locally and logs are auto-cleaned after 30 days

## 9. Customization

### Custom Notification Icons
Place an icon file (`.png` or `.ico`) in the script directory and update the code:
```python
notification.notify(
    title=title,
    message=message,
    app_icon="path/to/icon.png",  # Add your icon path
    timeout=10
)
```

### Notification Sounds
Customize notification sounds by modifying the platform-specific functions in the `NotificationHandler` class.

## 10. Uninstall

To remove the auto-login service:

**Windows:**
- Delete the Task Scheduler task

**Linux (systemd):**
```bash
sudo systemctl stop wifi-auto-login.service
sudo systemctl disable wifi-auto-login.service
sudo rm /etc/systemd/system/wifi-auto-login.service
```

**macOS:**
```bash
launchctl unload ~/Library/LaunchAgents/com.wifi.autologin.plist
rm ~/Library/LaunchAgents/com.wifi.autologin.plist
```

## Need Help?

- Check the logs: Script creates detailed logs in `wifi_log.db`
- Enable debug mode by adding verbose output in the script
- Open an issue on GitHub with your log output (remove sensitive data!)

---

Successfully set up! Your WiFi will now connect automatically with desktop notifications! 🎉