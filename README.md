# Remote Deploy
Remote Deploy uses a powershell GUI to silently run/monitor software installation scripts on a remote computer. These installation scripts are kept in seperate .ps1 files to avoid PDQ package redundancy.

# Usage
Enter a computer name or server name, and select a package from the dropdown list. Remote Deploy will copy the necessary files to the target computer, start a remote powershell session as a job, and wait for output from the job using a winforms timer object.

# Return Arrays
Installation packages send status updates back to Remote Deploy using return codes. All return codes are arrays, with the first index being the return code and following indexes being any additional information. There are several codes with pre-written status messages, and a custom code for misc updates. These codes are pre-configured as functions in RemoteDeploy.ps1 and are sent to installation packages as an argument.

    0  : Completed
        The installer finished and the installation was verified.
        Syntax: Status completed

    -1 : Connected
        The pssession has connected to the target computer and is running
        Syntax: Status connected

    -2 : Copying
        The Installer is copying any necessary files/folders to the target device prior to installation.
        Syntax: Status copying

    -3 : Installing
        The installer is running
        Syntax: Status installing

    -4 : Verifying
        Checking the target computer to ensure that the application installed successfully
        Syntax: Status verifying

    1  : Custom output
        A placeholder for any custom output message. The second value in the exit array holds the custom message, and the third value is used to specify whether the installer should continue or stop. The default action is to stop.
        Syntax: Status [custom message] (Remote Deploy will continue)
        Syntax: Error [custom message]  (Remote Deploy will stop)
        Syntax: customMessage [custom message] ['continue'/'stop']

    2  : Copy Error
        The installer failed to copy files to the target computer. The second value in the exit array holds the error message (typically '$_' in a Try/Catch block)
        Syntax: Error copying [error message]

    3  : Install Error
        The installer returned an error and did not finish. The second value in the exit array holds the error message (typically '$_' in a Try/Catch block)
        Syntax: Error installing [error message]

    4  : Verification Error
        The installer did not return an error, but the installation could not be verified
        Syntax: Error verifying

# Argument Prompts
Installation packages can request additional information from the user before deploying. These are defined as comments in the first lines of a package. RemoteDeploy will scan the package text for keywords before deploying. The format for these keywords are as follows:

    #get credentials
        This flag needs to be the first line of a package. It will prompt the user for their username/password. This is necessary for connecting the remote computer to a network drive, since credentials won't pass more than once. (For more information on this reference https://blogs.technet.microsoft.com/ashleymcglone/2016/08/30/powershell-remoting-kerberos-double-hop-solved-securely/)

    #[number of arguments]
        This flag tells RemoteDeploy how many argument prompts to expect.
    
    #[message]
        The default argument syntax. This will create a text input box and set the user message to whatever is specified in the flag

    #directory  [directory path]  [message]
        Populates a combo selection box with the contents of a directory, such as \\ConfigMgrDistro\Software. Note that there are two spaces between each item on the line.

    #networkshare  [network path]  [message]
        Populates a combo selection box with the contents of a network share drive, such as \\print or \\goprint. Note that there are two spaces between each item on the line.
