$global:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$global:ComputerName = [System.Net.Dns]::GetHostName();

# extend path correctly...
# $env:path = "c:\cygwin\bin;$($env:path)"
# $env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\bin"
$env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\cmd"

# set term so "less" does not complain
$env:TERM="msys"

# idiotic shared home drive rubish, must make the directory trusted
Set-Alias CasPol "$([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())CasPol.exe"
CasPol -polchgprompt off -machine -addgroup 1.2 -url file://P:\WindowsPowerShell\Modules\* FullTrust  | out-null

# hook up PsGet and PoshGit
Import-Module PsGet
Import-Module Pscx
Import-Module Posh-Git

# custom aliases
new-alias which get-command

Set-Location c:\

function prompt(){ 
	#colours
	$gbhlColour3 = 'darkgreen';
	
	$hlColour1 = 'blue';
	$hlColour2 = 'magenta';
	$hlColour3 = 'green';

	$location = get-location;
	$windowWidth = $host.UI.RawUI.WindowSize.Width;
	
	# username
	$indexOfSlash = $CurrentUser.Name.IndexOf('\');
	if($indexOfSlash -gt 0)
	{
		$userName = $CurrentUser.Name.Substring($indexOfSlash + 1);
	}
	else
	{
		$userName = $CurrentUser.Name;
	}
	$userAtHost = [string]::Format("{0}@{1}", $userName, $ComputerName);
	$path = $location.Path;
	
	write-host -nonewline -f $gbhlColour3 "┌─┤";
	write-host -nonewline -f $hlColour3 $userAtHost;
	
	# git status
	Write-VcsStatus;
	
	write-host -nonewline -f $gbhlColour3 "├";
	
	$cusorXPos = $host.UI.RawUI.CursorPosition.x;
	$pathStringLen = $location.Path.Length + 3; # extra 3 for the line art
	$paddingLineLength = $windowWidth - ($cusorXPos + $pathStringLen);

	# a bar to fill the gap
	$bar = "─" * ($paddingLineLength - 1);
	
	write-host -nonewline -f $gbhlColour3 $bar; 
	write-host -nonewline -f $gbhlColour3 "┤"; 
	write-host -nonewline -f $hlColour2 ($location.Path); 
	write-host -f $gbhlColour3 "├┐"; 
	
	write-host -nonewline -f $gbhlColour3 "└ ";
	write-host -nonewline -f $hlColour1 "PS";
	write-host -nonewline -f $gbhlColour3 ">";
	
	return " "
}
