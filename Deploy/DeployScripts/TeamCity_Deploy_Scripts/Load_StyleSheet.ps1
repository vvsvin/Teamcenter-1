Param(
[Parameter(Mandatory=$false)] [String]$Username,
[Parameter(Mandatory=$false)] [String]$RepoPath,
[Parameter(Mandatory=$false)] [String]$Password,
[Parameter(Mandatory=$false)] [String]$HostName,
[Parameter(Mandatory=$false)] [String]$HomePath,
[Parameter(Mandatory=$false)] [String]$InfodbaPWD,
[Parameter(Mandatory=$false)][String]$BuildNumber,
[Parameter(Mandatory=$false)][String]$BuildType,
[Parameter(Mandatory=$false)] [String]$DeployBackupPath,
[String]$CurrentDate= (Get-Date -Format "dd-MM-yyyy"),
[String]$StyleSheetFolder= $DeployBackupPath +"\TCConfiguration_" + $CurrentDate + "_" + $BuildNumber+"\Stylesheets",
[String]$FullFilePath= $DeployBackupPath +"\TCConfiguration_" + $CurrentDate + "_" + $BuildNumber+"\Stylesheets\Full_Stylesheets.txt",
[String]$DeltaFilePath= $DeployBackupPath +"\TCConfiguration_" + $CurrentDate + "_" + $BuildNumber+"\Stylesheets\Delta_Stylesheets.txt",
[String]$BatFilePath= $DeployBackupPath +"\TCConfiguration_" + $CurrentDate + "_" + $BuildNumber+"\Stylesheets\Import_Stylesheets.bat",
[String]$LogFilePath= $DeployBackupPath +"\TCConfiguration_" + $CurrentDate + "_" + $BuildNumber+"\Stylesheets\Log_Stylesheets.txt",
[String]$ErrorFilePath= $DeployBackupPath +"\TCConfiguration_" + $CurrentDate + "_" + $BuildNumber+"\Stylesheets\ErrorLog_Stylesheets.txt",
[String]$GitFileChangePath="SourceCode/Configuration/Stylesheets/",
[String]$GitMasterChangeFilePath=$RepoPath +"\Deploy\DeployScripts\Git_Compare\MasterGitDelta.txt",
[String]$EmptyString="Empty"
)
write-host "GitMasterChangeFilePath: " $GitMasterChangeFilePath
$Found=Get-Content $GitMasterChangeFilePath | Where-Object {$_ -match $GitFileChangePath}
write-host "Found: " $Found
if ($Found){
write-host "Stylesheets files are modified !!"
# Remote Server.
$pw = convertto-securestring -AsPlainText -Force -String $Password
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username,$pw
$Session = New-PSSession -ComputerName $HostName -Credential $cred

write-host "BatFilePath: " $BatFilePath
write-host "HomePath: " $HomePath
write-host "InfodbaPWD: " $InfodbaPWD
write-host "StyleSheetFolder: " $StyleSheetFolder

if($BuildType -eq "Full_Deployment"){
	$FilePath=$FullFilePath
} else {
	$FilePath=$DeltaFilePath
}
$Status=Invoke-Command -Session $Session -ScriptBlock {
Invoke-Expression "$args[0] $args[1], $args[2], $args[3], $args[4], $args[5], $args[6], $args[7]" > $args[4] 2> $args[5]
$ErrorFound=Get-Content $args[5] | Where-Object {$_ -match "RROR:"}
write-host "ErrorFound: " $ErrorFound
if( $LASTEXITCODE -eq 0 -and [string]::IsNullOrEmpty($ErrorFound)) {
	$returncode="Success"
	write-host "Stylesheets Imported Successfully !!"
} else {
	$returncode="Failed"
	write-host "Stylesheets import Failed"
}
$returncode
}-ArgumentList $BatFilePath, $HomePath, $InfodbaPWD, $FilePath, $LogFilePath, $ErrorFilePath, $StyleSheetFolder, $EmptyString
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
write-host "No Modifications to Stylesheets !!"
}
