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
        $DeployButton.Enabled    = $false
        $ClearButton.Enabled     = $false
        $global:startTime        = get-date -Format  "yyyy-MM-dd HH:mm:ss"
        $RemoteDeploy.ClientSize = '290,370'
        
        $ClockTimer.start()
        $LowerLabel.text  = "Copying installation files `nto $target"
        $installerDir     = (Get-Content "$packageDir\$selectedPackage.ps1" -First 1).Substring(1)
        $installerName    = $installerDir.Split("\")[-1]
        $copyInstallerJob = Start-Job -ArgumentList $target, $installerDir, $installerName -Name "CopyInstallerJob" -ScriptBlock `
        {
            $target        = $args[0]
            $installerDir  = $args[1]
            $installerName = $args[2]
            try 
            {
                if (!(Test-Path "\\$target\C$\RemoteDeploy")) {New-Item -ItemType Directory -Path "\\$target\C$\RemoteDeploy"}
                Copy-Item -Path $installerDir -Destination "\\$target\C$\RemoteDeploy\$installerName" -Force -Recurse
                Write-Output 0
            }
            catch { Write-Output 1,$_ }
        }
        Do {[System.Windows.Forms.Application]::DoEvents()} Until ($copyInstallerJob.State -eq "Completed")
        if ((get-job -Name "CopyInstallerJob" -IncludeChildJob | Receive-Job)[0] -eq -1)
        {
            $LowerLabel.text = "Could not copy installation files. Error message:`n$($jobOutput[1])"
            $ClockTimer.stop()
            $ClearButton.Enabled = $true
            return
        }

        $LowerLabel.text = "Files copied. Connecting to $target"
        Invoke-Command -ComputerName $target -FilePath "$packageDir\$selectedPackage.ps1" -AsJob
        $DeployTimer.Add_Tick($DeployTimerTick)        
        $DeployTimer.start()
    }

    $DeployTimerTick = 
    {
        $jobOutput = Get-Job -IncludeChildJob | Receive-Job
        if (!$jobOutput) {return}
        switch ($jobOutput[0])
        {
           -1 {$LowerLabel.text = "Connected"; return}
          -11 {$LowerLabel.text = "Installing"; return}
            0
            {
                $LowerLabel.text = "Installation completed successfully"
                
            }
            1 {$LowerLabel.text = "Failed!`n`nThe installation could not be verified"}
            2 {$LowerLabel.text = "Installation failed!`n`nThe MSI returned the following error:`n$($jobOutput[1])"}
            3 # Custom message
            {
                $LowerLabel.text = $jobOutput[1]
                if ($jobOutput[2] -eq 'continue') {return}
            }
        }
        $ClockTimer.stop()
        $DeployTimer.Remove_Tick($DeployTimerTick)
        $DeployTimer.stop()
        $ClearButton.Enabled = $true
        # (new-object -ComObject wscript.shell).Popup("Deployment complete! See window for status",0,"Remote Deploy",0)
    }

    function ClearButtonClick 
    {
        $ClockTimer.Stop()
        $DeployTimer.Stop()
        $UpperLabel.text               = ""
        $LowerLabel.text               = ""
        $ComputerNameTextBox.text      = ""
        $PackageComboBox.SelectedIndex = 0
        $RemoteDeploy.ClientSize       = '290,250'
        $DeployButton.Enabled          = $true
        $StatusBar.Text                = 'Enter a Computer Name to get started'
        Get-Job | Remove-Job -Force
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
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $RemoteDeploy                    = New-Object system.Windows.Forms.Form
    $RemoteDeploy.ClientSize         = '290,250'
    $RemoteDeploy.text               = "Remote Deploy"
    $RemoteDeploy.TopMost            = $false
    $RemoteDeploy.SizeGripStyle      = "Hide"
    # $RemoteDeploy.FormBorderStyle    = "FixedSingle"
    $RemoteDeploy.StartPosition      = "CenterScreen"
    $RemoteDeploy.TopMost            = $true

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
    $ComputerNameTextBox.Text        = "02130-l03009495"
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
    $PackageDir                      = "\\storagedept\Dept\ITUserServices\Utilities\Remote Deploy\Packages"
    $packageArr                      = ,"" + (Get-ChildItem -Path $PackageDir -force | Foreach-Object {$_.BaseName})
    $PackageComboBox.Items.AddRange($packageArr)
    $PackageComboBox.SelectedIndex   = 1
    
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
        Start-Process $PSScriptRoot\run.cmd -Verb RunAs -WindowStyle Hidden
        Exit
    }

}

RunAsAdmin