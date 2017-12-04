function Main() {
    # Set folder variables
    $PubsRoot="D:\Content\PubsLocator"
    $BackupDir="D:\Content\_backups\PubsLocator"

    # Set tier/environment value based on server name
    $Computername=$env:computername
    If ($Computername -eq '_dev_servername') {
        $Tier="Dev" 
    } ElseIf ($Computername -eq '_qa_servername') {
        $Tier="QA"
    } ElseIf ($Computername -eq '_stage_servername') {
        $Tier="Stage"
    } ElseIf ($Computername -eq '_prod_servername') {
        $Tier="Prod"
    } Else {
        $Tier="Dev" 
    }
    
    # Create arrays of sites and/or folders that we want to deploy
    $SiteFolders = @("ApplicationManagement", "GUAM", "KIOSK", "NCIPL", "NCIPLAdmin", "NCIPLCC", "NCIPLex", "NCIPLLM", "PERT", "root")
    $OtherFolders = @("ReferenceDlls", "_errorLogs")
    $AllFolders = $SiteFolders + $OtherFolders
        
    Write-Host -foregroundcolor 'green' "Backing up sites to D:\Content\_backups\..."
    BackupSites
    Write-Host -foregroundcolor 'green' "Done."

    Write-Host -foregroundcolor 'green' "Copying site code from source..."
    CopySiteCode
    Write-Host -foregroundcolor 'green' "Done."

    Write-Host -foregroundcolor 'green' "Copying transformed configuration files..."
    DeployConfigs
    Write-Host -foregroundcolor 'green' "Done."

}


# Create a backup of the last deployed code
function BackupSites() {
    If (Test-Path $BackupDir){
        Remove-Item $BackupDir -Force -Recurse
    }
    Robocopy $PubsRoot $BackupDir /e
}


# For each site/application, robocopy site directories minus C# code, project/solution files, and svn files
function CopySiteCode() {
    foreach ($Folder in $AllFolders) {
        Robocopy .\$Folder "$PubsRoot\$Folder" /e /xf *.cs *.csproj *.sln appSettings.config connectionStrings.config sessionState.config PubsDeploy* /xd .svn
    }
}


# Deploy configs for specified tier
function DeployConfigs() {
    foreach ($Site in $SiteFolders) {
        Robocopy ".\_configurations\PubsLocator_$Tier\$Site" "$PubsRoot\$Site" /e
    }
}


# Run the Main() function
Main
