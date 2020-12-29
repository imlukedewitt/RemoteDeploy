$returnCodes = $args[9]
Invoke-Expression $returnCodes

status connected

$extensionList = ""

$userFolders = Get-ChildItem -Path "C:\Users"
foreach ($userFolder in $userFolders)
{
    $extensionList += "------ $($userFolder.BaseName) ------`r`n`r`n"
    $extensionsPath = "$($userFolder.Fullname)\AppData\Local\Google\Chrome\User Data\Default\Extensions"
    if (Test-Path($extensionsPath) -ErrorAction SilentlyContinue)
    {
        $extensionFolders = Get-ChildItem -Path $extensionsPath
        foreach ($extensionFolder in $extensionFolders )
        {
            ##: Get the version specific folder within this extension folder
            $versionFolders = Get-ChildItem -Path "$($extensionFolder.FullName)"
            foreach ($versionFolder in $versionFolders)
            {
                ##: The extension folder name is the app id in the Chrome web store
                $appid = $extensionFolder.BaseName
    
                ##: First check the manifest for a name
                $name = ""
                if( (Test-Path -Path "$($versionFolder.FullName)\manifest.json") )
                {
                    try
                    {
                        $json = Get-Content -Raw -Path "$($versionFolder.FullName)\manifest.json" | ConvertFrom-Json
                        $name = $json.name
                    }
                    catch { $name = "" }
                }
    
                ##: If we find _MSG_ in the manifest it's probably an app
                if( $name -like "*MSG*" ) {
                    ##: Sometimes the folder is in en
                    if( Test-Path -Path "$($versionFolder.FullName)\_locales\en\messages.json" )
                    {
                        try
                        { 
                            $json = Get-Content -Raw -Path "$($versionFolder.FullName)\_locales\en\messages.json" | ConvertFrom-Json
                            $name = $json.appName.message
                            ##: Try a lot of different ways to get the name
                            if(!$name) { $name = $json.extName.message }
                            if(!$name) { $name = $json.extensionName.message }
                            if(!$name) { $name = $json.app_name.message }
                            if(!$name) { $name = $json.application_title.message }
                        }
                        catch { $name = "" }
                    }
                    ##: Sometimes the folder is en_US
                    if( Test-Path -Path "$($versionFolder.FullName)\_locales\en_US\messages.json" )
                    {
                        try
                        {
                            $json = Get-Content -Raw -Path "$($versionFolder.FullName)\_locales\en_US\messages.json" | ConvertFrom-Json
                            $name = $json.appName.message
                            ##: Try a lot of different ways to get the name
                            if(!$name) { $name = $json.extName.message }
                            if(!$name) { $name = $json.extensionName.message }
                            if(!$name) { $name = $json.app_name.message }
                            if(!$name) { $name = $json.application_title.message }
                        }
                        catch { $name = "" }
                    }
                }
    
                ##: If we can't get a name from the extension use the app id instead
                if( !$name ) { $name = "[$($appid)]" }
    
                ##: Dump to extension list
                $extensionList += "$name ($($versionFolder)) - $appid`r`n`r`n"
            }
        }
    }
    $extensionList += "`n`n"
}

customMessage $extensionList