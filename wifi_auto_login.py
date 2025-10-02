import sqlite3
import requests
import datetime
import re
import json
import os
import time
import platform
import subprocess
import sys
import argparse
from pathlib import Path
from urllib.parse import urlparse

# Try to import plyer for notifications, fallback to native solutions if not available
try:
    from plyer import notification
    PLYER_AVAILABLE = True
except Exception:
    PLYER_AVAILABLE = False

# Optional Windows toast library (used only in windows fallback)
try:
    import win10toast
    WIN10TOAST_AVAILABLE = True
except Exception:
    WIN10TOAST_AVAILABLE = False

# Configuration file path
CONFIG_FILE = Path.home() / ".wifi_auto_auth_config.json"
DB_NAME = "wifi_log.db"

class NotificationHandler:
    """Cross-platform notification handler"""

    def __init__(self, enabled=True, sound=True):
        self.enabled = enabled
        self.sound = sound
        self.system = platform.system()  # always available now

    def send(self, title, message, urgency="normal"):
        """Send a desktop notification"""
        if not self.enabled:
            return

        try:
            if PLYER_AVAILABLE:
                notification.notify(
                    title=title,
                    message=message,
                    app_icon=None,
                    timeout=10,
                )
                return
            # Fallback if plyer not available
            if self.system == "Linux":
                self._linux_notify(title, message, urgency)
            elif self.system == "Darwin":
                self._macos_notify(title, message)
            elif self.system == "Windows":
                self._windows_notify(title, message)
            else:
                print(f"🔔 {title}: {message}")
        except Exception as e:
            print(f"Notification failed: {e}")
            print(f"🔔 {title}: {message}")

    def _linux_notify(self, title, message, urgency):
        """Linux notification using notify-send"""
        cmd = ["notify-send", title, message, f"--urgency={urgency}"]
        # note: notify-send doesn't have a cross-distro 'sound' flag; you can play a sound separately if needed
        try:
            subprocess.run(cmd, check=False)
        except FileNotFoundError:
            print(f"notify-send not found; fallback to console -> {title}: {message}")

    def _macos_notify(self, title, message):
        """macOS notification using osascript"""
        # Escape double-quotes in message/title
        safe_title = title.replace('"', '\\"')
        safe_message = message.replace('"', '\\"')
        script = f'display notification "{safe_message}" with title "{safe_title}"'
        subprocess.run(["osascript", "-e", script], check=False)

    def _windows_notify(self, title, message):
        """Windows notification using win10toast or powershell fallback"""
        # Prefer win10toast if installed
        try:
            if WIN10TOAST_AVAILABLE:
                from win10toast import ToastNotifier
                toaster = ToastNotifier()
                toaster.show_toast(title, message, duration=10, threaded=True)
            else:
                # Use PowerShell balloon as fallback - escape single quotes
                safe_title = title.replace("'", "''")
                safe_message = message.replace("'", "''")
                ps_script = f"""
                $app = New-Object -ComObject WScript.Shell
                $app.Popup('{safe_message}', 10, '{safe_title}', 64)
                """
                subprocess.run(["powershell", "-NoProfile", "-Command", ps_script], check=False)
        except Exception:
            print(f"Windows notification fallback -> {title}: {message}")

def _deep_update(dst, src):
    """Deep merge src dict into dst dict"""
    for k, v in src.items():
        if isinstance(v, dict) and isinstance(dst.get(k), dict):
            _deep_update(dst[k], v)
        else:
            dst[k] = v

class Config:
    """Configuration manager for the WiFi auto-login script"""
    
    @staticmethod
    def load():
        """Load configuration from file"""
        default_config = {
            "login_url": "http://192.168.100.1:8090/login.xml",
            "username": "your_username",
            "password": "your_password",
            "payload_params": {
                "mode": "191",
                "username": "your_username",
                "password": "your_password",
                "a": "dynamic",
                "producttype": "0"
            },
            "notifications": {
                "enabled": True,
                "sound": True,
                "on_success": True,
                "on_failure": True,
                "on_network_error": True,
                "on_already_logged_in": True
            },
            "db_name": DB_NAME,
            "retry_attempts": 3,
            "retry_delay": 5
        }

        if CONFIG_FILE.exists():
            try:
                with open(CONFIG_FILE, 'r') as f:
                    user_config = json.load(f)
                _deep_update(default_config, user_config)
            except json.JSONDecodeError:
                print("⚠️ Invalid config file, using defaults")
        else:
            Config.save(default_config)
            print(f"📝 Created default config at: {CONFIG_FILE}")
            print("Please edit this file with your WiFi credentials!")

        return default_config
    
    @staticmethod
    def save(config):
        """Save configuration to file"""
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=4)

def setup_database():
    """Create the database and table if they do not exist."""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS login_attempts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            username TEXT,
            password TEXT,
            a TEXT,
            response_status TEXT,
            response_message TEXT,
            notification_sent INTEGER DEFAULT 0
        )
    """)
    conn.commit()
    conn.close()

def log_attempt(username, password, a, response_status, response_message, notification_sent=False):
    """Log each login attempt in the database."""
    ts = datetime.datetime.now().isoformat(sep=' ', timespec='seconds')
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO login_attempts (timestamp, username, password, a, response_status, response_message, notification_sent)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (ts, username, "******", a, str(response_status), response_message, int(bool(notification_sent))))
    conn.commit()
    conn.close()

def extract_message(response_text):
    """Extracts the meaningful message from the XML response (best-effort)."""
    # Try common CDATA <message>
    match = re.search(r"<message>\s*<!\[CDATA\[(.*?)\]\]>\s*</message>", response_text, re.DOTALL | re.IGNORECASE)
    if match:
        return match.group(1).strip()
    # Try plain <message> tag
    match2 = re.search(r"<message>(.*?)</message>", response_text, re.DOTALL | re.IGNORECASE)
    if match2:
        return match2.group(1).strip()
    # Try <msg> tag variant
    match3 = re.search(r"<msg>(.*?)</msg>", response_text, re.DOTALL | re.IGNORECASE)
    if match3:
        return match3.group(1).strip()
    # fallback to first 300 chars of plain text
    return re.sub(r"\s+", " ", response_text).strip()[:300] or "No response"

def check_connectivity(url):
    """Check if the network/login portal is reachable"""
    try:
        parsed = urlparse(url if '://' in url else 'http://' + url)
        base_url = f"{parsed.scheme}://{parsed.netloc}"
        response = requests.get(base_url, timeout=5)
        return True
    except requests.exceptions.RequestException:
        return False
    except Exception:
        return False

def wifi_login(config, notifier):
    """Perform the WiFi login request and log the result."""
    url = config["login_url"]
    username = config["username"]
    password = config["password"]
    
    # Check network connectivity first
    if not check_connectivity(url):
        error_msg = "Network unreachable or login portal not available"
        print(f"⌛ {error_msg}")
        
        if config["notifications"]["on_network_error"]:
            notifier.send(
                "WiFi Auto-Auth: Network Error",
                error_msg,
                urgency="critical"
            )
        
        log_attempt(username, password, "N/A", "NETWORK_ERROR", error_msg, True)
        return False
    
    # Generate dynamic 'a' value if needed
    if config["payload_params"].get("a") == "dynamic":
        a_value = str(int(datetime.datetime.now().timestamp()))
    else:
        a_value = config["payload_params"].get("a", "")
    
    # Build payload - copy to avoid mutation
    payload = dict(config["payload_params"])
    payload["username"] = username
    payload["password"] = password
    if "a" in payload:
        payload["a"] = a_value
    
    notification_sent = False
    
    try:
        response = requests.post(url, data=payload, timeout=10)
        response_status = response.status_code
        response_message = extract_message(response.text)
        
        print(f"\n📌 Login Attempt")
        print(f"Time: {datetime.datetime.now().isoformat(sep=' ', timespec='seconds')}")
        print(f"Username: {username}")
        if a_value:
            print(f"Session ID (a): {a_value}")
        print(f"Status: {response_status}")
        print(f"Message: {response_message}")
        print("-" * 80)
        
        # Determine success/failure and send appropriate notification
        success_keywords = ["success", "logged in", "authenticated", "welcome"]
        already_logged_keywords = ["already", "exist", "active"]
        
        message_lower = response_message.lower()
        
        if any(keyword in message_lower for keyword in success_keywords):
            if config["notifications"]["on_success"]:
                notifier.send(
                    "WiFi Auto-Auth: Success ✅",
                    f"Successfully logged in as {username}",
                    urgency="normal"
                )
                notification_sent = True
        elif any(keyword in message_lower for keyword in already_logged_keywords):
            if config["notifications"]["on_already_logged_in"]:
                notifier.send(
                    "WiFi Auto-Auth: Already Connected 🔄",
                    "You are already logged into the network",
                    urgency="low"
                )
                notification_sent = True
        else:
            if config["notifications"]["on_failure"]:
                notifier.send(
                    "WiFi Auto-Auth: Login Failed ❌",
                    f"Failed: {response_message[:100]}",
                    urgency="critical"
                )
                notification_sent = True
        
        # Log the attempt in SQLite
        log_attempt(username, password, a_value, str(response_status), response_message, notification_sent)
        return response_status == 200
        
    except requests.exceptions.Timeout:
        error_msg = "Connection timeout - server took too long to respond"
        print(f"⌛ Timeout Error: {error_msg}")
        if config["notifications"]["on_network_error"]:
            notifier.send(
                "WiFi Auto-Auth: Timeout ⏱️",
                error_msg,
                urgency="critical"
            )
            notification_sent = True
        log_attempt(username, password, a_value, "TIMEOUT", error_msg, notification_sent)
        return False
        
    except requests.exceptions.RequestException as e:
        error_msg = str(e)
        print(f"❌ Error: {error_msg}")
        if config["notifications"]["on_failure"]:
            notifier.send(
                "WiFi Auto-Auth: Error ❌",
                f"Connection error: {error_msg[:100]}",
                urgency="critical"
            )
            notification_sent = True
        log_attempt(username, password, a_value, "FAILED", error_msg, notification_sent)
        return False

def view_logs(limit=5):
    """Display login logs in a readable format."""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT timestamp, username, a, response_status, response_message, notification_sent 
        FROM login_attempts 
        ORDER BY timestamp DESC 
        LIMIT ?
    """, (limit,))
    
    logs = cursor.fetchall()
    conn.close()
    
    if not logs:
        print("No login attempts found.")
        return
    
    print("\n📋 Recent Login Attempts")
    print("=" * 80)
    
    for log in logs:
        timestamp, username, a, status, message, notif = log
        print(f"Time: {timestamp}")
        print(f"Username: {username}")
        if a and a != "N/A":
            print(f"Session ID (a): {a}")
        print(f"Status: {status}")
        print(f"Message: {message}")
        print(f"Notification Sent: {'Yes' if notif else 'No'}")
        print("-" * 80)

def clear_old_logs(days=30):
    """Clear logs older than specified days"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cutoff = datetime.datetime.now() - datetime.timedelta(days=days)
    cutoff_iso = cutoff.isoformat(sep=' ', timespec='seconds')
    cursor.execute("DELETE FROM login_attempts WHERE timestamp < ?", (cutoff_iso,))
    deleted = cursor.rowcount
    conn.commit()
    conn.close()
    if deleted and deleted > 0:
        print(f"🗑️ Cleared {deleted} old log entries")

def parse_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='WiFi Auto-Login Script with Notifications')
    parser.add_argument('--no-notify', action='store_true', 
                       help='Disable notifications for this run')
    parser.add_argument('--test-notify', action='store_true',
                       help='Test notification system and exit')
    parser.add_argument('--view-logs', type=int, metavar='N',
                       help='View last N login attempts and exit')
    parser.add_argument('--clear-logs', type=int, metavar='DAYS',
                       help='Clear logs older than DAYS and exit')
    return parser.parse_args()

def main():
    """Main execution function"""
    args = parse_args()
    
    # Load configuration
    config = Config.load()
    
    # Handle test notification
    if args.test_notify:
        print("🧪 Testing notification system...")
        test_notifier = NotificationHandler(enabled=True, sound=True)
        test_notifier.send(
            "WiFi Auto-Auth Test",
            "✅ Notifications are working correctly!",
            urgency="normal"
        )
        print("✅ Test notification sent. Check your desktop notifications!")
        return
    
    # Handle view logs
    if args.view_logs is not None:
        setup_database()
        view_logs(args.view_logs)
        return
    
    # Handle clear logs
    if args.clear_logs is not None:
        setup_database()
        clear_old_logs(args.clear_logs)
        return
    
    # Check if this is first run (default credentials)
    if config["username"] == "your_username":
        print("\n⚠️ Please configure your WiFi credentials!")
        print(f"Edit the config file at: {CONFIG_FILE}")
        print("Then run this script again.")
        return
    
    # Override notification settings if --no-notify is used
    if args.no_notify:
        config["notifications"]["enabled"] = False
        print("🔕 Notifications disabled for this run")
    
    # Initialize notification handler
    notifier = NotificationHandler(
        enabled=config["notifications"]["enabled"],
        sound=config["notifications"].get("sound", True)
    )
    
    # Setup database
    setup_database()
    
    # Clear old logs (older than 30 days)
    clear_old_logs(30)
    
    # Attempt login with retry logic
    max_retries = config.get("retry_attempts", 3)
    retry_delay = config.get("retry_delay", 5)
    
    for attempt in range(max_retries):
        if attempt > 0:
            print(f"\n🔄 Retry attempt {attempt}/{max_retries - 1}")
            time.sleep(retry_delay)
        
        success = wifi_login(config, notifier)
        if success:
            break
    
    # Show recent logs
    view_logs(5)

if __name__ == "__main__":
    # Install plyer if not available
    if not PLYER_AVAILABLE:
        print("📦 plyer not installed. For better notification support, run:")
        print("   pip install plyer")
        print("   Using fallback notification methods...\n")
    
    main()