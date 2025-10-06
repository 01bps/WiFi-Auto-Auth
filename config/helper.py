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
