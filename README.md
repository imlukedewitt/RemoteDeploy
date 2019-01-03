# Remote Deploy
Remote Deploy uses a powershell GUI to silently run/monitor software installation scripts on a remote computer. These installation scripts are kept in seperate .ps1 files to avoid PDQ package redundancy.

# Usage
Enter a computer name or server name, and select a package from the dropdown list. Remote Deploy will copy the necessary files to the target computer, start a remote powershell session as a job, and wait for output from the job using a Windows Forms timer object.

# Exit Codes
