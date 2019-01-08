# Remote Deploy
Remote Deploy uses a powershell GUI to silently run/monitor software installation scripts on a remote computer. These installation scripts are kept in seperate .ps1 files to avoid PDQ package redundancy.

# Usage
Enter a computer name or server name, and select a package from the dropdown list. Remote Deploy will copy the necessary files to the target computer, start a remote powershell session as a job, and wait for output from the job using a winforms timer object.

# Return Arrays
Installation packages send status updates back to Remote Deploy using return codes. All return codes are arrays, with the first index being the return code and following indexes being any additional information. There are several codes with pre-written status messages, and a custom code for misc updates. Installation packages use 'Write-Output' to return data back to Remote Deploy.

    0  : Completed
        The installer finished and the installation was verified.
        Syntax: $completed

    -1 : Connected
        The pssession has connected to the target computer and is running
        Syntax: $connected

    -2 : Copying
        The Installer is copying any necessary files/folders to the target device prior to installation.
        Syntax: $copying

    -3 : Installing
        The installer is running
        Syntax: $installing

    -4 : Verifying
        Checking the target computer to ensure that the application installed successfully
        Syntax: $verifying

    1  : Custom output
        A placeholder for any custom output message. The second value in the exit array holds the custom message, and the third value is used to specify whether the installer should continue or stop. The default action is to stop.
        Syntax: $customMsg, [custom message], "continue"

    2  : Copy Error
        The installer failed to copy files to the target computer. The second value in the exit array holds the error message (typically '$_' in a Try/Catch block)
        Syntax: $copyErr, [error message]

    3  : Install Error
        The installer returned an error and did not finish. The second value in the exit array holds the error message (typically '$_' in a Try/Catch block)
        Syntax: $msiErr, [error message]

    4  : Verification Error
        The installer did not return an error, but the installation could not be verified
        Syntax: $verrErr