cls
$rootFolder = ($Env:USERPROFILE)
$folderName = 'PowershellRssReader'
$folder = Join-Path $rootFolder $folderName

if(Test-Path $folder) {
    Remove-Item $folder -Recurse -Force -ErrorAction Continue
}

$startupFolder = Join-Path $rootFolder "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
$batchFile = (Join-Path $startupFolder 'RssFeed-Run.bat')
if(Test-Path $batchFile) {
    Remove-Item -Path $batchFile -Force -ErrorAction Continue
}