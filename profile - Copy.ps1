$global:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$global:ComputerName = [System.Net.Dns]::GetHostName();

# extend path correctly...
# $env:path = "c:\cygwin\bin;$($env:path)"
$env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\bin"

# hook up PsGet and PoshGit
Import-Module PsGet
Import-Module Posh-Git

function prompt(){ 
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
	
	$line1LeftLength = [string]::Format( "┌─┤{0}├", $userAtHost).Length;
	$line1RightLength = [string]::Format( "┤{0}├┐", $location.Path).Length; 
	
	$line1Middle = "";
	
	$paddingLineLength = $windowWidth - ($line1LeftLength + $line1RightLength);
	
	for ($i=1; $i -le $paddingLineLength - 2; $i++)
	{
		# write-host "asfd";
		$line1Middle = $line1Middle + "─";
	}
	
	#$cursorAtLineOne = $host.UI.RawUI.CursorPosition.x;
	
	write-host -nonewline "┌─┤";
	# user @ host + any further information required

	write-host -nonewline -f green $userAtHost;
	
	# $cursorAtLineTwo = $host.UI.RawUI.CursorPosition.x;
	
	Write-VcsStatus
	write-host -nonewline ([string]::Format("├{0}┤", $line1Middle)); 
	write-host -nonewline -f magenta ([string]::Format("{0}", $location.Path));
	write-host "├┐";
	
	# write-host ([string]::Format( "{0}{1}", $line1Left, $line1Middle)); 
	write-host -nonewline "└ PS>"
	#write-host -nonewline $cursorAtLineOne $cursorAtLineTwo
	
	
	return " "
}