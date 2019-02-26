function RemoteDeploy
{
    function DeployButtonClick
    {
        # Setup and verify variables
        $target          = $tComputerName.Text.Trim().ToUpper()
        $selectedPackage = $cPackage.SelectedItem
        if ($target -eq "" -or $target -eq "Computer Name" -or $cPackage.SelectedIndex -eq 0) { $StatusBar.text = "ERROR: Please complete all fields before deploying"; return}
        $RemoteDeploy.ClientSize = '400,500'
        $UpperLabel.text = "Testing connection...`n----------------"

        # Check that the target is online
        try {Test-Connection -ComputerName $target -ErrorAction stop -Count 2}
        catch
        {
            $UpperLabel.text = "Connection Error`n----------------"
            $LowerLabel.text = "Could not connect to $target, the device `nmight be offline. Please check the name and try again"
            return
        }

        # Get instructions from package for required arguments/additional information
        # If the first line is a number, get that many arguments from the user
        $argumentInstructions = (Get-Content "$packageDir\$selectedPackage.ps1") | ForEach-Object { $_.substring(1) }
        if ($argumentInstructions[0] -match "^[0-9]*$") 
        {
            # Create array to hold the arguments, iterate through each one and get info from the user
            $deploymentArguments = @(" ") * 10
            for ($i = 1; $i -le $argumentInstructions[0]; $i++)
            {
                # Create array to hold each instruction component (Type, message, etc)
                $instructionComponents = $argumentInstructions[$i] -split "  "
                if ($instructionComponents[0] -eq 'get credentials')
                {
                    if (!($global:cred))
                    {
                        $global:cred = Get-Credential -Message "Enter your lion login and password"
                        $global:cred = New-Object System.Management.Automation.PSCredential ("southern\$($global:cred.UserName)", $global:cred.Password)
                        $deploymentArguments[$i-1] = $global:cred
                    }
                }
                elseif ($instructionComponents[0] -eq 'networkshare')
                {
                    $networkPath = $instructionComponents[1]
                    $message = $instructionComponents[2]
                    $options = net view $networkPath
                    $options = $options[7..($options.length - 3)]
                    $options = foreach ($j in $options) { if ($j -match '.*[a-zA-Z].*') {write-output $j}}
                    $options = foreach ($j in $options) { Write-Output ($j -split "  ")[0] }

                    [void] $cInputArg.Items.AddRange($options)
                    $inputComboForm.Controls.Add($cInputArg)
                    $inputComboForm.Topmost = $true
                    $lcInputArg.text = $message
                    $result = $inputComboForm.ShowDialog()
                    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {$deploymentArguments[$i-1] = $cInputArg.SelectedItem}
                    $cInputArg.Items.Clear()
                }
                elseif ($instructionComponents[0] -eq 'directory')
                {
                    $networkPath = $instructionComponents[1]
                    $message = $instructionComponents[2]
                    $options = (get-childitem $networkPath).name

                    [void] $cInputArg.Items.AddRange($options)
                    $inputComboForm.Controls.Add($cInputArg)
                    $inputComboForm.Topmost = $true
                    $lcInputArg.text = $message
                    $result = $inputComboForm.ShowDialog()
                    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {$deploymentArguments[$i-1] = $cInputArg.SelectedItem}
                    $cInputArg.Items.Clear()
                }
                else
                {
                    $deploymentArguments[$i-1] = [Microsoft.VisualBasic.Interaction]::InputBox($argumentInstructions[$i],"Remote Deploy")
                }
            }
        }
        
        $bClear.text             = "Force Stop"
        $bClear.TabStop          = $false # Disable tabbing onto Force Stop button to prevent accidental presses
        $bDeploy.Enabled = $false
        $global:startTime        = get-date -Format  "yyyy-MM-dd HH:mm:ss"
        $RemoteDeploy.ClientSize = '400,500'
        $ClockTimer.start()
        $LowerLabel.text = "Connecting to $target"
        try { Invoke-Command -ComputerName $target -FilePath "$packageDir\$selectedPackage.ps1" -AsJob -ArgumentList $deploymentArguments }
        catch { $LowerLabel.text = "Couldn't connect! Error message:`n$_" ; return}
        $DeployTimer.Add_Tick($DeployTimerTick)
        $DeployTimer.start()
    }

    $DeployTimerTick = 
    {
        $jobOutput = Get-Job -IncludeChildJob | Receive-Job
        if (!$jobOutput) {return}
        switch ($jobOutput[0])
        {
            0 {$LowerLabel.text = "Installation completed successfully"}
           -1 {$LowerLabel.text = "Connected"; return}
           -2 {$LowerLabel.text = "Copying files"; return}
           -3 {$LowerLabel.text = "Installing"; return}
           -4 {$LowerLabel.text = "Verifying installation"; return}
            1 # Custom message
            {
                $LowerLabel.text = $jobOutput[1]
                if ($jobOutput[2] -eq 'continue') {return}
            }
            2 {$LowerLabel.text = "Could not copy files. Error from program:`n$($jobOutput[1])"; $global:cred = $null;}
            3 {$LowerLabel.text = "Installation failed!`n`nProgram returned the following error:`n$($jobOutput[1])"}
            4 {$LowerLabel.text = "Failed!`n`nThe installation could not be verified"}
            default
            {
                $LowerLabel.text += "`nError! Received unexpected output. `n`nError message:`n$($jobOutput[1])"
            }
        }
        $ClockTimer.stop()
        $DeployTimer.Remove_Tick($DeployTimerTick)
        $DeployTimer.stop()
        $bClear.text = "Clear"
        $bClear.TabStop = $true
        [Microsoft.VisualBasic.Interaction]::MsgBox("Deployment finished! See Remote Deploy window for details.", "OKOnly,SystemModal,Information,DefaultButton2", "Remote Deploy")
    }

    function ClearButtonClick 
    {
        $ClockTimer.Stop()
        $DeployTimer.Stop()
        Get-Job | Stop-Job | Remove-Job -Force
        if ($bClear.text -eq 'Clear')
        {
            $UpperLabel.text          = ""
            $LowerLabel.text          = ""
            $RemoteDeploy.ClientSize  = '400,300'
            $bDeploy.Enabled          = $true
            $StatusBar.Text           = 'Enter a Computer Name to get started'
        }
        else
        {
            $StatusBar.text   = 'Deployment was force stopped'
            $LowerLabel.text += "`n`n---------------`nForce stopped"
            $bClear.text      = 'Clear'
            $bClear.TabStop   = $true
        }
    }

    $ClockTimerTick =
    {
        $currenttime                 = get-date -Format  "yyyy-MM-dd HH:mm:ss"
        $elapsedtime                 = New-TimeSpan -Start $global:starttime -End $currenttime
        $UpperLabel.text             = "$($ProgressBar[$global:ProgressIndex])`n$elapsedTime"
        $global:ProgressIndex++
        if ( $global:ProgressIndex -ge $ProgressBar.Length ) { $global:ProgressIndex = 0 }
    }

    Add-Type -AssemblyName System.Windows.Forms
    [void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic") # Used for the popup notification after installation is finished
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $global:cred = $null

    #region Main Window

    $RemoteDeploy                    = New-Object system.Windows.Forms.Form
    $RemoteDeploy.ClientSize         = '400,300'
    $RemoteDeploy.text               = "Remote Deploy"
    $RemoteDeploy.TopMost            = $false
    $RemoteDeploy.SizeGripStyle      = "Hide"
    $RemoteDeploy.icon               = "\\storagedept\Dept\ITUserServices\Utilities\RemoteDeploy\Icon.ico"
    # $RemoteDeploy.FormBorderStyle    = "FixedSingle"
    $RemoteDeploy.StartPosition      = "CenterScreen"
    # $RemoteDeploy.TopMost            = $true

    $lHeader                          = New-Object system.Windows.Forms.Label
    $lHeader.text                     = "REMOTE DEPLOY"
    $lHeader.AutoSize                 = $true
    $lHeader.width                    = 25
    $lHeader.height                   = 10
    $lHeader.location                 = New-Object System.Drawing.Point(40,35)
    $lHeader.Font                     = 'Century Gothic,29,style=Bold'

    $bDummyButton                    = New-Object System.Windows.Forms.Button
    $bDummyButton.Width              = 0
    $bDummyButton.TabIndex           = 0
    $bDummyButton.Add_LostFocus({$bDummyButton.TabStop = $false})

    $tComputerName                   = New-Object system.Windows.Forms.TextBox
    $tComputerName.multiline         = $false
    $tComputerName.width             = 200
    $tComputerName.height            = 20
    $tComputerName.Text              = "Computer Name"
    $tComputerName.ForeColor         = 'DarkGray'
    $tComputerName.location          = New-Object System.Drawing.Point(50,115)
    $tComputerName.Font              = 'Microsoft Sans Serif,10'
    $tComputerName.Add_GotFocus({if($tComputerName.Text -eq 'Computer Name') {$tComputerName.Text = ''; $tComputerName.ForeColor = 'Black'}})
    $tComputerName.Add_LostFocus({if($tComputerName.Text -eq ''){$tComputerName.Text = 'Computer Name'; $tComputerName.ForeColor = 'Darkgray'}})

    $bComputerNameSearch             = New-Object system.Windows.Forms.Button
    $bComputerNameSearch.text        = "Search"
    $bComputerNameSearch.width       = 60
    $bComputerNameSearch.height      = 23
    $bComputerNameSearch.location    = New-Object System.Drawing.Point(290,115)
    $bComputerNameSearch.Font        = 'Microsoft Sans Serif,10'
    $bComputerNameSearch.Add_Click({Start-Process -WindowStyle Hidden \\storagedept\Dept\ITUserServices\Utilities\RemoteDeploy\runComputerLookup.cmd})

    $cPackage                        = New-Object system.Windows.Forms.ComboBox
    $cPackage.DropDownStyle          = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cPackage.width                  = 300
    $cPackage.height                 = 20
    $cPackage.location               = New-Object System.Drawing.Point(50,165)
    $cPackage.Font                   = 'Microsoft Sans Serif,9'
    $packageDir                      = "\\storagedept\Dept\ITUserServices\Utilities\RemoteDeploy\Packages"
    $packageArr                      = ,"Deployment Package" + (Get-ChildItem -Path $packageDir -force | Foreach-Object {$_.BaseName})
    $cPackage.Items.AddRange($packageArr)
    $cPackage.Item
    $cPackage.SelectedIndex          = 0
    
    $bDeploy                         = New-Object system.Windows.Forms.Button
    $bDeploy.text                    = "Deploy"
    $bDeploy.width                   = 130
    $bDeploy.height                  = 30
    $bDeploy.location                = New-Object System.Drawing.Point(50,215)
    $bDeploy.Font                    = 'Microsoft Sans Serif,10'
    $bDeploy.Add_Click({ DeployButtonClick })

    $bClear                          = New-Object system.Windows.Forms.Button
    $bClear.text                     = "Clear"
    $bClear.width                    = 130
    $bClear.height                   = 30
    $bClear.location                 = New-Object System.Drawing.Point(220,215)
    $bClear.Font                     = 'Microsoft Sans Serif,10'
    $bClear.Add_Click({ClearButtonClick})

    $StatusBar                       = New-Object Windows.Forms.StatusBar
    $StatusBar.Text                  = 'Enter a computer name and select package.'

    $UpperLabel                      = New-Object system.Windows.Forms.Label
    $UpperLabel.text                 = ""
    $UpperLabel.AutoSize             = $true
    $UpperLabel.width                = 25
    $UpperLabel.height               = 10
    $UpperLabel.location             = New-Object System.Drawing.Point(50,285)
    $UpperLabel.Font                 = 'Consolas,8'

    $LowerLabel                      = New-Object system.Windows.Forms.Label
    $LowerLabel.text                 = ""
    $LowerLabel.AutoSize             = $true
    $LowerLabel.width                = 25
    $LowerLabel.height               = 10
    $LowerLabel.location             = New-Object System.Drawing.Point(50,315)
    $LowerLabel.Font                 = 'Consolas,8'

    $RemoteDeploy.controls.AddRange( @($bDummyButton,$lHeader,$ComputerNameLabel,$tComputerName,$bComputerNameSearch,$PackageLabel,$cPackage,$bDeploy,$bClear,$UpperLabel,$LowerLabel,$StatusBar) )
    $RemoteDeploy.Add_Closed({ ClearButtonClick }) # runs when the form is closed

    #endregion

    #region Timers

    $ClockTimer                      = New-Object System.Windows.Forms.Timer
    $ClockTimer.Interval             = 100
    $ProgressBar                     = ">--------------","<>-------------","-<>------------","---<>----------","-------<>------","----------<>---","------------<>-","-------------<>","--------------<","-------------<>","------------<>-","----------<>---","-------<>------","---<>----------","-<>------------","-<>------------","<>-------------"
    $global:ProgressIndex            = 0
    $global:starttime                = ""
    $ClockTimer.Add_Tick($ClockTimerTick)
    $DeployTimer                     = New-Object System.Windows.Forms.Timer
    $DeployTimer.Interval            = 100

    #endregion

    #region Combo Box Window

    $inputComboForm                  = New-Object System.Windows.Forms.Form
    $inputComboForm.Text             = 'Remote Deploy'
    $inputComboForm.Size             = New-Object System.Drawing.Size(300,400)
    $inputComboForm.StartPosition    = 'CenterScreen'

    $lcInputArg                      = New-Object System.Windows.Forms.Label
    $lcInputArg.Location             = New-Object System.Drawing.Point(10,20)
    $lcInputArg.Size                 = New-Object System.Drawing.Size(280,20)
    $lcInputArg.Text                 = ""
    $inputComboForm.Controls.Add($lcInputArg)

    $cInputArg                       = New-Object System.Windows.Forms.ListBox
    $cInputArg.Location              = New-Object System.Drawing.Point(10,40)
    $cInputArg.Size                  = New-Object System.Drawing.Size(260,20)
    $cInputArg.Height                = 200

    $bOkay                           = New-Object System.Windows.Forms.Button
    $bOkay.Location                  = New-Object System.Drawing.Point(75,300)
    $bOkay.Size                      = New-Object System.Drawing.Size(75,23)
    $bOkay.Text                      = 'OK'
    $bOkay.DialogResult              = [System.Windows.Forms.DialogResult]::OK
    $inputComboForm.AcceptButton     = $bOkay
    $inputComboForm.Controls.Add($bOkay)

    #endregion
    
    
    [void]$RemoteDeploy.ShowDialog()
}

function RunAsAdmin
{
    $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
    $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
    if ($myWindowsPrincipal.IsInRole($adminRole)) { RemoteDeploy }
    else 
    {
        Start-Process "\\storagedept\Dept\ITUserServices\Utilities\RemoteDeploy\run.cmd" -Verb RunAs -WindowStyle Hidden
        Exit
    }
}

RunAsAdmin