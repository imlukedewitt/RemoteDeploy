function RemoteDeploy
{
    function DeployButtonClick
    {
        $target          = $ComputerNameTextBox.Text.Trim().ToUpper()
        $selectedPackage = $PackageComboBox.SelectedItem
        if( $target -eq "" -or $PackageComboBox.SelectedIndex -eq 0 )
        {
            $StatusBar.text = "ERROR: Please complete all fields before deploying"
            return
        }

        $inputInstructions = (Get-Content "$packageDir\$selectedPackage.ps1") | ForEach-Object { $_.substring(1) }
        if (!($global:cred) -and $inputInstructions[0] -eq "get credentials")
        {
            $global:cred = Get-Credential -Message "Enter your lion login and password"
            $global:cred = New-Object System.Management.Automation.PSCredential ("southern\$($global:cred.UserName)", $global:cred.Password)
            $inputInstructions = $inputInstructions[1..($inputInstructions.length-1)]
        }

        
        if ($inputInstructions[0] -match "^[0-9]*$") # If the first line of the package is a number, get more infomation from the user
        {
            $packageArgs = @($null) * ($inputInstructions[0] + 1)
            $packageArgs[0] = $global:cred
            for ($i = 1; $i -le $inputInstructions[0]; $i++)
            {
                $inputReqs = $inputInstructions[$i] -split "  "
                if ($inputReqs[0] -eq 'networkshare')
                {
                    $networkPath = $inputReqs[1]
                    $message = $inputReqs[2]
                    $options = net view $networkPath
                    $options = $options[7..($options.length - 3)]
                    $options = foreach ($j in $options) { if ($j -match '.*[a-zA-Z].*') {write-output $j}}
                    $options = foreach ($j in $options) { Write-Output ($j -split "  ")[0] }

                    [void] $inputComboList.Items.AddRange($options)
                    $inputComboForm.Controls.Add($inputComboList)
                    $inputComboForm.Topmost = $true
                    $inputComboLabel.text = $message
                    $result = $inputComboForm.ShowDialog()
                    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {$packageArgs[$i] = $inputComboList.SelectedItem}
                    $inputComboList.Items.Clear()
                }
                elseif ($inputReqs[0] -eq 'directory')
                {
                    $networkPath = $inputReqs[1]
                    $message = $inputReqs[2]
                    $options = (get-childitem $networkPath).name

                    [void] $inputComboList.Items.AddRange($options)
                    $inputComboForm.Controls.Add($inputComboList)
                    $inputComboForm.Topmost = $true
                    $inputComboLabel.text = $message
                    $result = $inputComboForm.ShowDialog()
                    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {$packageArgs[$i] = $inputComboList.SelectedItem}
                    $inputComboList.Items.Clear()
                }
                else
                {
                    $packageArgs[$i] = [Microsoft.VisualBasic.Interaction]::InputBox($inputInstructions[$i],"Remote Deploy")
                }
            }
            $LowerLabel.text = $packageArgs
        }
        else { $packageArgs = $global:cred }

        $DeployButton.Enabled    = $false
        $ClearButton.Enabled     = $false
        $global:startTime        = get-date -Format  "yyyy-MM-dd HH:mm:ss"
        $RemoteDeploy.ClientSize = '290,370'
        $ClockTimer.start()
        
        $LowerLabel.text = "Connecting to $target"
        try { Invoke-Command -ComputerName $target -FilePath "$packageDir\$selectedPackage.ps1" -AsJob -ArgumentList $packageArgs }
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
        [Microsoft.VisualBasic.Interaction]::MsgBox("Deployment finished! See Remote Deploy window for details.", "OKOnly,SystemModal,Information,DefaultButton2", "Remote Deploy")
        $ClearButton.Enabled = $true
    }

    function ClearButtonClick 
    {
        $ClockTimer.Stop()
        $DeployTimer.Stop()
        $UpperLabel.text               = ""
        $LowerLabel.text               = ""
        $RemoteDeploy.ClientSize       = '290,250'
        $DeployButton.Enabled          = $true
        $StatusBar.Text                = 'Enter a Computer Name to get started'
        Get-Job | Stop-Job | Remove-Job -Force
    }

    $ClockTimerTick =
    {
        $currenttime                 = get-date -Format  "yyyy-MM-dd HH:mm:ss"
        $elapsedtime                 = New-TimeSpan -Start $global:starttime -End $currenttime
        $UpperLabel.text             = "$($ProgressBar[$global:ProgressIndex])`n$elapsedTime"
        $global:ProgressIndex++
        if ( $global:ProgressIndex -ge $ProgressBar.Length ) { $global:ProgressIndex = 0 }
    }

    $global:cred = $null

    Add-Type -AssemblyName System.Windows.Forms
    [void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic") # Used for the popup notification after installation is finished
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $RemoteDeploy                    = New-Object system.Windows.Forms.Form
    $RemoteDeploy.ClientSize         = '290,250'
    $RemoteDeploy.text               = "Remote Deploy"
    $RemoteDeploy.TopMost            = $false
    $RemoteDeploy.SizeGripStyle      = "Hide"
    $RemoteDeploy.icon               = "\\storagedept\Dept\ITUserServices\Utilities\RemoteDeploy\Icon.ico"
    # $RemoteDeploy.FormBorderStyle    = "FixedSingle"
    $RemoteDeploy.StartPosition      = "CenterScreen"
    # $RemoteDeploy.TopMost            = $true

    $ComputerNameLabel               = New-Object system.Windows.Forms.Label
    $ComputerNameLabel.text          = "Computer Name:"
    $ComputerNameLabel.AutoSize      = $true
    $ComputerNameLabel.width         = 25
    $ComputerNameLabel.height        = 10
    $ComputerNameLabel.location      = New-Object System.Drawing.Point(20,20)
    $ComputerNameLabel.Font          = 'Microsoft Sans Serif,10'

    $ComputerNameTextBox             = New-Object system.Windows.Forms.TextBox
    $ComputerNameTextBox.multiline   = $false
    $ComputerNameTextBox.width       = 250
    $ComputerNameTextBox.height      = 20
    $ComputerNameTextBox.Text        = ""
    $ComputerNameTextBox.location    = New-Object System.Drawing.Point(20,40)
    $ComputerNameTextBox.Font        = 'Microsoft Sans Serif,10'

    $PackageLabel                    = New-Object system.Windows.Forms.Label
    $PackageLabel.text               = "Deployment Package:"
    $PackageLabel.AutoSize           = $true
    $PackageLabel.width              = 25
    $PackageLabel.height             = 10
    $PackageLabel.location           = New-Object System.Drawing.Point(20,90)
    $PackageLabel.Font               = 'Microsoft Sans Serif,10'

    $PackageComboBox                 = New-Object system.Windows.Forms.ComboBox
    $PackageComboBox.DropDownStyle   = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $PackageComboBox.width           = 250
    $PackageComboBox.height          = 20
    $PackageComboBox.location        = New-Object System.Drawing.Point(20,110)
    $PackageComboBox.Font            = 'Microsoft Sans Serif,9'
    $PackageDir                      = "\\storagedept\Dept\ITUserServices\Utilities\RemoteDeploy\Packages"
    $packageArr                      = ,"" + (Get-ChildItem -Path $PackageDir -force | Foreach-Object {$_.BaseName})
    $PackageComboBox.Items.AddRange($packageArr)
    $PackageComboBox.SelectedIndex   = 0shut
    
    $DeployButton                    = New-Object system.Windows.Forms.Button
    $DeployButton.text               = "Deploy"
    $DeployButton.width              = 115
    $DeployButton.height             = 30
    $DeployButton.location           = New-Object System.Drawing.Point(20,170)
    $DeployButton.Font               = 'Microsoft Sans Serif,10'

    $ClearButton                     = New-Object system.Windows.Forms.Button
    $ClearButton.text                = "Clear"
    $ClearButton.width               = 115
    $ClearButton.height              = 30
    $ClearButton.location            = New-Object System.Drawing.Point(150,170)
    $ClearButton.Font                = 'Microsoft Sans Serif,10'

    $StatusBar                       = New-Object Windows.Forms.StatusBar
    $StatusBar.Text                  = 'Enter a computer name and select package.'

    $UpperLabel                      = New-Object system.Windows.Forms.Label
    $UpperLabel.text                 = ""
    $UpperLabel.AutoSize             = $true
    $UpperLabel.width                = 25
    $UpperLabel.height               = 10
    $UpperLabel.location             = New-Object System.Drawing.Point(20,230)
    $UpperLabel.Font                 = 'Consolas,8'

    $LowerLabel                      = New-Object system.Windows.Forms.Label
    $LowerLabel.text                 = ""
    $LowerLabel.AutoSize             = $true
    $LowerLabel.width                = 25
    $LowerLabel.height               = 10
    $LowerLabel.location             = New-Object System.Drawing.Point(20,270)
    $LowerLabel.Font                 = 'Consolas,8'

    $RemoteDeploy.controls.AddRange( @($ComputerNameLabel,$ComputerNameTextBox,$PackageLabel,$PackageComboBox,$DeployButton,$ClearButton,$UpperLabel,$LowerLabel,$StatusBar) )

    $ClockTimer                      = New-Object System.Windows.Forms.Timer
    $ClockTimer.Interval             = 100
    $ProgressBar                     = ">--------------","<>-------------","-<>------------","---<>----------","-------<>------","----------<>---","------------<>-","-------------<>","--------------<","-------------<>","------------<>-","----------<>---","-------<>------","---<>----------","-<>------------","-<>------------","<>-------------"
    $global:ProgressIndex            = 0
    $global:starttime                = ""
    $ClockTimer.Add_Tick($ClockTimerTick)

    $DeployTimer                     = New-Object System.Windows.Forms.Timer
    $DeployTimer.Interval            = 100

    $inputComboForm                  = New-Object System.Windows.Forms.Form
    $inputComboForm.Text             = 'Remote Deploy'
    $inputComboForm.Size             = New-Object System.Drawing.Size(300,400)
    $inputComboForm.StartPosition    = 'CenterScreen'

    $inputComboLabel                 = New-Object System.Windows.Forms.Label
    $inputComboLabel.Location        = New-Object System.Drawing.Point(10,20)
    $inputComboLabel.Size            = New-Object System.Drawing.Size(280,20)
    $inputComboLabel.Text            = ""
    $inputComboForm.Controls.Add($inputComboLabel)

    $inputComboList                  = New-Object System.Windows.Forms.ListBox
    $inputComboList.Location         = New-Object System.Drawing.Point(10,40)
    $inputComboList.Size             = New-Object System.Drawing.Size(260,20)
    $inputComboList.Height           = 200

    $OKButton                        = New-Object System.Windows.Forms.Button
    $OKButton.Location               = New-Object System.Drawing.Point(75,300)
    $OKButton.Size                   = New-Object System.Drawing.Size(75,23)
    $OKButton.Text                   = 'OK'
    $OKButton.DialogResult           = [System.Windows.Forms.DialogResult]::OK
    $inputComboForm.AcceptButton     = $OKButton
    $inputComboForm.Controls.Add($OKButton)

    $DeployButton.Add_Click({ DeployButtonClick })
    $ClearButton.Add_Click({ ClearButtonClick })
    $RemoteDeploy.Add_Closed({ ClearButtonClick }) #runs when the form is closed
    $RemoteDeploy.ShowDialog()
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