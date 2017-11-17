# PaltoShell
A simple PowerShell GUI to query a Palo Alto firewall.
Right now the only function is to check for GlobalProtect VPN users.

![alt text](https://raw.githubusercontent.com/marcusit/PaltoShell/master/paltoshell.png)

# Installation
In the "VARIABLES" section the following needs to be adjusted:
* $fw_hostname - Add the hostname or IP of the Palo Alto firewall here.
* $homedir - By default we use the users home directory. This where we store the API key. If a different path is desired edit they $keyfile variable instead.
* $default_path - If we want to save the results to a .csv file this is where the save dialog will browse to by default.
* $keyfile - The path and filename of the API key file. Should be in a secure location.

# System Requirements
* Microsoft .NET (tested with version 4.6.2)
* PowerShell version 4.0 or higher
