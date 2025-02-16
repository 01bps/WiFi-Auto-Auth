# **Auto Wifi Login**
"Tired of entering the same Wi-Fi credentials every time you join the network? So was I! 😅 At my institute, logging into Wi-Fi manually was a hassle, so I built this Auto WiFi Login Script to automate the process!

This script automatically logs into Wi-Fi networks using pre-saved credentials and now comes with SQLite integration to store login attempts. It keeps track of all login activities, captures dynamic session parameters (a), and provides a user-friendly log display for debugging.

Ideal for schools, workplaces, or any location with recurring Wi-Fi logins, this script eliminates manual re-authentication and ensures effortless connectivity. It's fully customizable, works across different networks, and can even be automated on startup for a seamless experience.

Say goodbye to typing passwords repeatedly and hello to smart, automated Wi-Fi access


## **Features**

-  Secure credential storage using SQLite database
-  Login attempt logging with automatic cleanup
-  Support for multiple network configurations
-  Automatic error handling and retries
-  Detailed status tracking and logging

### **For step-by-step setup instructions, please refer to [setup.md](https://github.com/01bps/RGIPT_Auto_Connect/blob/main/setup.md)**

## **Security Notes**
- Credentials are securely stored in an SQLite database within your home directory.
- No sensitive data is transmitted except during the login request.
- Passwords are masked in logs for security.
- Login attempts are logged in SQLite, and old logs are automatically deleted after reboot


# **License:**
   This project is licensed under the [MIT License](LICENSE), which allows for free use, modification, and distribution.

🔧 **Need help?** Open an issue on GitHub!
