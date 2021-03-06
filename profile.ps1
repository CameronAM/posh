﻿"output"
# write-output "output"
# write-host "Initing prompt..."
$PSVersionTable

$global:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$global:ComputerName = [System.Net.Dns]::GetHostName();

"1"

# extend path correctly...
# $env:path = "c:\cygwin\bin;$($env:path)"
$env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\cmd" 
# $env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\bin"

"2"

# set term so "less" does not complain
$env:TERM="msys"

"3"

# idiotic shared home drive rubish, must make the directory trusted
Set-Alias CasPol "$([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())CasPol.exe"
CasPol -polchgprompt off -machine -addgroup 1.2 -url file://P:\WindowsPowerShell\Modules\* FullTrust  | out-null

"4"

# hook up PsGet and PoshGit
# Import-Module PsGet # not needed, use chocolaty
# Import-Module Pscx # after installing with choco it's on the path and always available
# Import-Module Posh-Git

# custom aliases
new-alias -force which get-command
new-alias -force help get-help
new-alias -force gh get-help

# Set-Location c:\

function prompt() { 
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
	
    if((get-module Posh-Git)) {
	   # git status
	   Write-VcsStatus;
    }
	
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

function Invoke-WMSettingChange {
    #requires -version 2

    if (-not ("win32.nativemethods" -as [type])) {
        # import sendmessagetimeout from win32
        add-type -Namespace Win32 -Name NativeMethods -MemberDefinition '[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);'
    }

    $HWND_BROADCAST = [intptr]0xffff;
    $WM_SETTINGCHANGE = 0x1a;
    $result = [uintptr]::zero

    # notify all windows of environment block change
    [win32.nativemethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [uintptr]::Zero, "Environment", 2, 5000, [ref]$result);
}

# Import-Module Posh-Git

function ImportPoshGit(){
    Import-Module Posh-Git
    Invoke-SshAgent
}