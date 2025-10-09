# Hacktoberfest 2025 - Our Contributors

This page celebrates everyone who contributed to WiFi-Auto-Auth during Hacktoberfest!

## ⭐ Star This Repo!

Show your support by starring this repository!

---

## 📊 Stats

- **Contributors:** 0
- **Issues Fixed:** 0
- **PRs Merged:** 0

---

## 🏆 All Contributions

Keep Adding your contribution in the below template,One after the other:

## Implement Password Encryption 
**Contributor ID:** AnikethBhosale
**Issue reference No.:** #4

### What I Changed:
- Integrated Fernet symmetric encryption for WiFi and dashboard passwords in `config.json` for enhanced security
- Passwords are now automatically encrypted on first run and stored securely in both config and database
- Added logic to prevent multiple encryption of already encrypted passwords
- Passwords are only decrypted in memory for login/authentication, never stored or logged in plaintext
- Updated README with an 'Updated Security Notes' section describing the new encryption workflow
- Added `cryptography` to `requirements.txt` to document the new dependency

**Files Changed:** `wifi_auto_login.py`, `dashboard.py`, `config.example.json`, `requirements.txt`, `readme.md`

---

## Professional Logging System Implementation
**Contributor ID:** cmarchena
**Issue reference No.:** #6

### What I Changed:
- Implemented comprehensive professional logging system with configurable log levels
- Added CLI arguments for logging configuration (--log-level, --view-logs, etc.)
- Created logging configuration module with environment variable support
- Added log rotation for automatic file management
- Updated README with detailed logging options documentation
- Created .gitignore file to exclude logs, cache, and sensitive files

**Files Changed:** `wifi_auto_login.py`, `config/logging_config.py`, `readme.md`, `.gitignore`

---

## Internet Connectivity Check
**Contributor ID:** singhxabhijeet
**Issue reference No.:** #11

**What I Changed:**
- Implemented an internet connectivity check to prevent unnecessary login attempts.
- Added a `check_connectivity()` function to verify internet access before running the login logic.
- Updated the script to notify the user and exit gracefully if a connection is already active.
- Improved user feedback regarding the network status.

**Files Changed:** `wifi_auto_login.py`

---

## 🙏 Thank You!

Every contribution makes this project better. We appreciate you!

**Don't forget to ⭐ star this repository!**

---

*Updated: October 2025*
