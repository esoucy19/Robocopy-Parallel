<#
This script is a wrapper around robocopy, using a set of default sensible
arguments, including the creation of a log file for each folder copied.

The script uses Powershell workflows to run robocopy in parallel over multiple
target directories, as well as using robocopy's own /MT (multithread) switch,
hopefully speeding up transfer speed.

The script also lets you specify multiple source directories, reducing the need
to run different scripts as long as the destination is the same.

DO note that the script doesn't check if multiple the different sources'
directories share the same name.
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [Alias("Path")]
    [String[]]$Paths,
    [Parameter(Mandatory=$true)]
    [String]$TargetPath,
    [bool]$Log = $true,
    [String]$LogDir = "C:\Robocopy Logs"
)

Begin{
    Workflow RobocopyParallel {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]
            [Alias("Path")]
            [String[]]$Paths,
            [Parameter(Mandatory=$true)]
            [String]$TargetPath,
            [bool]$Log,
            [String]$LogDir
        )
        $Dirs = Get-ChildItem -Path $Paths
        Foreach -Parallel ($Dir in $Dirs) {
            $Src = $Dir.FullName
            $Dst = $TargetPath
            $DirName = $Dir.Name
            $BaseCmd = "robocopy $Src $Dst"
            $BaseArgs = " /MIR /ZB /COPYALL /W:1 /R:2"
            $LogArgs = {if ($Log) { "/LOG+:" + $LogDir + "\" + $DirName + ".txt" + " /TEE"} else {""}}
            $Cmd = $BaseCmd + $BaseArgs + $LogArgs
            Invoke-Expression -Command $Cmd
        }
    }

    if (-NOT (Test-Path -Path $LogDirectory)) { New-Item -ItemType "directory" -Path $LogDirectory }
    $TimeStamp = Get-Date -Format o | Foreach-Object {$_ -replace ":", "."}
    $LogDir = $LogDirectory + "\" + $TimeStamp
    New-Item -ItemType "directory" -Path $LogDir
}

Process{
    RobocopyParallel -Path $Paths -TargetPath $TargetPath -Log $Log -LogDir $LogDir
}

End{}