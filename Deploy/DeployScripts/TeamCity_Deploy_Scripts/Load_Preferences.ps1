Param(
[Parameter(Mandatory=$false)] [String]$Username,
[Parameter(Mandatory=$false)] [String]$RepoPath,
[Parameter(Mandatory=$false)] [String]$Password,
[Parameter(Mandatory=$false)] [String]$HostName,
[Parameter(Mandatory=$false)] [String]$HomePath,
[Parameter(Mandatory=$false)] [String]$InfodbaPWD,
[Parameter(Mandatory=$false)][String]$BuildNumber,
[Parameter(Mandatory=$false)] [String]$DeployBackupPath,
[Parameter(Mandatory=$false)] [String]$BuildType,
[Parameter(Mandatory=$false)] [String]$EnvName,
[String]$CurrentDate= (Get-Date -Format "dd-MM-yyyy"),
[String]$FileFolderPath= $DeployBackupPath +"\TCConfiguration_" + $CurrentDate + "_" + $BuildNumber+"\Preferences",
[String]$FullFilePath= $DeployBackupPath +"\TCConfiguration_" + $CurrentDate + "_" + $BuildNumber+"\Preferences\Full_Preferences.txt",
[String]$DeltaFilePath= $DeployBackupPath +"\TCConfiguration_" + $CurrentDate + "_" + $BuildNumber+"\Preferences\Delta_Preferences.txt",
[String]$BatFilePath= $DeployBackupPath +"\TCConfiguration_" + $CurrentDate + "_" + $BuildNumber+"\Preferences\Import_Preferences.bat",
[String]$LogFilePath= $DeployBackupPath +"\TCConfiguration_" + $CurrentDate + "_" + $BuildNumber+"\Preferences\Log_Preferences.txt",
[String]$ErrorFilePath= $DeployBackupPath +"\TCConfiguration_" + $CurrentDate + "_" + $BuildNumber+"\Preferences\ErrorLog_Preferences.txt",
[String]$GitFileChangePath="SourceCode/Configuration/Preferences/",
[String]$GitMasterChangeFilePath=$RepoPath +"\Deploy\DeployScripts\Git_Compare\MasterGitDelta.txt",
[String]$EmptyString="Empty"
)
write-host "GitMasterChangeFilePath: " $GitMasterChangeFilePath
$Found=Get-Content $GitMasterChangeFilePath | Where-Object {$_ -match $GitFileChangePath}
write-host "Found: " $Found
if ($Found){
write-host "Preferences files are modified !!"
# Remote Server.
$pw = convertto-securestring -AsPlainText -Force -String $Password
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username,$pw
$Session = New-PSSession -ComputerName $HostName -Credential $cred

write-host "FullBatFilePath: " $FullBatFilePath
write-host "HomePath: " $HomePath
write-host "InfodbaPWD: " $InfodbaPWD
if($BuildType -eq "Full_Deployment"){
	$FilePath=$FullFilePath
} else {
	$FilePath=$DeltaFilePath
}
write-host "BatFilePath: " $BatFilePath
$Status=Invoke-Command -Session $Session -ScriptBlock {
Invoke-Expression "$args[0] $args[1], $args[2], $args[3], $args[4], $args[5], $args[6], $args[7], $args[8]" > $args[4] 2> $args[5]
$ErrorFound=Get-Content $args[5] | Where-Object {$_ -match "RROR:"}
write-host "ErrorFound: " $ErrorFound
if( $LASTEXITCODE -eq 0 -and [string]::IsNullOrEmpty($ErrorFound)) {
	$returncode="Success"
	write-host "Preferences Imported Successfully !!"
} else {
	$returncode="Failed"
	write-host "Preferences import Failed"
}
$returncode
}-ArgumentList $BatFilePath, $HomePath, $InfodbaPWD, $FileFolderPath, $LogFilePath, $ErrorFilePath,$FilePath, $EnvName, $EmptyString
Invoke-Command -Session $Session -ScriptBlock {
Get-Content $args[0]
Get-Content $args[1]
}-ArgumentList $LogFilePath, $ErrorFilePath
# Above ends Remote Session.
if($Status -eq "Failed"){
	exit 1
}
Remove-PSSession -Session $Session
}else{
write-host "No Modifications to Preferences !!"
}
