import sqlite3
import requests
import datetime
import re
import json
import os

# --- CONFIGURATION ---
CONFIG_PATH = "config.json"

# Error handling if config.json is missing
if not os.path.exists(CONFIG_PATH):
    raise FileNotFoundError(
        "Missing config.json. Please copy config.example.json to config.json and fill in your details."
    )

with open(CONFIG_PATH, "r") as f:
    config = json.load(f)

URL = config["wifi_url"]
USERNAME = config["username"]
PASSWORD = config["password"]
PRODUCT_TYPE = config.get("product_type", "0")  # Default to "0" if not provided

# --- DATABASE SETUP ---
DB_NAME = "wifi_log.db"

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
            response_message TEXT
        )
    """)
    conn.commit()
    conn.close()

def log_attempt(username, password, a, response_status, response_message):
    """Log each login attempt in the database."""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO login_attempts (timestamp, username, password, a, response_status, response_message)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (datetime.datetime.now(), username, "******", a, response_status, response_message))
    conn.commit()
    conn.close()

# --- HELPER FUNCTIONS ---
def extract_message(response_text):
    """Extracts the meaningful message from the XML response."""
    match = re.search(r"<message><!\[CDATA\[(.*?)\]\]></message>", response_text)
    return match.group(1) if match else "Unknown response"

# --- MAIN WIFI LOGIN FUNCTION ---
def wifi_login():
    """Perform the WiFi login request and log the result."""
    a_value = str(int(datetime.datetime.now().timestamp()))  # Generate dynamic 'a' value

    payload = {
        "mode": "191",
        "username": USERNAME,
        "password": PASSWORD,
        "a": a_value,
        "producttype": PRODUCT_TYPE
    }

    try:
        response = requests.post(URL, data=payload)
        response_status = response.status_code
        response_message = extract_message(response.text)

        print(f"\n📌 Login Attempt")
        print(f"Time: {datetime.datetime.now()}")
        print(f"Username: {USERNAME}")
        print(f"Session ID (a): {a_value}")
        print(f"Status: {response_status}")
        print(f"Message: {response_message}")
        print("-" * 80)

        # Log the attempt in SQLite
        log_attempt(USERNAME, PASSWORD, a_value, response_status, response_message)

    except requests.exceptions.RequestException as e:
        print(f"❌ Error: {e}")
        log_attempt(USERNAME, PASSWORD, a_value, "FAILED", str(e))

# --- VIEW LOGIN LOGS ---
def view_logs(limit=5):
    """Display login logs in a readable format."""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT timestamp, username, a, response_status, response_message 
        FROM login_attempts 
        ORDER BY timestamp DESC 
        LIMIT ?
    """, (limit,))

    logs = cursor.fetchall()
    conn.close()

    if not logs:
        print("No login attempts found.")
        return

    print("\n📌 Recent Login Attempts")
    print("=" * 80)

    for log in logs:
        timestamp, username, a, status, message = log
        print(f"Time: {timestamp}")
        print(f"Username: {username}")
        print(f"Session ID (a): {a}")
        print(f"Status: {status}")
        print(f"Message: {message}")
        print("-" * 80)

# --- MAIN EXECUTION ---
if __name__ == "__main__":
    setup_database()   # Ensure the database is set up
    wifi_login()       # Attempt login
    view_logs(5)       # Show last 5 login attempts
