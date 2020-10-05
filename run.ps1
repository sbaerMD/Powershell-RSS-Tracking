cls
$RSS_DateFormat = 'de' #'de' oder 'en'

function main() {
    $folderName = 'PowershellRssReader'
    $rootFolder = (Join-Path ($Env:USERPROFILE) $folderName)
    checkInitialization ($rootFolder)

    $credentials = loadCredentials($rootFolder)
    $stateFolder = getStateFolder ($rootFolder) 
    $linksFolderName = 'feed-links'
    $credentials = loadCredentials ($rootFolder)
    
    $NewsIn = @()
    $NoNewsIn = @()
       
    resolveFeeds (Join-Path $rootFolder $linksFolderName) | foreach {
        $state = getStateFor $stateFolder $_.Name
        $actualState = getLastRssItem $_.Url $credentials
        
        if($actualState.From -gt $state) { #es gibt Neuigkeiten
            $NewsIn += "$($_.Name): $($actualState.Title)"
            #und wieder speichern
            $state = date2string($actualState.From)
            setStateFor $stateFolder $_.Name $state
        } 
        else {
            $NoNewsIn += $_.Name
            $state = date2string(get-date)
            setStateFor $stateFolder $_.Name $state
        }       
    }

    $fileName = [Guid]::NewGuid().ToString()
    $file = Join-Path $rootFolder "$($fileName).txt";

    $content = "Zusammenfassung der RSS-Feeds`r`n"
    $content += "################################`r`n`r`n"

    if($NewsIn.Length -gt 0) {
        $content += "Neuigkeiten in folgenden RSS-Feeds gefunden:`r`n"
        $content += "--------------------------------------------`r`n"
        $NewsIn | foreach {
            $content += "$($_)`r`n"
        }        
    }
    $content += "`r`n`r`n`r`n"
    if($NoNewsIn.Length -gt 0) {
        $content += "keine Neuigkeiten in folgenden RSS-Feeds:`r`n"
        $content += "-----------------------------------------`r`n"
        $NoNewsIn | foreach {
            $content += "$($_), "
        }        
    }

    Set-Content -Path $file -Value $content

    $proc = Start-Process "notepad" -ArgumentList $file -PassThru 
    $proc.WaitForExit()

    Remove-Item $file -Force -ErrorAction Ignore
}

function checkInitialization($folder) {
    if( -not(Test-Path $folder)) {
        Write-Host "!!Abbruch!!`nBitte zuerst die Ersteinrichtung für diesen Nuter-Account durchführen!"
        exit
    }
}

function loadCredentials($folder) {
    $usernameFileName = "username.txt"
    $passwordFileName = "secure_password.txt"

    $username =  Get-Content (Join-Path $folder $usernameFileName)
    $password = Get-Content (Join-Path $folder $passwordFileName) | ConvertTo-SecureString
    $credential = New-Object System.Management.Automation.PsCredential($username, $password)
    $credential
}

function resolveFeeds($folder) {
    gci $folder -Filter "*.url" | foreach {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $url = (gc $_.FullName | Where {$_ -match "URL="}) | Foreach {$_.ToString().Substring(4)}
        @{Name = $name; Url = $url}
    }
}


function getStateFolder($folder) {
    
    $stateFolderName = 'states'
    $stateFolder = Join-Path $folder $stateFolderName
    
    if( -not(Test-Path $stateFolder)) {
        New-Item -Path $folder -Name $stateFolderName -ItemType "directory"
    }
    $stateFolder
}
function getStateFor($stateFolder, $feedName) {
    
    $stateFile = Join-Path $stateFolder "$($feedName)-state.txt" 
    if(Test-Path $stateFile) {
        $content = Get-Content $stateFile
        string2date $content
    } else {
        $null        
    }    
}
function setStateFor($stateFolder, $feedName, $state) {
    
    $stateFile = Join-Path $stateFolder "$($feedName)-state.txt" 
    Set-Content -Path $stateFile -Value $state -Force
   
}

function getLastRssItem($url, $credentials) {
    
    $lastTitle = ''
    $lastDateValue = $null
    Write-Host "Prüfe '$($url)'"
    
    Invoke-RestMethod -Uri $url -Credential $credentials | foreach {
        $dateString = $_.PubDate  
        #$_.Title      
        $dateValue = string2date $dateString
        if($dateValue -gt $lastDateValue) {
            $lastDateValue = $dateValue
            $lastTitle = $_.Title
        }
    }   
    
    @{
        Title = $lastTitle
        From = $lastDateValue
    }
}

function getNullDate {
    Get-Date -Day 1 -Month 1 -Year 1 -Hour 0 -Minute 0 -Second 0
}

function string2date($dateString) {
    $loc = localizationInfo
    [datetime]::ParseExact($dateString, $loc.DateFormat, $loc.Culture)
}
function date2string($date) {
    $loc = localizationInfo 
    $date.ToString($loc.DateFormat, $loc.Culture)
}

function localizationInfo() {
    if( $RSS_DateFormat -eq 'de') {
        localizationInfo_DE 
    } elseif($RSS_DateFormat -eq 'en') {
    localizationInfo_EN
    } else {
        Write-Host "RSS_DateFormat '$($RSS_DateFormat)' wird nicht unterstützt!"
        exit
    }
}

function localizationInfo_DE() {    
   @{
        Culture = New-Object system.globalization.cultureinfo("de-DE")
        DateFormat = "ddd dd MMM yyyy HH:mm:ss zzzz"
    }
}
function localizationInfo_EN() {
    @{
        Culture = New-Object system.globalization.cultureinfo("en-GB")
        DateFormat = "ddd, dd MMM yyyy HH:mm:ss zzzz"
    }
}

main


