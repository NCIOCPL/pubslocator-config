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

    # Create ApplicationManagement AppPool with settings
    New-WebAppPool -Name "ApplicationManagement"
    $GuamAppPool = Get-Item IIS:\AppPools\ApplicationManagement
    $GuamAppPool.managedRuntimeVersion = "v4.0"
    $GuamAppPool.enable32BitAppOnWin64 = "True"
    $GuamAppPool | Set-Item
    
    # Create PubsLocator Admin AppPool with settings    
    New-WebAppPool -Name "PubsAdmin"
    $PubsAdminAppPool = Get-Item IIS:\AppPools\PubsAdmin
    $PubsAdminAppPool.managedRuntimeVersion = "v2.0"
    $PubsAdminAppPool.enable32BitAppOnWin64 = "True"
    $PubsAdminAppPool | Set-Item
}


# Add and configure Application Pools
function AddSites {

    $RootFilePath = 'D:\Content\PubsLocator'
    $RootImagePath = 'D:\PubsRuntimeFiles\cissecure\ncipubs\prodimages'
    $WinAuthentication = '/system.WebServer/security/authentication/windowsAuthentication'
    $AnonAuthentication = '/system.WebServer/security/authentication/anonymousAuthentication'
    $BasicAuthentication = '/system.WebServer/security/authentication/basicAuthentication'

    # Create ApplicationManagement site and HTTPS binding
    Write-Host -foregroundcolor 'blue' "ApplicationManagement setup"
    New-Website -Name "ApplicationManagement" -Port 443 -IPAddress "*" -HostHeader "xxxx.cancer.gov" -PhysicalPath "$RootFilePath\ApplicationManagement" -ApplicationPool "ApplicationManagement" -Ssl     
    Set-WebConfigurationProperty -Filter $AnonAuthentication -Name "enabled" -Value true -Location "ApplicationManagement"
    Set-WebConfigurationProperty -Filter $WinAuthentication -Name "enabled" -Value false -Location "ApplicationManagement"
    Start-Website -Name "ApplicationManagement"

    # Create NCIPLAdmin site and HTTPS binding
    Write-Host -foregroundcolor 'blue' "NCIPLAdmin / Internal setup"
    New-Website -Name "PubsAdmin" -Port 443 -IPAddress "*" -HostHeader "xxxx.cancer.gov" -PhysicalPath "$RootFilePath\root" -ApplicationPool "PubsAdmin" -Ssl     
    Set-WebConfigurationProperty -Filter $AnonAuthentication -Name "enabled" -Value true -Location "PubsAdmin"
    Set-WebConfigurationProperty -Filter $WinAuthentication -Name "enabled" -Value false -Location "PubsAdmin"
        New-WebApplication -Name "NCIPLCC" -Site "PubsAdmin" -PhysicalPath "$RootFilePath\NCIPLCC" -ApplicationPool "PubsAdmin"
            New-WebVirtualDirectory -Name "pubimages" -Site "PubsAdmin" -Application "NCIPLCC" -PhysicalPath $RootImagePath 
        New-WebApplication -Name "NCIPLLM" -Site "PubsAdmin" -PhysicalPath "$RootFilePath\NCIPLLM" -ApplicationPool "PubsAdmin"
            New-WebVirtualDirectory -Name "pubimages" -Site "PubsAdmin" -Application "NCIPLLM" -PhysicalPath $RootImagePath 
        New-WebApplication -Name "NCIPLAdmin" -Site "PubsAdmin" -PhysicalPath "$RootFilePath\NCIPLAdmin" -ApplicationPool "PubsAdmin" 
        New-WebApplication -Name "PERT" -Site "PubsAdmin" -PhysicalPath "$RootFilePath\PERT" -ApplicationPool "PubsAdmin"
        New-WebVirtualDirectory -Name "pdf" -PhysicalPath "D:\PubsRuntimeFiles\cissecure\PDF" -Site "PubsAdmin"
    Start-Website -Name "PubsAdmin"
}


# Remove old sites and AppPools to prevent errors on site creation
function ClearOldSites {
    if (Test-Path "IIS:\AppPools\ApplicationManagement") { Remove-WebAppPool -Name "ApplicationManagement" }
    if (Test-Path "IIS:\AppPools\PubsAdmin") { Remove-WebAppPool -Name "PubsAdmin" }
    if (Test-Path "IIS:\Sites\ApplicationManagement") { Remove-Website -Name "ApplicationManagement" }
    if (Test-Path "IIS:\Sites\PubsAdmin") { Remove-Website -Name "PubsAdmin" }
}


# Verify that the script is being run with admin privileges
function Is-Admin {
    $id = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $id.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Run the Main() function
Main
