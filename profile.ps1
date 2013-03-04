$global:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$global:ComputerName = [System.Net.Dns]::GetHostName();

# extend path correctly...
# $env:path = "c:\cygwin\bin;$($env:path)"
$env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\cmd" 
# $env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\bin"

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
new-alias -force which get-command
new-alias -force help get-help
new-alias -force gh get-help

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

	# write-host $windowWidth $cusorXPos 

	$modifiedPath = truncatePath $location.Path (($windowWidth - $cusorXPos) - 4);

	#write-host $location.Path;
	#write-host $modifiedPath;

	$pathStringLen = $modifiedPath.Length + 3; # extra 3 for the line art
	$paddingLineLength = $windowWidth - ($cusorXPos + $pathStringLen);

	# There might not be enough space to put the path in here, check and shorten in
	# bits until the path is not to long to fit, stick that in the path location in
	# the prompt.
	# Keep shortening, and stick the fully shorted location with last directory in the 
	# window title.

	# $path = truncatePath($location.Path, )

	# a bar to fill the gap
	$bar = "─" * ($paddingLineLength - 1);
	
	write-host -nonewline -f $gbhlColour3 $bar; 
	write-host -nonewline -f $gbhlColour3 "┤"; 
	write-host -nonewline -f $hlColour2 ($modifiedPath); 
	write-host -f $gbhlColour3 "├┐"; 
	
	write-host -nonewline -f $gbhlColour3 "└ ";
	write-host -nonewline -f $hlColour1 "PS";
	write-host -nonewline -f $gbhlColour3 ">";
	
	return " "
}

function truncatePath([string]$pathString, [int]$length) {
    $processedPath = "";
    
    if($pathString.Length -gt $length) {
        $chunks = $pathString.Trim(@("\")).Split("\");
        
        # assuming first value is the drive, skip it
        # don't ever process the last item in the list

        for($i = 1; $i -lt $chunks.Length - 1; $i++) { # -or (($chunks -join "\").Length -le $length
            $newValue = "";

			$selection = select-string "^.|\.." -input $chunks[$i] -allmatches;
            foreach($m in $selection.Matches) { 
				$newValue += $m.Value;
			}
            
            $chunks[$i] = $newValue;
            
            if(($chunks -join "\").Length -le $length) { break };
        }
        
        # write-host $length;
		# write-host ($chunks -join "\");

        return ($chunks -join "\");
    } else {
        $pathString;
    }
}

function Invoke-SshAgent([switch]$Quiet) {
    $oldPath = $env:path;
    $env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\bin"

    Start-SshAgent($Quiet);

    $env:path = $oldPath;
}