## Config
$computerNameListPath = "redacted"

Function ComputerLookup
{

    ##
    # $l* indicates a label object for the corresponsing object, *
    # $t indicates a text box object
    # $c indicates a combo box object
    # $b indicates a button object
    # $a indicates an array (usually for declaring items in a combo box object)
    # $s indicates a status bar object
    # $g indicates a grid / listview object
    # $m indicates a message for output and troubleshooting
    # $v indicates a value for output and manipluation
    ##

    function ClearGrid
    {
        for ($i = 0; $i -lt $gNameGrid.RowCount; $i++)
        {
            $gNameGrid[0,$i].value = ''
            $gNameGrid[1,$i].value = ''
        }
    }

    function ResetForm
    {
        $NameLookupForm.ClientSize = '400,325'
        $cBuilding.SelectedIndex   = 0
        $tRoom.text                = 'Room number / Username'
        $tRoom.ForeColor           = 'Darkgray'
        $StatusBar.text            = 'Enter a building and room number.'
        ClearGrid
    }

    function SearchNames
    {
        # Error checking and setup
        if ($tRoom.text -eq 'Room number / Username') {$StatusBar.text = 'ERROR: Please enter a search filter'; return}
        if ($tRoom.text -match '^[a-zA-Z]') {$searchQuery = $tRoom.text; $cBuilding.SelectedIndex = 0}
        else {$searchQuery = ($cBuilding.selecteditem).substring(0,2) + $tRoom.text}
        $NameLookupForm.ClientSize = '400,635'

        # Get matching names from a text list. PDQ updates this list every morning.
        $allComputerNames = Get-Content -Path $computerNameListPath
        $matchingComputerNames = $allComputerNames | Where-Object {$_ -like "*$searchQuery*"}
        ClearGrid
        if(!$matchingComputerNames) {$gNameGrid[0,0].value = "No results found" ; return}
        if ($matchingComputerNames.getType() -like 'String')
        {
            $gNameGrid[0,0].value = $matchingComputerNames.Split(' ')[0]
            $gNameGrid[1,0].value = $matchingComputerNames.Split(' ')[1]
        }
        else
        {
            if ($matchingComputerNames.Length -gt $gNameGrid.RowCount) {$gNameGrid.rows.add($matchingComputerNames.Length - $gNameGrid.RowCount)}
            for ($i = 0; $i -lt $matchingComputerNames.Length; $i++)
            {
                $gNameGrid[0,$i].value = $matchingComputerNames[$i].Split(' ')[0] 
                $gNameGrid[1,$i].value = $matchingComputerNames[$i].Split(' ')[1]
            }
        }
    }

    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $NameLookupForm                  = New-Object system.Windows.Forms.Form
    $NameLookupForm.ClientSize       = '400,325'
    $NameLookupForm.text             = "Computer Name Lookup"
    $NameLookupForm.StartPosition    = "CenterScreen"
    $NameLookupForm.TopMost          = $false

    $cBuilding                       = New-Object system.Windows.Forms.ComboBox
    $cBuilding.DropDownStyle         = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cBuilding.width                 = 300
    $cBuilding.height                = 20
    $cBuilding.location              = New-Object System.Drawing.Point(50,138)
    $cBuilding.Font                  = 'Microsoft Sans Serif,10'
    $cBuildingList                   = @("Select building","01 - Server Room","02 - Plaster","03 - Physical Plant","04 - Ummel","05 - Kuhn","06 - Justice New Side","07 - Justice Old Side","08 - Stegge Apartments","09 - Blaine Hall","10 - McCormick","11 - East Hall","12 - Webster Hall","13 - FINART (music/art)","14 - TETPAC (theater)","15 - Football Stadium","16 - Taylor Hall","17 - Leggett and Platt","18 - Young Gym","19 - Hearnes Hall","20 - Library","21 - Reynolds Hall","22 - BSC","23 - Alumni Center","24 - Mansion Annex (URM)","25 - Student Life Center","26 - Lion Cub Academy","27 - Nixon Hall","28 - HSB","29 - Fieldhouse (North Endzone Facility)","30 - Baseball Field","31 - FEMA Shelter Facility","32 - Apartment Quads","33 - Annex (Trailers)")
    $cBuilding.Items.AddRange($cBuildingList)
    $cBuilding.SelectedIndex         = 0
    $cBuilding.TabIndex              = 0

    $tRoom                           = New-Object system.Windows.Forms.TextBox
    $tRoom.multiline                 = $false
    $tRoom.text                      = "Room number / Username"
    $tRoom.width                     = 300
    $tRoom.height                    = 20
    $tRoom.location                  = New-Object System.Drawing.Point(50,190)
    $tRoom.Font                      = 'Microsoft Sans Serif,10'
    $tRoom.ForeColor                 = 'Darkgray'
    $tRoom.Add_GotFocus({if($tRoom.Text -eq 'Room number / Username') {$tRoom.Text = ''; $tRoom.ForeColor = 'Black'}})
    $tRoom.Add_LostFocus({if($troom.Text -eq ''){$tRoom.Text = 'Room number / Username'; $tRoom.ForeColor = 'Darkgray'}})

    $bSearch                         = New-Object system.Windows.Forms.Button
    $bSearch.text                    = "Search"
    $bSearch.width                   = 130
    $bSearch.height                  = 30
    $bSearch.location                = New-Object System.Drawing.Point(50,243)
    $bSearch.Font                    = 'Microsoft Sans Serif,10'
    $bSearch.Add_Click({SearchNames})

    $bClear                          = New-Object system.Windows.Forms.Button
    $bClear.text                     = "Clear"
    $bClear.width                    = 130
    $bClear.height                   = 30
    $bClear.location                 = New-Object System.Drawing.Point(220,243)
    $bClear.Font                     = 'Microsoft Sans Serif,10'
    $bClear.Add_Click({ResetForm})

    $gNameGrid                       = New-Object system.Windows.Forms.DataGridView
    $gNameGrid.RowHeadersVisible     = $false
    $gNameGrid.width                 = 300
    $gNameGrid.height                = 255
    $gNameGrid.ColumnCount           = 2
    $gNameGrid.RowCount              = 11
    $gNameGrid.ColumnHeadersVisible  = $true
    $gNameGrid.Columns[0].Name       = "Computer name"
    $gNameGrid.Columns[0].Width      = 145
    $gNameGrid.Columns[1].Name       = "Last user"
    $gNameGrid.Columns[1].Width      = 135
    $gNameGrid.location              = New-Object System.Drawing.Point(50,325)
    $gNameGrid.TabStop               = $false

    $header                          = New-Object system.Windows.Forms.Label
    $header.text                     = "NAME LOOKUP"
    $header.AutoSize                 = $true
    $header.width                    = 25
    $header.height                   = 10
    $header.location                 = New-Object System.Drawing.Point(40,40)
    $header.Font                     = 'Century Gothic,32,style=Bold'

    $StatusBar                       = New-Object Windows.Forms.StatusBar
    $StatusBar.Text                  = 'Enter a building and room number.'

    $NameLookupForm.controls.AddRange(@($cBuilding,$tRoom,$bSearch,$bClear,$header,$StatusBar,$gNameGrid))

    [void]$NameLookupForm.ShowDialog()

}

ComputerLookup