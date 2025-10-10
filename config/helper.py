import subprocess, sys

def get_ssid_linux():
    out = subprocess.check_output(["nmcli", "-t", "-f", "active,ssid", "dev", "wifi"], text=True)
    for line in out.splitlines():
        active, ssid = line.split(":",1)
        if active == "yes":
            return ssid
    return None

def get_ssid_mac():
    out = subprocess.check_output(["/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport", "-I"], text=True)
    for line in out.splitlines():
        if "SSID:" in line:
            return line.split("SSID:")[1].strip()
    return None

def get_ssid_windows():
    out = subprocess.check_output(["netsh", "wlan", "show", "interfaces"], text=True, shell=True)
    for line in out.splitlines():
        if "SSID" in line and "BSSID" not in line:
            return line.split(":",1)[1].strip()
    return None

def detect_ssid():
    import platform
    plat = platform.system()
    try:
        if plat == "Linux": return get_ssid_linux()
        if plat == "Darwin": return get_ssid_mac()
        if plat == "Windows": return get_ssid_windows()
    except Exception:
        return None
import yaml, keyring, requests, sqlite3, argparse, platform, subprocess

def load_config(path):
    return yaml.safe_load(open(path))

def choose_profile(config, ssid, override):
    if override:
        return config['profiles'].get(override)
    for name, p in config['profiles'].items():
        if ssid in p.get('ssids', []):
            return name, p
    return config.get('default_profile'), config['profiles'][config.get('default_profile')]

def get_creds(key):
    return keyring.get_password('wifi_login', key)

def portal_login(profile, creds):
    # very simplified: POST to login_url with username/password fields
    resp = requests.get("http://clients3.google.com/generate_204", allow_redirects=True, timeout=5)
    if resp.status_code == 204:
        return True, "No portal"
    # redirect -> parse and post
    # ... form parsing and submission ...
    return False, "Portal flow not implemented"

def log(db, profile, ssid, status, msg):
    conn = sqlite3.connect(db); c = conn.cursor()
    c.execute("INSERT INTO login_attempts(profile, ssid, status, msg) VALUES(?,?,?,?)",
              (profile, ssid, status, msg))
    conn.commit(); conn.close()
