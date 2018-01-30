<#
	.SYNOPSIS
	Upload a file to the Nexus repository.

	.DESCRIPTION
	Upload a file to the Nexus repository.

	.PARAMETER Filename
	The file to be uploaded. Required.

	.PARAMETER RemoteFilename
	The file name to use on the remote server.  If not set, Filename is copied.

	.PARAMETER LocalDir
	The local directory where the file is located. If not set, the current directory is assumed.

	.PARAMETER UserID
	The Nexus user's ID. Required.

	.PARAMETER UserPass
	The Nexus user's Password. Required.
#>

Param(
	[Parameter(mandatory=$true, ValueFromPipeline=$false)]
	[string]$Filename,

	[Parameter(mandatory=$false, ValueFromPipeline=$false)]
	[string]$RemoteFilename,

	[Parameter(mandatory=$false, ValueFromPipeline=$false)]
	[string]$LocalDir,

	[Parameter(mandatory=$true, ValueFromPipeline=$false)]
	[string]$UserID,

	[Parameter(mandatory=$true, ValueFromPipeline=$false)]
	[string]$UserPass
)

if( [string]::IsNullOrWhiteSpace( $RemoteFilename ) ) {
	$RemoteFilename = $Filename
}

if( [string]::IsNullOrWhiteSpace( $LocalDir ) ) {
	$LocalDir = (Get-Item -Path ".\" -Verbose).FullName
}

# Calculate the destination URL.
$configFile = [System.IO.Path]::Combine($PSScriptRoot, "nexus-config.json")
$config = (Get-Content $configFile) -join "`n" | ConvertFrom-Json
$remoteUrl = $config.baseUrl.Trim()
if ( -not $remoteUrl.EndsWith('/') ) { $remoteUrl = $remoteUrl + '/' }
$remoteUrl = $remoteUrl + $RemoteFilename

# Calculate the path to upload from.
$localPath = [System.IO.Path]::Combine($LocalDir, $Filename)

# Create login credential
$securePassword = ConvertTo-SecureString $UserPass -AsPlainText -Force
$credential = New-Object PSCredential ($UserID, $securePassword)


$uploadParams = @{
	Uri = $remoteUrl;
	Method = 'PUT';
	Credential = $credential;
	InFile = $localPath;
}

$result = Invoke-RestMethod @uploadParams

Write-Host $result