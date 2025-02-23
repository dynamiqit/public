param (
    [Parameter(Mandatory=$true)]
    [string]$GroupID # Group Object ID to deploy the app
)

# Check if WinTuner module is installed
if (-not (Get-Module -ListAvailable -Name WinTuner)) {
    Write-Host "Installing WinTuner module from PSGallery"
    # Install WinTuner module from PSGallery
    Install-Module -Name WinTuner -Repository PSGallery -Force
} else {
    # Check if the installed module is the latest version
    $installedModule = Get-Module -ListAvailable -Name WinTuner | Sort-Object Version -Descending | Select-Object -First 1
    $latestModule = Find-Module -Name WinTuner -Repository PSGallery
    if ($installedModule.Version -lt $latestModule.Version) {
        Write-Host "Updating WinTuner module to version $($latestModule.Version)"
        # Update the WinTuner module to the latest version
        Update-Module -Name WinTuner -Force
    }
}

# Import the WinTuner module
Import-Module WinTuner

# Set the default Intunes apps
$Appslist = @()

# Fill the applist
while ($true) {
    $appsearch = Read-Host "Enter the package ID of the app to add (or press Enter to finish)"
    if ([string]::IsNullOrWhiteSpace($appsearch)) {
        break
    }
    $app = Search-WtWinGetPackage -PackageId $appsearch | Out-GridView -Title "Select the app to add" -PassThru | Select-Object -ExpandProperty PackageId
    if ([string]::IsNullOrWhiteSpace($app)) {
        break
    }
    $Appslist += $app
}

Connect-WtWinTuner

# Create folder C:\Wintuner if it does not exist
$folderPath = 'C:\Wintuner'
if (-not (Test-Path -Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory
}


    foreach ($app in $Appslist) {
        New-WtWingetPackage -PackageId $app -PackageFolder $folderPath | Deploy-WtWin32App -AvailableFor $GroupID
    }

    # Disconnect
    Disconnect-WtWinTuner

    # Clean all files in $folderPath
    Get-ChildItem -Path $folderPath | Remove-Item -Recurse -Force