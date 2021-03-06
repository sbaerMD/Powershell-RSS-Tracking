﻿#Arbeitsverzeichnis anlegen
$rootFolder = ($Env:USERPROFILE)
$folderName = 'PowershellRssReader'
$folder = Join-Path $rootFolder $folderName


$runScriptName = 'run.ps1'
$runScript = Join-Path $folder $runScriptName

$linksFolderName = 'feed-links'
$linksFolder = Join-Path $folder $linksFolderName

if( Test-Path $folder) {
    Write-Host "Die Ersteinrichtung wurde für diesen Nuter-Account schon durchgeführt ... Abbruch"
    exit
}

New-Item -Path $rootFolder -Name $folderName -ItemType "directory"
New-Item -Path $folder -Name $linksFolderName -ItemType "directory"


#Zugangsdaten sicher speichern
$usernameFileName = "username.txt"
$passwordFileName = "secure_password.txt"

$credential = Get-Credential
$credential.UserName |Set-Content (Join-Path $folder $usernameFileName)
$credential.Password | ConvertFrom-SecureString | Set-Content (Join-Path $folder $passwordFileName)

#Skript herunterladen und ablegen
$url = 'https://raw.githubusercontent.com/sbaerMD/Powershell-RSS-Tracking/main/run.ps1'
Invoke-WebRequest -Uri $url -OutFile $runScript


#Im Autostart ablegen
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
$batchContent = "@ECHO OFF`r`nchcp 65001`r`npowershell -File `"$($runScript)`" -ExecutionPolicy ByPass"
$startupFolder = Join-Path $rootFolder "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
$outfile = (Join-Path $startupFolder 'RssFeed-Run.bat')
[System.IO.File]::WriteAllLines($outfile, $batchContent, $Utf8NoBomEncoding)


Write-Host "Ersteinrichtung abgeschlossen"

explorer $linksFolder
