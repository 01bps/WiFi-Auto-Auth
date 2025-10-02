@echo off
REM WiFi Auto Auth Installation Script
REM This script installs and configures WiFi Auto Auth service

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo ========================================
echo WiFi Auto Auth Installation Script
echo ========================================
echo.

REM Get the current script directory
set "INSTALL_DIR=%~dp0"
set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

echo Installation directory: %INSTALL_DIR%
echo.

REM Check if Python 3.x is installed
echo Checking for Python 3.x installation...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.x from https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Verify Python version is 3.x
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
for /f "tokens=1 delims=." %%a in ("%PYTHON_VERSION%") do set PYTHON_MAJOR=%%a

if %PYTHON_MAJOR% LSS 3 (
    echo ERROR: Python 3.x or higher is required. Found Python %PYTHON_VERSION%
    pause
    exit /b 1
)

echo Python %PYTHON_VERSION% detected successfully
echo.

REM Install required Python packages from requirements.txt
echo Installing required Python packages from requirements.txt...
pip install -r "%INSTALL_DIR%\requirements.txt"
if %errorLevel% neq 0 (
    echo ERROR: Failed to install packages from requirements.txt
    pause
    exit /b 1
)
echo Python packages installed successfully
echo.

REM Create necessary directories
echo Creating necessary directories...

if not exist "%INSTALL_DIR%\config" (
    mkdir "%INSTALL_DIR%\config"
    echo Created config directory
)

if not exist "%INSTALL_DIR%\logs" (
    mkdir "%INSTALL_DIR%\logs"
    echo Created logs directory
)

if not exist "%INSTALL_DIR%\data" (
    mkdir "%INSTALL_DIR%\data"
    echo Created data directory
)

echo.

REM Interactive configuration setup
echo ========================================
echo Configuration Setup
echo ========================================
echo.

set /p WIFI_SSID="Enter WiFi SSID (network name): "
set /p WIFI_USERNAME="Enter WiFi username/ID: "
set /p WIFI_PASSWORD="Enter WiFi password: "
set /p PORTAL_URL="Enter authentication portal URL: "

echo.
echo Creating configuration file...

REM Create config.json file
(
echo {
echo   "wifi": {
echo     "ssid": "%WIFI_SSID%",
echo     "username": "%WIFI_USERNAME%",
echo     "password": "%WIFI_PASSWORD%"
echo   },
echo   "portal": {
echo     "url": "%PORTAL_URL%",
echo     "timeout": 30
echo   },
echo   "logging": {
echo     "enabled": true,
echo     "log_file": "logs/wifi_auto_auth.log",
echo     "level": "INFO"
echo   }
echo }
) > "%INSTALL_DIR%\config\config.json"

echo Configuration file created at: %INSTALL_DIR%\config\config.json
echo.

REM Set up scheduled task (Windows equivalent of cron job)
echo ========================================
echo Scheduled Task Setup
echo ========================================
echo.
set /p SETUP_TASK="Do you want to set up automatic execution on startup and network changes? (Y/N): "

if /i "%SETUP_TASK%"=="Y" (
    echo.
    echo Creating scheduled tasks...
    
    REM Create a scheduled task to run on startup
    schtasks /create /tn "WiFiAutoAuth" /tr "python \"%INSTALL_DIR%\wifi_auto_auth.py\"" /sc onlogon /rl highest /f >nul 2>&1
    if %errorLevel% equ 0 (
        echo [OK] Startup task created successfully
    ) else (
        echo [WARNING] Failed to create startup task
    )
    
    REM Create a task to run on network state change
    schtasks /create /tn "WiFiAutoAuthOnNetwork" /tr "python \"%INSTALL_DIR%\wifi_auto_auth.py\"" /sc onevent /ec System /mo "*[System[Provider[@Name='Microsoft-Windows-NetworkProfile'] and EventID=10000]]" /rl highest /f >nul 2>&1
    if %errorLevel% equ 0 (
        echo [OK] Network event task created successfully
    ) else (
        echo [WARNING] Failed to create network event task
    )
    
    echo.
    echo Scheduled tasks have been configured.
) else (
    echo Skipping scheduled task setup.
    echo You can manually run: python wifi_auto_auth.py
)

echo.

REM Set proper file permissions
echo ========================================
echo Setting File Permissions
echo ========================================
echo.

REM Set restrictive permissions on config directory (Windows NTFS permissions)
icacls "%INSTALL_DIR%\config" /inheritance:r /grant:r "%USERNAME%:(OI)(CI)F" /t >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Config directory permissions set (accessible only by current user)
) else (
    echo [WARNING] Could not set restrictive permissions on config directory
)

REM Set permissions on logs directory
icacls "%INSTALL_DIR%\logs" /grant "%USERNAME%:(OI)(CI)M" >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Logs directory permissions set
) else (
    echo [WARNING] Could not set permissions on logs directory
)

echo.

REM Final summary
echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo Summary:
echo   - Python %PYTHON_VERSION% verified
echo   - Required packages installed
echo   - Directories created: config, logs, data
echo   - Configuration file created
echo   - File permissions configured
if /i "%SETUP_TASK%"=="Y" (
    echo   - Scheduled tasks configured
)
echo.
echo Installation directory: %INSTALL_DIR%
echo Configuration file: %INSTALL_DIR%\config\config.json
echo Log file: %INSTALL_DIR%\logs\wifi_auto_auth.log
echo.
echo Next steps:
echo   1. Review configuration in config\config.json
echo   2. Test the script: python wifi_auto_auth.py
if /i NOT "%SETUP_TASK%"=="Y" (
    echo   3. Run install.bat again to set up scheduled tasks
)
echo.
echo To uninstall, run: uninstall.bat
echo.
pause