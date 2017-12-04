function Main() {
    # The WebAdministration module requires elevated privileges.
    $isAdmin = Is-Admin
    if( $isAdmin ) {
        Write-Host -foregroundcolor 'green' "Starting..."
        Import-Module WebAdministration

        Write-Host -foregroundcolor 'magenta' "Removing old sites and AppPools..."
        ClearOldSites
        Write-Host -foregroundcolor 'magenta' "Done."
        
        Write-Host -foregroundcolor 'green' "Adding AppPools..."
        AddAppPools
        Write-Host -foregroundcolor 'green' "Done."
        
        Write-Host -foregroundcolor 'green' "Adding sites..."
        AddSites
        Write-Host -foregroundcolor 'green' "Done."
    } 
    else {
        Write-Host -foregroundcolor 'red' "This script must be run from an AA account."
    }   
}

# Add and configure Application Pools
function AddAppPools {

    # Create GUAM AppPool with settings
    New-WebAppPool -Name "GUAM"
    $GuamAppPool = Get-Item IIS:\AppPools\GUAM
    $GuamAppPool.managedRuntimeVersion = "v4.0"
    $GuamAppPool.enable32BitAppOnWin64 = "True"
    $GuamAppPool | Set-Item
    
    # Create PubsLocator AppPool with settings
    New-WebAppPool -Name "PubsLocator"
    $PubsAppPool = Get-Item IIS:\AppPools\PubsLocator
    $PubsAppPool.managedRuntimeVersion = "v2.0"
    $PubsAppPool.enable32BitAppOnWin64 = "True"
    $PubsAppPool | Set-Item
}


# Add and configure Application Pools
function AddSites {

    $RootFilePath = 'D:\Content\PubsLocator'
    $RootImagePath = 'D:\PubsRuntimeFiles\cissecure\ncipubs\prodimages'
    $WinAuthentication = '/system.WebServer/security/authentication/windowsAuthentication'
    $AnonAuthentication = '/system.WebServer/security/authentication/anonymousAuthentication'
    
    # Create NCIPL site and HTTPS binding    
    Write-Host -foregroundcolor 'blue' "NCIPL / External setup"
    New-Website -Name "PubsLocator" -Port 443 -IPAddress "*" -HostHeader "xxxx.cancer.gov" -PhysicalPath "$RootFilePath\root" -ApplicationPool "PubsLocator" -Ssl
    Set-WebConfigurationProperty -Filter $AnonAuthentication -Name "enabled" -Value true -Location "PubsLocator"
    Set-WebConfigurationProperty -Filter $WinAuthentication -Name "enabled" -Value false -Location "PubsLocator"
        New-WebApplication -Name "NCIPL" -Site "PubsLocator" -PhysicalPath "$RootFilePath\NCIPL" -ApplicationPool "PubsLocator"
            New-WebVirtualDirectory -Name "pubimages" -Site "PubsLocator" -Application "NCIPL" -PhysicalPath $RootImagePath 
            New-WebApplication -Name "GUAM" -Site "PubsLocator\NCIPL" -PhysicalPath "$RootFilePath\GUAM" -ApplicationPool "GUAM"
        New-WebApplication -Name "NCIPLEX" -Site "PubsLocator" -PhysicalPath "$RootFilePath\NCIPLEX" -ApplicationPool "PubsLocator"    
            New-WebVirtualDirectory -Name "pubimages" -Site "PubsLocator" -Application "NCIPLEX" -PhysicalPath $RootImagePath 
        New-WebApplication -Name "VPR" -Site "PubsLocator" -PhysicalPath "$RootFilePath\KIOSK" -ApplicationPool "PubsLocator"
            New-WebVirtualDirectory -Name "pubimages" -Site "PubsLocator" -Application "VPR" -PhysicalPath $RootImagePath 
        New-WebVirtualDirectory -Name "pdf" -Site "PubsLocator" -PhysicalPath "D:\PubsRuntimeFiles\cissecure\PDF"
    Start-Website -Name "PubsLocator"
}


# Remove old sites and AppPools to prevent errors on site creation
function ClearOldSites {
    if (Test-Path "IIS:\AppPools\PubsLocator") { Remove-WebAppPool -Name "PubsLocator" }
    if (Test-Path "IIS:\AppPools\GUAM") { Remove-WebAppPool -Name "GUAM" }
    if (Test-Path "IIS:\Sites\PubsLocator") { Remove-Website -Name "PubsLocator" }
}


# Verify that the script is being run with admin privileges
function Is-Admin {
    $id = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $id.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Run the Main() function
Main
