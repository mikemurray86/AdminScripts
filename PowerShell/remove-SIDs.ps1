<#
.SYNOPSIS
    Cleans up the file system of unresolved SIDs
.DESCRIPTION
    This will enumerate over every folder from the specified location to see if there are unresolved SIDs and will remove them. 
.PARAMETER Path
    Specifies a path to begin looking from.
.PARAMETER Recurse
    Specify if the script should decend into child directories. 
.EXAMPLE
    C:\PS> remove-SIDs.ps1 -path C:\temp
    This will check all folders directly under C:\temp for unresolved SIDs and remove them.
.EXAMPLE
    C:\PS> remove-SIDs.ps1 -path C:\temp -recurse
    This will check all folders directly under C:\temp and then any folders inside the folders it found. 
#>

#Requires -Version 3.0
#Requires -Modules ActiveDirectory, NTFSSecurity

[cmdletbinding(ConfirmImpact='High',
                SupportsShouldProcess=$true
                )]

param(
    [Parameter(Mandatory=$true)]
    [String] $path,
    [Parameter(Mandatory=$false)]
    [switch] $Recurse
)
begin{
    Write-Progress -Activity "Collecting Files"
    $Files = @()
    if ($recurse){ # don't bother to collect files that are inheriting permissions since we can't change them here anyway. 
        $Files += Get-ChildItem2 $Path -Recurse -Directory | Get-NTFSInheritance | Where-Object{ $_.AccessInheritanceEnabled -eq $False}
    }
    else{
        $Files += Get-ChildItem2 $Path -Directory | Get-NTFSInheritance | Where-Object{ $_.AccessInheritanceEnabled -eq $False}
    }
    $Files += Get-NTFSInheritance $Path # grabbing this so that the full name attribute can be used to get the rights on the root share
    Write-Progress -Activity "Collecting Files" -Status "Done" -Completed
}
process{
    foreach($file in $files){
        Write-Progress -Activity "Looking for Unresolved SIDs" -PercentComplete (($files.indexof($file) / ($files | Measure-Object).Count) * 100)
        $owner = (Get-NTFSOwner -Path $File.FullName).Owner
        if( -not $owner.AccountName){ # test if there is no account name which would indicate an unresolved SID
            if($PSCmdlet.ShouldProcess("Owner of $($File.FullName)")){
                Set-NTFSOwner -Path $file.FullName -Account "OPI Admins"
            }
        }
        $perms = Get-NTFSAccess -Path $file.FullName
        foreach( $perm in $perms){
            if(-not $perm.Account.AccountName){ # test if there is no account name which would indicate an unresolved SID
                if($PSCmdlet.ShouldProcess("Remove Permission on $($File.FullName)")){
                    $perm | Remove-NTFSAccess
                }
            }
        }
    }
    Write-Progress -Activity "Looking for Unresolved SIDs" -Completed
}