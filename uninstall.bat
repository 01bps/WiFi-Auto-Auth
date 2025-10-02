@echo off
REM WiFi Auto Auth Uninstallation Script
REM This script removes WiFi Auto Auth service and cleans up

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo ========================================
echo WiFi Auto Auth Uninstallation Script
echo ========================================
echo.

REM Get the current script directory
set "INSTALL_DIR=%~dp0"
set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

echo Installation directory: %INSTALL_DIR%
echo.

REM Confirm uninstallation
set /p CONFIRM="Are you sure you want to uninstall WiFi Auto Auth? This will remove all scheduled tasks. (Y/N): "
if /i NOT "%CONFIRM%"=="Y" (
    echo Uninstallation cancelled.
    pause
    exit /b 0
)

echo.
echo Starting uninstallation...
echo.

REM Remove scheduled tasks
echo ========================================
echo Removing Scheduled Tasks
echo ========================================
echo.

schtasks /query /tn "WiFiAutoAuth" >nul 2>&1
if %errorLevel% equ 0 (
    schtasks /delete /tn "WiFiAutoAuth" /f >nul 2>&1
    if %errorLevel% equ 0 (
        echo [OK] Removed startup task
    ) else (
        echo [WARNING] Failed to remove startup task
    )
) else (
    echo [SKIP] Startup task not found
)

schtasks /query /tn "WiFiAutoAuthOnNetwork" >nul 2>&1
if %errorLevel% equ 0 (
    schtasks /delete /tn "WiFiAutoAuthOnNetwork" /f >nul 2>&1
    if %errorLevel% equ 0 (
        echo [OK] Removed network event task
    ) else (
        echo [WARNING] Failed to remove network event task
    )
) else (
    echo [SKIP] Network event task not found
)

echo.

REM Ask about removing configuration and data
echo ========================================
echo Data Removal Options
echo ========================================
echo.
set /p REMOVE_CONFIG="Do you want to remove configuration files (contains WiFi credentials)? (Y/N): "
set /p REMOVE_LOGS="Do you want to remove log files? (Y/N): "
set /p REMOVE_DATA="Do you want to remove data directory? (Y/N): "

echo.

if /i "%REMOVE_CONFIG%"=="Y" (
    if exist "%INSTALL_DIR%\config" (
        rd /s /q "%INSTALL_DIR%\config" 2>nul
        if %errorLevel% equ 0 (
            echo [OK] Removed config directory
        ) else (
            echo [WARNING] Failed to remove config directory
        )
    ) else (
        echo [SKIP] Config directory not found
    )
) else (
    echo [SKIP] Keeping configuration files
)

if /i "%REMOVE_LOGS%"=="Y" (
    if exist "%INSTALL_DIR%\logs" (
        rd /s /q "%INSTALL_DIR%\logs" 2>nul
        if %errorLevel% equ 0 (
            echo [OK] Removed logs directory
        ) else (
            echo [WARNING] Failed to remove logs directory
        )
    ) else (
        echo [SKIP] Logs directory not found
    )
) else (
    echo [SKIP] Keeping log files
)

if /i "%REMOVE_DATA%"=="Y" (
    if exist "%INSTALL_DIR%\data" (
        rd /s /q "%INSTALL_DIR%\data" 2>nul
        if %errorLevel% equ 0 (
            echo [OK] Removed data directory
        ) else (
            echo [WARNING] Failed to remove data directory
        )
    ) else (
        echo [SKIP] Data directory not found
    )
) else (
    echo [SKIP] Keeping data directory
)

echo.

REM Ask about uninstalling Python packages
echo ========================================
echo Python Packages
echo ========================================
echo.
set /p REMOVE_PACKAGES="Do you want to uninstall Python packages installed by WiFi Auto Auth? (Y/N): "

if /i "%REMOVE_PACKAGES%"=="Y" (
    if exist "%INSTALL_DIR%\requirements.txt" (
        echo Uninstalling Python packages...
        pip uninstall -r "%INSTALL_DIR%\requirements.txt" -y >nul 2>&1
        if %errorLevel% equ 0 (
            echo [OK] Python packages uninstalled
        ) else (
            echo [WARNING] Some packages may not have been uninstalled
        )
    ) else (
        echo [WARNING] requirements.txt not found, skipping package uninstallation
    )
) else (
    echo [SKIP] Keeping Python packages (may be used by other programs)
)

echo.

REM Final summary
echo ========================================
echo Uninstallation Complete!
echo ========================================
echo.
echo Summary of actions taken:
echo   - Scheduled tasks removed
if /i "%REMOVE_CONFIG%"=="Y" (
    echo   - Configuration files removed
) else (
    echo   - Configuration files kept
)
if /i "%REMOVE_LOGS%"=="Y" (
    echo   - Log files removed
) else (
    echo   - Log files kept
)
if /i "%REMOVE_DATA%"=="Y" (
    echo   - Data directory removed
) else (
    echo   - Data directory kept
)
if /i "%REMOVE_PACKAGES%"=="Y" (
    echo   - Python packages uninstalled
) else (
    echo   - Python packages kept
)
echo.
echo The main program files remain in: %INSTALL_DIR%
echo You can manually delete this directory if desired.
echo.
echo Thank you for using WiFi Auto Auth!
echo.
pause