<#
.SYNOPSIS
This script installs or updates the WinTuner module, allows the user to select Intune apps to deploy, and deploys them to a specified group.

.DESCRIPTION
The script performs the following tasks:
1. Checks if the WinTuner module is installed. If not, it installs the module from PSGallery.
2. If the module is installed, it checks if the installed version is the latest. If not, it updates the module.
3. Imports the WinTuner module.
4. Prompts the user to enter package IDs of apps to add to the deployment list.
5. Connects to WinTuner.
6. Creates a folder 'C:\Wintuner' if it does not exist.
7. Deploys the selected apps to the specified group.
8. Disconnects from WinTuner.
9. Cleans up all files in the 'C:\Wintuner' folder.

.PARAMETER GroupID
The Object ID of the group to which the apps will be deployed. This parameter is mandatory.

.EXAMPLE
.\Install-Available-Apps.ps1 -GroupID "your-group-id"
This example runs the script and deploys the selected apps to the specified group.

.NOTES
Ensure you have the necessary permissions to install/update modules and deploy apps using WinTuner.

.AUTHOR
Jermaine Zimmerman
DynamiQ IT
#>

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